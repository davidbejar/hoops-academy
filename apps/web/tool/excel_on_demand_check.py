"""Excel on demand, in a real Chrome (WP97, decision 69).

Run after `tool/offline_cold_start.sh` (it leaves the mock bundle in build/offline-check):

    python3 -I tool/excel_on_demand_check.py

Signs in to the mock academy, opens the matches list and picks "Archivo Excel" in the export menu:
  1. the Excel library's deferred part was not fetched while the app was in use;
  2. offline (first use) the person gets the "could not be loaded" message and nothing is downloaded;
  3. online the part is fetched at that moment and the file is "downloaded".
Reuses the WebDriver helpers of offline_cold_start.py; needs chromedriver like that script.
"""
import glob, os, sys, time, socket, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import offline_cold_start as o

build = os.path.abspath('build/offline-check')
part = next(os.path.basename(f) for f in glob.glob(build + '/main.dart.js_*.part.js') if 'xl/workbook.xml' in open(f, errors='ignore').read())
print('excel part:', part)
assert 'xl/workbook.xml' not in open(build + '/main.dart.js', errors='ignore').read()
with socket.socket() as s:
    s.bind(('127.0.0.1', 0)); port = s.getsockname()[1]
drv = subprocess.Popen([os.environ.get('CHROMEDRIVER', 'chromedriver'), f'--port={port}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
server = o.serve(build, 5175)
wd = None
RES = "return performance.getEntriesByType('resource').map(r => r.name).filter(n => n.includes('.part.js'));"
try:
    o.wait_for('chromedriver', lambda: o._up(port), 15, 0.3)
    wd = o.WebDriver(port, False)
    wd.cmd('POST', '/url', {'url': 'http://localhost:5175/'})
    o.wait_for('landing', lambda: o.has(wd, o.SIGN_IN), 120)
    o.wait_for('sw', lambda: o._sw(wd), 60)
    o.wait_for('sign-in tap', lambda: o.click(wd, o.SIGN_IN), 30, 0.5)
    time.sleep(1)
    o.wait_for('login', lambda: o.has(wd, ('Cambiar de academia',)) or o.click(wd, o.SIGN_IN), 30, 0.5)
    o.wait_for('picker', lambda: o.has(wd, ('Cambiar de academia',)), 30, 0.5)
    o.wait_for('pick', lambda: o.click(wd, ('Academia Demo',)), 30, 0.5)
    o.wait_for('signed in', lambda: not o.has(wd, ('Cambiar de academia',)) and o.texts(wd), 30, 0.5)
    wd.js("location.hash = '#/matches';")
    o.wait_for('matches', lambda: o.click(wd, ('Exportar',)) is not None or o.has(wd, ('Exportar',)), 60, 1)
    time.sleep(2)
    loaded = wd.js(RES)
    print('deferred parts loaded before export:', len(loaded), '| excel part among them:', any(part in n for n in loaded))
    # reopen: the first click above may have opened the sheet already
    if not o.has(wd, ('Archivo Excel',)):
        o.wait_for('open menu', lambda: o.click(wd, ('Exportar',)) and o.has(wd, ('Archivo Excel',)), 20, 1)
    # offline first use
    wd.cmd('POST', '/chromium/network_conditions', {'network_conditions': {'offline': True, 'latency': 0, 'download_throughput': -1, 'upload_throughput': -1}})
    o.wait_for('excel click', lambda: o.click(wd, ('Archivo Excel',)), 20, 0.5)
    o.wait_for('offline message', lambda: o.has(wd, ('No se pudo cargar Excel',)), 30, 1)
    print('offline first use: message shown ->', [t for t in o.texts(wd) if 'Excel' in t][:2])
    # online again
    wd.cmd('POST', '/chromium/network_conditions', {'network_conditions': {'offline': False, 'latency': 0, 'download_throughput': -1, 'upload_throughput': -1}})
    time.sleep(5)
    o.wait_for('open menu 2', lambda: o.click(wd, ('Exportar',)) and o.has(wd, ('Archivo Excel',)), 20, 1)
    o.wait_for('excel click 2', lambda: o.click(wd, ('Archivo Excel',)), 20, 0.5)
    o.wait_for('downloaded', lambda: o.has(wd, ('Descargado hoops-',)), 40, 1)
    print('online: ', [t for t in o.texts(wd) if 'Descargado' in t][:1])
    loaded = wd.js(RES)
    print('excel part fetched after the click:', any(part in n for n in loaded))
finally:
    if wd: wd.quit()
    drv.terminate(); server.shutdown()
