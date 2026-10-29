from pathlib import Path
import json,hashlib
r=Path(__file__).resolve().parent; out=r/'previews/0.3.13';out.mkdir(exist_ok=True)
for name in ['youtube-music-android','youtube-music-windows','youtube-explorer','youtube-explorer-windows']:
 p=json.loads((r/f'previews/0.3.12/{name}.rpmx').read_text(encoding='utf-8'));s=p['source']
 s=s.replace("    if(wanted.isEmpty || wanted=='Sin álbum') return output;", "    final bool known=wanted.isNotEmpty && wanted!='Sin álbum';")
 s=s.replace("r['status']=='Official' && normal(wanted)==normal(r['title'] as String)","r['status']=='Official' && (!known || normal(wanted)==normal(r['title'] as String))")
 helper="""bool recordingMatches(String title,String artist,int duration,String candidateTitle,String candidateArtist,int candidateDuration) {
  if(matches(title,artist,0,candidateTitle,candidateArtist,0)==false) return false;
  if(normal(cleanTitle(title))!=normal(cleanTitle(candidateTitle))) return false;
  if(duration>0 && candidateDuration>0) {
    final int difference=(duration-candidateDuration).abs();
    if(difference>10000 && difference*100>duration*5) return false;
  }
  return true;
}
int recordingLength(Map row) {
  if(row.containsKey('length')==false || row['length']==null) return 0;
  final dynamic length=row['length'];
  if(length is int) return length as int;
  return 0;
}
int albumEdition(Map row) {
  if(row.containsKey('release-group')==false) return 0;
  if(row['release-group']==null) return 0;
  final dynamic raw=row['release-group'];
  if(raw is! Map) return 0;
  final Map group=raw as Map;
  if(group.containsKey('primary-type')==false || group['primary-type']!='Album') return 0;
  if(group.containsKey('secondary-types')) {
    if(group['secondary-types']==null) return 1;
    final dynamic types=group['secondary-types'];
    if(types is List && (types as List).contains('Compilation')) return 0;
  }
  return 1;
}
"""
 s=s.replace('Map<String,dynamic> metadataResult(',helper+'Map<String,dynamic> metadataResult(')
 s=s.replace("row['length'] is int ? row['length'] as int : 0","recordingLength(row as Map)")
 s=s.replace("if(matches(c['title'] as String,c['artist'] as String,c['durationMs'] as int,row['title'] as String,credit(row['artist-credit']),recordingLength(row as Map)))", "if(recordingMatches(c['title'] as String,c['artist'] as String,c['durationMs'] as int,row['title'] as String,credit(row['artist-credit']),recordingLength(row as Map)))")
 s=s.replace("              int points=0;", "              final int eligible=known ? 1 : albumEdition(r as Map);\n              int points=0;")
 old="if(points>rank || (points==rank && chosen!=null && (r['id'] as String).compareTo(chosen['id'] as String)<0))"
 new="if(eligible==1 && (points>rank || (points==rank && chosen!=null && (stringValue(r['date']).compareTo(stringValue(chosen['date']))<0 || (stringValue(r['date'])==stringValue(chosen['date']) && (r['id'] as String).compareTo(chosen['id'] as String)<0)))))"
 assert old in s;s=s.replace(old,new)
 s=s.replace("    c['recordingId']=best['id'];", """    final Map<String,dynamic> partial=<String,dynamic>{'title':c['title'],'artist':c['artist'],'album':chosen['title'],'albumVerified':true};
    if(stringValue(chosen['date']).isNotEmpty) partial['date']=chosen['date'];
    output['tags']=partial;
    c['result']=output;
    c['recordingId']=best['id'];""")
 assert len(s.encode('utf-8'))<=65536
 p.update(source=s,version='0.2.2' if 'explorer' in name else '0.5.2',minAppVersion='0.3.13',description='Recupera el álbum de una grabación compatible; conserva letras sincronizadas e identidad de descargas de álbum. Candidato local 0.3.13.')
 (out/f'{name}.rpmx').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(out/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in sorted(out.glob('*.rpmx'))),encoding='utf-8')
