"""Build local candidates; never publishes or modifies historical packages."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
shared = (root/'sources/metadata_lyrics.dart').read_text(encoding='utf-8')
yt = (root/'sources/youtube_music.dart').read_text(encoding='utf-8')
start = yt.index("  if(operation=='lyrics' && stage=='start')")
end = yt.index("  if(operation=='search' && stage=='start')", start)
dispatch = '''  if(operation=='lyrics' || operation=='metadata') {
    if(stage=='start') return jsonEncode(startLyrics(input));
    if(stage=='lyrics-search' || stage=='lyrics-fallback') return jsonEncode(lyricsResult(input));
    if(stage=='metadata-recordings' || stage=='metadata-release') return jsonEncode(metadataResult(input));
  }
'''
yt = yt[:start] + dispatch + yt[end:]
yt = yt.replace('String run(String request) {', shared + '\nString run(String request) {')
(root/'sources/youtube_enriched.dart').write_text(yt, encoding='utf-8')
lyrics = "import 'dart:convert';\n" + shared + '''
String run(String request) {
  final Map<String,dynamic> input=jsonDecode(request) as Map<String,dynamic>;
  if(input['event']!='lyrics') return jsonEncode(<String,dynamic>{'error':'Operación no admitida.'});
  if(input['stage']=='start') return jsonEncode(startLyrics(input));
  return jsonEncode(lyricsResult(input));
}
'''
(root/'sources/letras_locales.dart').write_text(lyrics, encoding='utf-8')
out = root/'previews/0.3.5'
out.mkdir(parents=True, exist_ok=True)
base=json.loads((root/'previews/0.3.4/youtube-music-android.rpmx').read_text(encoding='utf-8'))
base.update(version='0.4.0', minAppVersion='0.3.5', source=yt,
            description='YouTube Android con metadatos y letras automáticos para nuevas descargas. Experimental; requiere RP Music 0.3.5.')
base['sourceConfig']['domains'] += ['musicbrainz.org','coverartarchive.org','archive.org','*.archive.org']
base['sourceConfig']['description']='Audio sin cuenta. Busca letras y completa automáticamente etiquetas y portada al descargar; los datos ausentes se indican.'
local={'apiVersion':2,'id':'rp.letras-locales','name':'Letras locales','version':'0.1.0','minAppVersion':'0.3.5',
       'description':'Busca letras automáticamente al reproducir canciones locales sin letra. Solo guarda en la app; no modifica tu música.',
       'permissions':['library.read','network.http','lyrics.cache'],'capabilities':['lyrics'],
       'sourceConfig':{'name':'Letras locales','domains':['lrclib.net'],'platforms':['android','windows']},'source':lyrics}
for filename, package in [('youtube-music-android.rpmx',base),('letras-locales.rpmx',local)]:
    (out/filename).write_text(json.dumps(package,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
variants=json.loads((root/'catalog-variants.json').read_text(encoding='utf-8'))
path='previews/0.3.5/youtube-music-android.rpmx'
if path not in variants['rp.youtube-music']: variants['rp.youtube-music'].append(path)
(root/'catalog-variants.json').write_text(json.dumps(variants,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Keep Spotify's package in history, but remove it from the new catalog.
rows=[]
for raw in json.loads((root/'catalog.json').read_text(encoding='utf-8'))['extensions']:
    if 'spotify' in raw['id']: continue
    if raw['id']=='rp.youtube-music':
        raw['versions']=[v for v in raw.get('versions',[]) if v.get('path')!=path]
        raw['versions'].append({**{k:base[k] for k in ['id','name','version','description','minAppVersion']},'path':path,'sha256':hashlib.sha256((out/'youtube-music-android.rpmx').read_bytes()).hexdigest()})
    if raw['id']!='rp.letras-locales': rows.append(raw)
rows.append({**{k:local[k] for k in ['id','name','version','description','minAppVersion']},'path':'previews/0.3.5/letras-locales.rpmx','sha256':hashlib.sha256((out/'letras-locales.rpmx').read_bytes()).hexdigest()})
(root/'catalog.json').write_text(json.dumps({'schemaVersion':1,'extensions':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Dos candidatos locales 0.3.5 generados; catálogo local sin Spotify.')
