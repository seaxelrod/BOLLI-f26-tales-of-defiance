# local server that will dynamically serve favicon_local.ico, rather than favicon.ico

import http.server
import socketserver
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


with socketserver.TCPServer(("", PORT), LocalDevHandler) as httpd:
    print(f"Serving locally at http://localhost:{PORT}")
    httpd.serve_forever()
