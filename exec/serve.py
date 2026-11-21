# local server that will dynamically serve favicon_local.ico, rather than favicon.ico

import http.server
import os

PORT = 8000

class LocalDevHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        clean_path = path.split('?')[0]

        # Intercept any request ending in favicon.ico
        if clean_path == '/favicon.ico' or clean_path.endswith('/favicon.ico'):
            # self.log_message("[REWRITE] %s -> serving favicon_local.ico", path)
            path = '/favicon_local.ico'

        resolved_path = super().translate_path(path)
        print(f"[SERVE] Path '{path}' mapped to disk: {resolved_path} (Exists: {os.path.exists(resolved_path)})")
        return resolved_path

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()


# ThreadingHTTPServer handles each connection in its own thread, so an idle
# browser connection can't block the next request (the cause of the delays).
class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True        # Ctrl-C quits without waiting on open connections
    allow_reuse_address = True   # restart right away without "address in use"


with Server(("", PORT), LocalDevHandler) as httpd:
    print(f"Serving locally at http://localhost:{PORT}")
    httpd.serve_forever()
