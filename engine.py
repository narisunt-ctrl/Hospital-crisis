"""Deterministic fictional ER simulation. No clinical meaning or external AI."""
import copy
import random

SCENARIOS = {'normal': (10, 3), 'overload': (15, 4), 'mass': (20, 5)}

class Invalid(ValueError):
    pass

class Game:
    def __init__(self, scenario='normal', seed=42):
        if scenario not in SCENARIOS or type(seed) is not int or not 0 <= seed <= 999999:
            raise Invalid('สถานการณ์หรือ seed ไม่ถูกต้อง')
        self.scenario, self.seed = scenario, seed
        self.tick, self.version, self.duration = 0, 0, 180
        self.patients, self.events, self.trace, self.receipts = [], [], [], {}
        self.staff = [None] * 3
        self.beds = [None] * 4
        self.transfers = 3
        self.busy = 0
        rng = random.Random(seed)
        count, initial = SCENARIOS[scenario]
        self.schedule = []
        for i in range(count):
            severity = rng.choices([1, 2, 3], [3, 4, 3])[0]
            self.schedule.append(dict(id=f'P{i+1:02}', arrival=0 if i < initial else rng.randint(5, 125), severity=severity, duration=rng.randint(14, 25), name=['มะลิ', 'อรุณ', 'นที', 'พลอย', 'เมฆ', 'ดาว', 'ต้น', 'ฝน'][i % 8]))
        self.schedule.sort(key=lambda p: (p['arrival'], p['id']))
        self._arrivals()

    def log(self, text):
        self.events.append({'tick': self.tick, 'text': text})

    def _arrivals(self):
        for p in self.schedule:
            if p['arrival'] == self.tick:
                self.patients.append({**p, 'status': 'waiting', 'wait': 0, 'remaining': p['duration'], 'bed': None, 'staff': None, 'priority': p['severity'], 'late': False})
                self.log(f"{p['id']} เข้าห้องฉุกเฉิน • ระดับ {p['severity']}")

    def snapshot(self):
        # Future arrivals and service duration are not exposed to strategy/UI.
        patients = [{k:v for k,v in p.items() if k not in ('duration', 'arrival')} for p in self.patients]
        return {'scenario': self.scenario, 'seed': self.seed, 'tick': self.tick, 'version': self.version, 'duration': self.duration, 'patients': patients, 'staff': self.staff[:], 'beds': self.beds[:], 'transfers': self.transfers, 'events': self.events[-40:], 'done': self.tick >= self.duration, 'scores': self.scores(), 'strategy': 'rules-v1'}

    def scores(self):
        total = len(self.patients) or 1
        resolved = sum(p['status'] in ('completed', 'transferred') for p in self.patients)
        late = sum(p['late'] for p in self.patients)
        safety = max(0, 100 * (1 - late / total))
        efficiency = 100 * resolved / total
        resource = min(100, self.busy / max(1, self.tick * 3) * 100)
        waiting = max(0, 100 - sum(min(100, p['wait'] * p['severity'] * 2) for p in self.patients) / total)
        return {**{k: round(v, 1) for k,v in zip(['safety','efficiency','resources','waiting'], [safety,efficiency,resource,waiting])}, 'fitness': round(.4*safety+.25*efficiency+.2*resource+.15*waiting,1), 'resolved': resolved, 'late': late}

    def command(self, cmd, actor='human'):
        cid = cmd.get('command_id')
        if not isinstance(cid, str) or not 1 <= len(cid) <= 100:
            raise Invalid('command_id ไม่ถูกต้อง')
        if cid in self.receipts:
            if self.receipts[cid] != cmd:
                raise Invalid('command_id นี้ถูกใช้กับคำสั่งอื่นแล้ว')
            return self.snapshot()
        if cmd.get('expected_state_version') != self.version:
            raise Invalid('สถานะเปลี่ยนแล้ว กรุณาลองอีกครั้ง')
        if self.tick >= self.duration:
            raise Invalid('เวรนี้สิ้นสุดแล้ว')
        payload = cmd.get('payload')
        if not isinstance(payload, dict) or payload.get('type') != cmd.get('action'):
            raise Invalid('รูปแบบคำสั่งไม่ถูกต้อง')
        p = next((p for p in self.patients if p['id'] == payload.get('patient_id')), None)
        if not p or p['status'] != 'waiting':
            raise Invalid('เลือกผู้ป่วยที่ยังรออยู่')
        action = cmd['action']
        if action in ('allocate_bed', 'assign_staff'):
            field, resources = ('bed', self.beds) if action == 'allocate_bed' else ('staff', self.staff)
            index = payload.get(field + '_id')
            if type(index) is not int or not 0 <= index < len(resources) or resources[index] is not None or p[field] is not None:
                raise Invalid('ทรัพยากรนี้ไม่ว่าง หรือจัดสรรให้ผู้ป่วยแล้ว')
            resources[index], p[field] = p['id'], index
            if p['bed'] is not None and p['staff'] is not None:
                p['status'] = 'treating'
        elif action == 'prioritize_queue':
            priority = payload.get('new_priority')
            if type(priority) is not int or not p['severity'] <= priority <= 3:
                raise Invalid('ห้ามลดความสำคัญต่ำกว่าระดับผู้ป่วย')
            p['priority'] = priority
        elif action == 'request_transfer':
            if p['severity'] == 3 or self.transfers <= 0 or payload.get('destination_id') != 'partner':
                raise Invalid('ส่งต่อได้เฉพาะระดับ 1–2 และต้องมีโควตา')
            self.transfers -= 1
            p['status'] = 'transferred'
            self._release(p)
        else:
            raise Invalid('ไม่รู้จักคำสั่ง')
        self.version += 1
        self.trace.append({'tick': self.tick, 'actor': actor, 'command': copy.deepcopy(cmd)})
        self.receipts[cid] = copy.deepcopy(cmd)
        self.log(f"{'AI' if actor == 'ai' else 'คุณ'} • {action} → {p['id']}")
        return self.snapshot()

    def _release(self, p):
        for field, resources in [('bed', self.beds), ('staff', self.staff)]:
            if p[field] is not None:
                resources[p[field]] = None
                p[field] = None

    def advance(self, seconds=1):
        if type(seconds) is not int or not 1 <= seconds <= 10:
            raise Invalid('ช่วงเวลาไม่ถูกต้อง')
        for _ in range(seconds):
            if self.tick >= self.duration:
                break
            self.tick += 1
            for p in self.patients:
                if p['status'] == 'waiting':
                    p['wait'] += 1
                    if p['wait'] > {1:65, 2:40, 3:20}[p['severity']] and not p['late']:
                        p['late'] = True
                        self.log(f"⚠ {p['id']} รอเกินเป้าหมายเกม")
                elif p['status'] == 'treating':
                    self.busy += 1
                    p['remaining'] -= 1
                    if p['remaining'] == 0:
                        p['status'] = 'completed'
                        self._release(p)
                        self.log(f"✓ {p['id']} ดูแลเสร็จแล้ว")
            self._arrivals()
            self.version += 1
        return self.snapshot()

    def suggestions(self):
        waiting = sorted((p for p in self.patients if p['status'] == 'waiting'), key=lambda p: (-p['priority'], -p['wait'], p['id']))
        if not waiting:
            return None
        for p in waiting:
            for action, field, resources in [('allocate_bed', 'bed', self.beds), ('assign_staff', 'staff', self.staff)]:
                if p[field] is None and None in resources:
                    return {'action': action, 'payload': {'type': action, 'patient_id': p['id'], field+'_id': resources.index(None)}}
        return None
