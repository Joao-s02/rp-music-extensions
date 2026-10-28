"""New candidates only: preserve every previously published package and catalog."""
from pathlib import Path
import json, hashlib
r=Path(__file__).resolve().parent
out=r/'previews/0.3.11';out.mkdir(exist_ok=True)
metadata=(r/'sources/metadata_lyrics.dart').read_text(encoding='utf-8')
metadata=metadata.replace("'album':input['album'] ?? ''", "'album':input['album'] ?? '', 'albumLocked':input['albumLocked']==true")
metadata=metadata.replace("    c['result']=output;", "    if(c['albumLocked']==true) {output['complete']=best!=null;return output;}\n    c['result']=output;")
# Lyrics are useful for text; their album is never an authoritative edition.
metadata=metadata.replace("output['tags']=<String,dynamic>{'title':best['trackName'],'artist':best['artistName'],'album':best['albumName']};","output['tags']=<String,dynamic>{'title':c['title'],'artist':c['artist']};")
metadata=metadata.replace("row['syncedLyrics'] is String && (row['syncedLyrics'] as String).isNotEmpty", "stringValue(row['syncedLyrics']).isNotEmpty")
metadata=metadata.replace("output['syncedLyrics']=best['syncedLyrics'];", "if(best.containsKey('syncedLyrics') && best['syncedLyrics']!=null) output['syncedLyrics']=best['syncedLyrics'];")
metadata=metadata.replace("output['instrumental']=best['instrumental']==true;", "output['instrumental']=best.containsKey('instrumental') && best['instrumental']==true;")
metadata=metadata.replace("if(r['release-group'] is Map", "if(r.containsKey('release-group') && r['release-group'] is Map")
metadata=metadata.replace("final String title=best==null ? c['title'] as String : best['trackName'] as String;","final String title=c['title'] as String;")
metadata=metadata.replace("final String artist=best==null ? c['artist'] as String : best['artistName'] as String;","final String artist=c['artist'] as String;")
metadata=metadata.replace("final String wanted=currentTags is Map ? stringValue(currentTags['album']) : c['album'] as String;","final String wanted=c['album'] as String;\n    if(wanted.isEmpty || wanted=='Sin álbum') return output;")
metadata=metadata.replace("r['status']=='Official')", "r['status']=='Official' && normal(wanted)==normal(r['title'] as String))")
metadata=metadata.replace("if(points>rank) {chosen=r;rank=points;best=row;}","if(points>rank || (points==rank && chosen!=null && (r['id'] as String).compareTo(chosen['id'] as String)<0)) {chosen=r;rank=points;best=row;}")
metadata=metadata.replace("output['tags']=tags;","tags['albumVerified']=true;\n        output['tags']=tags;")
(r/'sources/metadata_lyrics_0311.dart').write_text(metadata,encoding='utf-8')
browse=(r/'sources/youtube_explorer_browse.dart').read_text(encoding='utf-8')
# Preserve header metadata separately from the track shelf/recommendations.
helpers='''
String explorerImage(dynamic node,int depth) {
  if(depth>25) return '';
  if(node is Map) {
    if(node.containsKey('thumbnails')) {
      final List<dynamic> rows=node['thumbnails'] as List<dynamic>;
      String best='';
      for(final dynamic row in rows) {final String image=explorerImage(row,depth+1);if(image.isNotEmpty) best=image;}
      if(best.isNotEmpty) return best;
    }
    if(node.containsKey('url')) {
      final String image=stringValue(node['url']);
      if(image.startsWith('https://lh3.googleusercontent.com/') || image.startsWith('https://yt3.googleusercontent.com/') || image.startsWith('https://yt3.ggpht.com/') || image.startsWith('https://i.ytimg.com/')) return image;
    }
    for(final dynamic value in node.values) {final String image=explorerImage(value,depth+1);if(image.isNotEmpty) return image;}
  } else if(node is List) {for(final dynamic value in node) {final String image=explorerImage(value,depth+1);if(image.isNotEmpty) return image;}}
  return '';
}
Map explorerHeader(dynamic node,int depth) {
  if(depth>30) return <String,dynamic>{};
  if(node is Map) {
    for(final String key in <String>['musicDetailHeaderRenderer','musicResponsiveHeaderRenderer','musicImmersiveHeaderRenderer','musicVisualHeaderRenderer']) {
      if(node.containsKey(key)) return node[key] as Map;
    }
    for(final dynamic value in node.values) {final Map found=explorerHeader(value,depth+1);if(found.isNotEmpty) return found;}
  } else if(node is List) {for(final dynamic value in node) {final Map found=explorerHeader(value,depth+1);if(found.isNotEmpty) return found;}}
  return <String,dynamic>{};
}
String explorerArtist(dynamic node,int depth) {
  if(depth>12) return '';
  if(node is Map) {
    if(node.containsKey('text') && node.containsKey('navigationEndpoint')) {
      final String id=explorerId(node['navigationEndpoint'],0);
      if(id.startsWith('UC') && stringValue(node['text']).isNotEmpty) return stringValue(node['text']);
    }
    for(final dynamic value in node.values) {final String found=explorerArtist(value,depth+1);if(found.isNotEmpty) return found;}
  } else if(node is List) {for(final dynamic value in node) {final String found=explorerArtist(value,depth+1);if(found.isNotEmpty) return found;}}
  return '';
}
Map<String,dynamic> artistArtwork(Map<String,dynamic> input) {
  if(input['stage']=='start') {
    return <String,dynamic>{'next':'artist-photo','context':<String,dynamic>{'artist':input['artist']},'request':<String,dynamic>{'method':'POST','url':'https://music.youtube.com/youtubei/v1/search?prettyPrint=false','body':<String,dynamic>{'query':input['artist'],'params':'EgWKAQIgAWoMEA4QChADEAQQCRAF','context':<String,dynamic>{'client':<String,dynamic>{'clientName':'WEB_REMIX','clientVersion':'1.'+(input['date'] as String)+'.01.00','hl':'es','gl':'BO'}}}}};
  }
  final Map c=input['context'] as Map;
  final Map response=input['response'] as Map;
  if(response['status']!=200) return <String,dynamic>{};
  final dynamic data=jsonDecode(response['body'] as String);
  for(final dynamic entity in explorerEntities(data,0)) {
    if(entity['kind']=='artist' && normal(entity['title'] as String)==normal(c['artist'] as String) && stringValue(entity['artwork']).isNotEmpty) return <String,dynamic>{'artist':c['artist'],'artwork':entity['artwork']};
  }
  return <String,dynamic>{};
}
'''
browse=helpers+'\n'+browse
browse=browse.replace("out.add(<String,dynamic>{'id':id,'kind':kind,'title':title});","out.add(<String,dynamic>{'id':id,'kind':kind,'title':title,'artwork':explorerImage(row,0)});")
browse=browse.replace("result['collection']=<String,dynamic>{'id':c['id'],'kind':c['kind'],'title':title.isEmpty ? 'Colección' : title};","""final Map header=explorerHeader(data,0);
      result['collection']=<String,dynamic>{'id':c['id'],'kind':c['kind'],'title':title.isEmpty ? 'Colección' : title,'artwork':explorerImage(header,0),'artist':explorerArtist(header,0)};
      if(c['kind']=='album' && title.isNotEmpty) {
        final String albumArtist=explorerArtist(header,0);
        final List<dynamic> albumTracks=songs(scope,0);
        for(final dynamic item in albumTracks) {final Map track=item as Map;track['album']=title;if(albumArtist.isNotEmpty && (track['artist']=='YouTube Music' || track['artist']=='Artista desconocido')) track['artist']=albumArtist;}
        result['tracks']=albumTracks;
      }""")
