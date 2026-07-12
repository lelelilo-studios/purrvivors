#!/usr/bin/env python3
"""Serve a web export for headless-browser screenshots.

Firefox --headless --screenshot fires as soon as the page 'load' event hits,
which is long before a wasm game boots. Trick: /shot.html embeds the game in
an iframe next to a hidden <img src="/slow.png"> that this server answers
only after DELAY seconds - holding the load event open while the game boots.

Usage: python3 tools/shot_server.py <dir> <port> <delay_seconds>
Then:  firefox --headless --screenshot out.png http://127.0.0.1:<port>/shot.html
"""
import http.server
import os
import sys
import time

DIR, PORT, DELAY = sys.argv[1], int(sys.argv[2]), float(sys.argv[3])

# 1x1 transparent PNG
PIXEL = bytes.fromhex(
    "89504e470d0a1a0a0000000d494844520000000100000001080600000"
    "01f15c4890000000d49444154789c626001000000ffff03000006000557bfabd4"
    "0000000049454e44ae426082")

SHOT_PAGE = b"""<!doctype html><html><body style="margin:0;background:#2b1c12">
<iframe src="/index.html" style="width:100vw;height:100vh;border:0"></iframe>
<img src="/slow.png" style="display:none">
</body></html>"""


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=DIR, **kw)

    def do_GET(self):
        if self.path.startswith("/slow.png"):
            time.sleep(DELAY)
            self.send_response(200)
            self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(PIXEL)))
            self.end_headers()
            self.wfile.write(PIXEL)
        elif self.path.startswith("/shot.html"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(SHOT_PAGE)))
            self.end_headers()
            self.wfile.write(SHOT_PAGE)
        elif self.path in ("/", "/index.html"):
            # Inject the slow image straight into the game page so the
            # browser's load event (and thus --screenshot) waits DELAY sec.
            with open(os.path.join(DIR, "index.html"), "rb") as f:
                html = f.read()
            html = html.replace(
                b"</body>",
                b'<img src="/slow.png" style="display:none"></body>')
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)
        else:
            super().do_GET()

    def log_message(self, *a):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
