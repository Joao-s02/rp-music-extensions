"""Build new lyric fixes without modifying published packages or catalog."""
from pathlib import Path
import json,hashlib
r=Path(__file__).resolve().parent;out=r/'previews/0.3.12';out.mkdir(exist_ok=True)
function=(r/'sources/lyrics_result_0312.dart').read_text(encoding='utf-8')
for filename in ['youtube-music-android','youtube-music-windows','youtube-explorer','youtube-explorer-windows','letras-locales']:
 base=r/('previews/0.3.5/letras-locales.rpmx' if filename=='letras-locales' else 'previews/0.3.11/'+filename+'.rpmx')
 p=json.loads(base.read_text(encoding='utf-8'))
 source=p['source'];start=source.index('Map<String,dynamic> lyricsResult(');end=source.index('String credit(',start) if 'String credit(' in source[start:] else source.index('String run(',start)
 # Lyrics-only providers do not need the recording-release branches.
 replacement=function
 if filename=='letras-locales':
  start_meta=replacement.index("  if(input['operation']=='metadata')")
  replacement=replacement[:start_meta]+"  return output;\n}\n"
 source=source[:start]+replacement+'\n'+source[end:]
 p.update(source=source,minAppVersion='0.3.12',version='0.1.1' if filename=='letras-locales' else '0.2.1' if 'explorer' in filename else '0.5.1')
 p['description']='Prioriza letras sincronizadas de la misma interpretación sin cambiar la identidad del álbum. App 0.3.12. Candidato local.'
 assert len(source.encode())<=65536
 (out/(filename+'.rpmx')).write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(out/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in sorted(out.glob('*.rpmx'))),encoding='utf-8')
print('Cinco candidatos nuevos; catálogo y paquetes publicados intactos')
