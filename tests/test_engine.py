import copy
import unittest
from engine import Game, Invalid

class EngineTests(unittest.TestCase):
    def cmd(self,g,action='allocate_bed',pid=None,**payload):
        return {'command_id':f'cmd-{g.version}', 'expected_state_version':g.version,'action':action,'payload':{'type':action,'patient_id':pid or g.patients[0]['id'],**payload}}

    def test_invalid_atomic(self):
        g=Game();before=copy.deepcopy(g.__dict__)
        for index in [-1,True,20,'0']:
            with self.assertRaises(Invalid):g.command(self.cmd(g,bed_id=index))
            self.assertEqual(before,g.__dict__)

    def test_idempotency_and_stale(self):
        g=Game();cmd=self.cmd(g,bed_id=0);g.command(cmd);before=copy.deepcopy(g.__dict__)
        g.command(cmd);self.assertEqual(before,g.__dict__)
        bad={**cmd,'command_id':'different'}
        with self.assertRaises(Invalid):g.command(bad)
        self.assertEqual(before,g.__dict__)

    def test_resources_not_double_booked(self):
        g=Game();g.command(self.cmd(g,bed_id=0));before=copy.deepcopy(g.__dict__)
        with self.assertRaises(Invalid):g.command(self.cmd(g,pid=g.patients[1]['id'],bed_id=0))
        self.assertEqual(before,g.__dict__)

    def test_treatment_and_release(self):
        g=Game();p=g.patients[0];g.command(self.cmd(g,bed_id=0));g.command(self.cmd(g,'assign_staff',staff_id=0))
        for _ in range(3):g.advance(10)
        self.assertEqual(p['status'],'completed');self.assertIsNone(g.beds[0]);self.assertIsNone(g.staff[0])

    def test_transfer_safety(self):
        g=Game('mass',12);p=next(p for p in g.patients if p['severity']==3);before=copy.deepcopy(g.__dict__)
        with self.assertRaises(Invalid):g.command(self.cmd(g,'request_transfer',pid=p['id'],destination_id='partner'))
        self.assertEqual(before,g.__dict__)

    def test_all_scenarios_deterministic_full_waves(self):
        for scenario in ('normal','overload','mass'):
            runs=[]
            for _ in range(2):
                g=Game(scenario,42)
                while g.tick<180:
                    while (proposal:=g.suggestions()):
                        g.command({**proposal,'command_id':f'ai-{g.version}','expected_state_version':g.version},actor='ai')
                    g.advance()
                self.assertTrue(g.snapshot()['done']);self.assertGreater(g.scores()['resolved'],0)
                self.assertTrue(all(0<=g.scores()[k]<=100 for k in ['fitness','safety','efficiency','resources','waiting']))
                runs.append(g.__dict__)
            self.assertEqual(*runs)

    def test_observation_hides_future(self):
        g=Game();s=g.snapshot();self.assertNotIn('schedule',s)
        self.assertNotIn('duration',s['patients'][0]);self.assertNotIn('arrival',s['patients'][0])

    def test_no_commands_after_wave(self):
        g=Game()
        for _ in range(18):g.advance(10)
        before=copy.deepcopy(g.__dict__)
        with self.assertRaises(Invalid):g.command(self.cmd(g,bed_id=0))
        self.assertEqual(before,g.__dict__)

if __name__=='__main__':unittest.main()