(r/'sources/youtube_explorer_browse_0311.dart').write_text(browse,encoding='utf-8')
definitions=[('previews/0.3.5/youtube-music-android.rpmx','youtube-music-android.rpmx','0.5.0',False),('previews/0.3.10/youtube-music-windows.rpmx','youtube-music-windows.rpmx','0.5.0',False),('previews/explorer-0.1.0/youtube-explorer.rpmx','youtube-explorer.rpmx','0.2.0',True),('previews/0.3.10/youtube-explorer-windows.rpmx','youtube-explorer-windows.rpmx','0.2.0',True)]
for baseline,name,version,explorer in definitions:
 p=json.loads((r/baseline).read_text(encoding='utf-8'))
 source=p['source'];a=source.index('String stringValue(');b=source.index('String run(',a);source=source[:a]+metadata+'\n'+source[b:]
 if explorer:source=source[:source.index('Map explorerScope(')]+browse
 else:source+='\n'+browse
 source=source.replace("  if(operation=='browse')", "  if(operation=='artistArtwork') return jsonEncode(artistArtwork(input));\n  if(operation=='browse')",1) if explorer else source.replace("  if(operation=='lyrics' || operation=='metadata')", "  if(operation=='artistArtwork') return jsonEncode(artistArtwork(input));\n  if(operation=='lyrics' || operation=='metadata')",1)
 p.update(version=version,minAppVersion='0.3.11',source=source)
 if 'library.read' not in p['permissions']:p['permissions'].append('library.read')
 p['sourceConfig']['artistArtwork']=True
 p['sourceConfig']['domains']+=['lh3.googleusercontent.com','yt3.googleusercontent.com','yt3.ggpht.com']
 p['description']='Metadatos de álbum coherentes y fotos de artistas con caché privada. App 0.3.11. Candidato local.'
 assert len(source.encode())<=65536
 (out/name).write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(out/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in sorted(out.glob('*.rpmx'))),encoding='utf-8')
print('Cuatro candidatos 0.3.11; paquetes publicados y catálogo conservados')
