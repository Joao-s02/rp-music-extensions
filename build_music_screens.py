"""Build independent local API 3 candidates; never updates the public catalog."""
from pathlib import Path
import json, hashlib

root = Path(__file__).resolve().parent
folder = root / 'previews/js-music-0.1.0'
folder.mkdir(parents=True, exist_ok=True)
common = (root / 'sources/music_screens_common.js').read_text(encoding='utf-8')
definitions = [
    ('explorador-musical', 'Explorador musical', 'explorador_musical.js',
     'Explora artistas, álbumes, listas y canciones públicas de YouTube Music. Sin cuenta; audio experimental.',
     ['music.youtube.com', 'www.youtube.com', '*.googlevideo.com'], 'Explorar JS', 'music', '#9C8DFF', False),
    ('radio-internet', 'Radio por internet', 'radio_internet.js',
     'Busca emisoras HTTPS MP3/AAC de Radio Browser, filtra por país/género y guarda favoritas privadas.',
     ['de1.api.radio-browser.info', 'nl1.api.radio-browser.info', 'at1.api.radio-browser.info'], 'Radio JS', 'headphones', '#00BFB3', True),
]
hashes = []
for slug, name, source, description, domains, label, icon, color, stream in definitions:
    code = common + '\n' + (root / 'sources' / source).read_text(encoding='utf-8')
    assert len(code.encode()) <= 65536
    package = dict(apiVersion=3, engine='javascript', id='rp.'+slug+'-js', name=name,
                   version='0.1.0', minAppVersion='0.3.9', description=description,
                   permissions=['navigation.add','storage.private','network.http','playback.control'] + (['network.stream'] if stream else []),
                   capabilities=['screen'], sourceConfig=dict(name=name, domains=domains, platforms=['android','windows'],
                       navigation=dict(label=label,icon=icon,color=color)), source=code)
    path = folder / (slug+'.rpmx')
    path.write_text(json.dumps(package, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    assert path.stat().st_size <= 128 * 1024
    hashes.append(hashlib.sha256(path.read_bytes()).hexdigest()+'  '+path.name)
(folder/'SHA256SUMS.txt').write_text('\n'.join(hashes)+'\n', encoding='utf-8')
print('\n'.join(hashes))
