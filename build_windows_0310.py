"""Local Windows candidates only. Preserve published packages and catalog."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent
folder = root / 'previews/0.3.10'
folder.mkdir(exist_ok=True)
definitions = [
    ('previews/0.3.5/youtube-music-android.rpmx',
     '7caf7c3a08f5f7d1f3daf48d5ee384b71be8d087840859d8563686017ff88d2d',
     'rp.youtube-music-windows', 'YouTube Windows', '0.4.1', 'youtube-music-windows.rpmx'),
    ('previews/explorer-0.1.0/youtube-explorer.rpmx',
     '75f155625bc759ac48bd7aae97d6570937eac06139886b204a7a3b38cf137348',
     'rp.youtube-explorer-windows', 'YouTube Explorador Windows', '0.1.0', 'youtube-explorer-windows.rpmx'),
]
for source, expected, identity, name, version, filename in definitions:
    raw = (root / source).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == expected
    package = json.loads(raw)
    package.update(id=identity, name=name, version=version, minAppVersion='0.3.10',
                   description='Windows: fuente Dart/API2 para RP Music0.3.10 con motor de audio actualizado. Candidato local en verificación.')
    package['sourceConfig']['platforms'] = ['windows']
    package['sourceConfig']['description'] = 'Audio y navegación públicos sin cuenta. Windows con motor alternativo en verificación local.'
    (folder / filename).write_text(json.dumps(package, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
baseline = root / 'previews/js-music-0.1.0/radio-internet.rpmx'
assert hashlib.sha256(baseline.read_bytes()).hexdigest() == '788e84a0da3fa1419afbbdadc93f77b853af7dec2a18756e028c1b6f8b0069a8'
radio = json.loads(baseline.read_bytes())
radio['version'] = '0.1.1'
radio['source'] = (root / 'sources/music_screens_common.js').read_text(encoding='utf-8')+'\n'+(root / 'sources/radio_internet_011.js').read_text(encoding='utf-8')
(folder / 'radio-internet.rpmx').write_text(json.dumps(radio, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
paths = sorted(folder.glob('*.rpmx'))
assert all(path.stat().st_size <= 128 * 1024 for path in paths)
(folder / 'SHA256SUMS.txt').write_text('\n'.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name for p in paths)+'\n', encoding='utf-8')
print('Three local candidates generated; published packages/catalog untouched.')
