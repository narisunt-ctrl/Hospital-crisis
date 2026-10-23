import argparse
import json
import secrets
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from engine import Game, Invalid

GAMES = {}
LOCK = threading.Lock()
WEB = Path(__file__).parent / 'web'

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB), **kwargs)

    def respond(self, data, status=200):
        raw = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(raw)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(raw)

    def do_POST(self):
        if self.headers.get('Sec-Fetch-Site') == 'cross-site':
            return self.respond({'error': 'Cross-site request refused'}, 403)
        try:
            length = int(self.headers.get('Content-Length', 0))
            if not 0 < length <= 16384:
                raise Invalid('ขนาดคำขอไม่ถูกต้อง')
            data = json.loads(self.rfile.read(length))
            if not isinstance(data, dict):
                raise Invalid('คำขอต้องเป็น object')
            with LOCK:
                if self.path == '/api/games':
                    if len(GAMES) >= 200:
                        return self.respond({'error': 'เต็มจำนวนเกม กรุณารีสตาร์ทเซิร์ฟเวอร์'}, 503)
                    game = Game(data.get('scenario', 'normal'), data.get('seed', 42))
                    gid = secrets.token_urlsafe(18)
                    GAMES[gid] = game
                    return self.respond({'id': gid, 'state': game.snapshot()})
                parts = self.path.strip('/').split('/')
                if len(parts) != 4 or parts[:2] != ['api', 'games'] or parts[2] not in GAMES:
                    return self.respond({'error': 'ไม่พบเกม'}, 404)
                game = GAMES[parts[2]]
                route = parts[3]
                if route == 'command':
                    state = game.command(data)
                elif route == 'tick':
                    state = game.advance(data.get('seconds', 1))
                elif route == 'suggestion':
                    return self.respond({'suggestion': game.suggestions(), 'state': game.snapshot()})
                elif route == 'accept':
                    # The client approves a specific pending suggestion. Recompute and
                    # compare before commit so stale proposals never silently change.
                    proposal = game.suggestions()
                    if not proposal or data.get('proposal') != proposal:
                        raise Invalid('คำแนะนำเปลี่ยนแล้ว กรุณาขอคำแนะนำใหม่')
                    state = game.command({**proposal, 'command_id': data.get('command_id'), 'expected_state_version': data.get('expected_state_version')}, actor='ai')
                elif route == 'export':
                    return self.respond({'kind':'RECORDED RUN — not verified replay', 'scenario_version':'toy-v1', 'metric_version':'toy-v1', 'scenario':game.scenario, 'seed':game.seed, 'trace':game.trace, 'events':game.events, 'state':game.snapshot()})
                else:
                    return self.respond({'error':'ไม่พบคำสั่ง'},404)
                self.respond({'state': state})
        except (Invalid, ValueError, TypeError, KeyError) as exc:
            self.respond({'error': str(exc)}, 400)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8000)
    parser.add_argument('--host', default='0.0.0.0')
    args = parser.parse_args()
    ThreadingHTTPServer((args.host, args.port), Handler).serve_forever()
