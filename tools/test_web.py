"""Exercise the exported Godot game through real browser input (Playwright)."""
import argparse
import asyncio
import json
import shutil
from pathlib import Path
from playwright.async_api import async_playwright

async def main(base_url, output):
    output.mkdir(parents=True, exist_ok=True)
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            executable_path=shutil.which('chromium'),
            args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'])
        for width, height, touch in [(1440, 900, False), (844, 390, True)]:
            page = await browser.new_page(viewport={'width': width, 'height': height},
                                          has_touch=touch, is_mobile=touch)
            errors = []
            page.on('pageerror', lambda e: errors.append(str(e)))
            page.on('console', lambda msg: errors.append(msg.text) if msg.type == 'error' else None)
            await page.goto(base_url)
            frame = page.frame_locator('#game')
            canvas = frame.locator('#canvas')
            await canvas.wait_for()
            await frame.locator('#status').wait_for(state='detached', timeout=120000)
            await canvas.wait_for(state='visible')
            async def snapshot():
                return json.loads(await canvas.get_attribute('data-game-state') or '{}')
            async def wait_state(predicate, timeout=15):
                for _ in range(timeout * 10):
                    state = await snapshot()
                    if predicate(state):
                        return state
                    await asyncio.sleep(.1)
                raise AssertionError(f'State did not reach target: {await snapshot()}')
            async def click(x, y):
                scale = min(width / 1440, height / 900)
                px = (width - 1440 * scale) / 2 + x * scale
                py = (height - 900 * scale) / 2 + y * scale
                if touch:
                    await page.touchscreen.tap(px, py)
                else:
                    await page.mouse.click(px, py)
            await wait_state(lambda s: s.get('mode') == 'menu')
            await page.screenshot(path=str(output / f'menu-{width}.png'))
            await click(300, 684)
            await wait_state(lambda s: s.get('mode') == 'playing')
            await click(340, 327)
            await wait_state(lambda s: s.get('cargo') == 'medicine')
            await click(1010, 567)
            first = await wait_state(lambda s: s.get('delivered') == 1)
            assert first['score'] > 100 and first['cargo'] == '' and first['order'] == 'sample'
            await click(1130, 327)
            await wait_state(lambda s: s.get('cargo') == 'sample')
            await click(1010, 567)
            await wait_state(lambda s: s.get('delivered') == 2)
            await page.screenshot(path=str(output / f'playing-{width}.png'))
            # Pause and resume through visible controls, on both input types.
            await click(1375, 60)
            before = await wait_state(lambda s: s.get('mode') == 'paused')
            await asyncio.sleep(1.2)
            after = await snapshot()
            assert before['remaining'] == after['remaining'], 'Pause must stop the clock'
            await click(700, 453)
            await wait_state(lambda s: s.get('mode') == 'playing')
            if not touch:
                before = await snapshot()
                await page.keyboard.down('ArrowLeft')
                await asyncio.sleep(.4)
                await page.keyboard.up('ArrowLeft')
                await asyncio.sleep(.35)
                after = await snapshot()
                assert after['x'] < before['x'] - 25, 'Keyboard must move the character'
            assert not errors, errors
            print(f'{width}x{height}: Godot loaded; mouse/touch navigation, medicine/lab deliveries, score, pause/resume passed')
            await page.close()
        # Phone portrait offers a dismissible orientation hint rather than cropping the map.
        page = await browser.new_page(viewport={'width': 390, 'height': 844}, has_touch=True, is_mobile=True)
        await page.goto(base_url)
        assert await page.locator('#rotate').is_visible()
        await page.click('#portrait')
        assert not await page.locator('#rotate').is_visible()
        assert await page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        await page.close()
        await browser.close()
        print('Portrait orientation hint and page layout passed')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', default='http://127.0.0.1:8000')
    parser.add_argument('--screenshots', type=Path, default=Path('/tmp/hospital-godot-check'))
    args = parser.parse_args()
    asyncio.run(main(args.url, args.screenshots))
