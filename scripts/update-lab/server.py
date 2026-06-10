#!/usr/bin/env python3
"""Update-lab HTTP server (loopback only) for `make update-test-*`.

Serves the scenario appcast and archives from --root, with two twists:

  /truncate/<file>   advertises the file's full Content-Length but resets the
                     connection after ~35% of the bytes — simulates a download
                     dying mid-transfer (NSURLSession surfaces a network error,
                     which Sparkle maps to SUDownloadError).
  --throttle-bps N   caps .zip transfer speed so the in-app progress UI is
                     visible even for small local archives.
"""
import argparse
import os
import socket
import struct
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CHUNK = 64 * 1024
TRUNCATE_PREFIX = "/truncate/"
TRUNCATE_FRACTION = 0.35


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):  # noqa: N802 (http.server API)
        path = self.path.split("?", 1)[0]
        truncate = path.startswith(TRUNCATE_PREFIX)
        rel = path[len(TRUNCATE_PREFIX):] if truncate else path.lstrip("/")
        full = os.path.realpath(os.path.join(self.server.root, rel))
        if not full.startswith(self.server.root + os.sep) or not os.path.isfile(full):
            self.send_error(404)
            return

        size = os.path.getsize(full)
        is_zip = full.endswith(".zip")
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream" if is_zip else "text/xml")
        self.send_header("Content-Length", str(size))
        self.end_headers()

        limit = int(size * TRUNCATE_FRACTION) if truncate else size
        throttle = self.server.throttle_bps if is_zip else 0
        sent = 0
        with open(full, "rb") as f:
            while sent < limit:
                chunk = f.read(min(CHUNK, limit - sent))
                if not chunk:
                    break
                self.wfile.write(chunk)
                sent += len(chunk)
                if throttle:
                    time.sleep(len(chunk) / throttle)

        if truncate:
            # Reset (RST) instead of a clean FIN so the client unambiguously
            # sees a failed transfer, then hand the base class a dummy stream
            # so its post-request flush doesn't trip on the dead socket.
            self.wfile.flush()
            self.connection.setsockopt(
                socket.SOL_SOCKET, socket.SO_LINGER, struct.pack("ii", 1, 0)
            )
            self.connection.close()
            self.wfile = open(os.devnull, "wb")
            self.close_connection = True
            self.log_message("truncated %s after %d/%d bytes", rel, sent, size)

    def log_message(self, fmt, *args):
        print(f"[update-lab] {self.address_string()} {fmt % args}", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--throttle-bps", type=int, default=0)
    args = parser.parse_args()

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.root = os.path.realpath(args.root)
    server.throttle_bps = args.throttle_bps
    print(f"[update-lab] serving {server.root} on http://localhost:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
