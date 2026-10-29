"""Serves a built site the way a host does: compressed, and several requests at once.

`python3 -m http.server` is what the checks used, and it sends no `Content-Encoding` at all — so every
measurement of the site was taken against a server that ships 238 kB where GitHub Pages ships 76 kB.
A budget measured against a configuration nobody deploys is a budget for the wrong page.

Usage:
    python3 tool/serve.py <directory> <port>
"""

import gzip
import http.server
import os
import socketserver
import sys

COMPRESSIBLE = (
    '.html', '.css', '.js', '.json', '.svg', '.txt', '.xml', '.webmanifest', '.ttf',
)


class Handler(http.server.SimpleHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def do_GET(self):
        """Sends the file compressed when the client accepts it and the type is worth compressing."""
        path = self.translate_path(self.path)

        if os.path.isdir(path):
            path = os.path.join(path, 'index.html')

        if not os.path.isfile(path) or not self._accepts_gzip(path):
            super().do_GET()
            return

        body = gzip.compress(open(path, 'rb').read(), 6)
        self.send_response(200)
        self.send_header('Content-Type', self.guess_type(path))
        self.send_header('Content-Encoding', 'gzip')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _accepts_gzip(self, path):
        if not path.endswith(COMPRESSIBLE):
            return False
        if 'gzip' not in (self.headers.get('Accept-Encoding') or ''):
            return False
        # A file already compressed better than we could is served as it is.
        return os.path.getsize(path) > 1024


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == '__main__':
    directory, port = sys.argv[1], int(sys.argv[2])
    os.chdir(directory)
    with Server(('127.0.0.1', port), Handler) as server:
        server.serve_forever()
