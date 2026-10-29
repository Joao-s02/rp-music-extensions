"""Build local candidates; never modifies the published catalog or old packages."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent
out = root / 'previews/0.3.16'
out.mkdir(parents=True, exist_ok=True)
for name in ['youtube-music-android', 'youtube-music-windows', 'youtube-explorer', 'youtube-explorer-windows']:
    package = json.loads((root / f'previews/0.3.13/{name}.rpmx').read_text(encoding='utf-8'))
    source = package['source']
    watch = (root / 'sources/watch_metadata_0316.dart').read_text(encoding='utf-8')
    source = source.replace('Map<String,dynamic> startLyrics(Map<String,dynamic> input) {', watch + '''
Map<String,dynamic> startLyrics(Map<String,dynamic> input) {
  final String inputAlbum=normal(stringValue(input['album']));
  if(input['operation']=='metadata' && input['sourceChecked']!=true && input['id'] is String && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(input['id'] as String) && <String>['','sin album','unknown album','album desconocido'].contains(inputAlbum)) return watchMetadataStart(input);
''')
    source = source.replace("'albumLocked':input['albumLocked']==true", "'albumLocked':input['albumLocked']==true,'verifiedSourceTags':input.containsKey('verifiedSourceTags') ? input['verifiedSourceTags'] : <String,dynamic>{},'verifiedSourceArtwork':input.containsKey('verifiedSourceArtwork') ? input['verifiedSourceArtwork'] : ''")
    source = source.replace("final Map<String,dynamic> output=<String,dynamic>{'plainLyrics':'','complete':false};", "final Map<String,dynamic> output=<String,dynamic>{'plainLyrics':'','complete':false,'tags':c['verifiedSourceTags'] ?? <String,dynamic>{},'artwork':c['verifiedSourceArtwork'] ?? ''};")
    source = source.replace("output['tags']=<String,dynamic>{'title':c['title'],'artist':c['artist']};", "final Map<String,dynamic> sourceTags=Map<String,dynamic>.from(c['verifiedSourceTags'] ?? <String,dynamic>{});sourceTags['title']=c['title'];sourceTags['artist']=c['artist'];output['tags']=sourceTags;")
    source = source.replace("  if(operation=='lyrics' || operation=='metadata') {", "  if(operation=='lyrics' || operation=='metadata') {\n    if(stage=='metadata-source') return jsonEncode(watchMetadataResult(input));")
    source = source.replace("if(c['albumLocked']==true) {output['complete']=best!=null;return output;}", '')
    source = source.replace('fmt=json&limit=10&query=', 'fmt=json&limit=25&query=')
    # Unknown-album placeholders must not become a required album name.
    source = source.replace("wanted.isNotEmpty && wanted!='Sin álbum'", "wanted.isNotEmpty && !<String>['sin album','unknown album','album desconocido'].contains(normal(wanted))")
    # A verified Single/EP is preferable to no album. Albums still rank first.
    source = source.replace("if(group.containsKey('primary-type')==false || group['primary-type']!='Album') return 0;", "if(group.containsKey('primary-type')==false || !<String>['Album','Single','EP'].contains(group['primary-type'])) return 0;")
    # Partial metadata already identifies a release: don't lose its cover if the
    # subsequent track-number lookup fails. Try the matching release group too.
    anchor = "    c['recordingId']=best['id'];"
    assert anchor in source
    source = source.replace(anchor, """    output['artwork']='https://coverartarchive.org/release/'+(chosen['id'] as String)+'/front-1200';
    final List<String> covers=<String>[output['artwork'] as String];
    if(chosen.containsKey('release-group') && chosen['release-group'] is Map) {
      final Map group=chosen['release-group'] as Map;
      if(group.containsKey('id') && group['id'] is String) covers.add('https://coverartarchive.org/release-group/'+(group['id'] as String)+'/front-1200');
    }
    output['artworkAlternatives']=covers;
    if(c.containsKey('verifiedSourceArtwork') && stringValue(c['verifiedSourceArtwork']).isNotEmpty) covers.add(c['verifiedSourceArtwork'] as String);
""" + anchor)
    source = source.replace('/front-500', '/front-1200')
    # Prefer the source's actual music artwork over a 320px video thumbnail.
    source = source.replace("'artwork':'https://i.ytimg.com/vi/'+id+'/mqdefault.jpg'", "'artwork':songArtwork(row,id)")
    helper = r"""String songArtwork(dynamic node,String id) {
  if(node is Map) {
    if(node.containsKey('thumbnails') && node['thumbnails'] is List) {
      String best='';int width=0;
      for(final dynamic raw in node['thumbnails']) {
        final Map row=raw as Map;
        if(row.containsKey('url') && row['url'] is String) {
          final String url=row['url'] as String;
          final int size=row.containsKey('width') && row['width'] is int ? row['width'] as int : 0;
          if((url.startsWith('https://lh3.googleusercontent.com/') || url.startsWith('https://yt3.googleusercontent.com/') || url.startsWith('https://yt3.ggpht.com/') || url.startsWith('https://i.ytimg.com/')) && size>=width) {best=url;width=size;}
        }
      }
      if(best.isNotEmpty) return best.contains('googleusercontent.com/') || best.contains('ggpht.com/') ? best.replaceAll(RegExp(r'=w\d+-h\d+[^?]*$'),'=w1200-h1200-l90-rj') : best;
    }
    for(final dynamic value in node.values) {final String image=songArtwork(value,'');if(image.isNotEmpty) return image;}
  } else if(node is List) {for(final dynamic value in node) {final String image=songArtwork(value,'');if(image.isNotEmpty) return image;}}
  return id.isEmpty ? '' : 'https://i.ytimg.com/vi/'+id+'/hqdefault.jpg';
}
"""
    source = source.replace('List<dynamic> songs(', helper + 'List<dynamic> songs(', 1)
    assert len(source.encode('utf-8')) <= 65536
    package.update(source=source, version='0.2.3' if 'explorer' in name else '0.5.3', minAppVersion='0.3.16', description='Álbumes de canciones sueltas con respaldo de origen, singles/EP y portadas hasta 1200px de la edición o grupo identificado.')
    (out / f'{name}.rpmx').write_text(json.dumps(package, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
# Read-only browser pages explicitly opt into a short, host-bounded cache.
p = json.loads((root / 'previews/js-music-0.1.0/explorador-musical.rpmx').read_text(encoding='utf-8'))
p.update(source=(root / 'sources/music_screens_common.js').read_text(encoding='utf-8')+'\n'+(root / 'sources/explorador_musical_0316.js').read_text(encoding='utf-8'), version='0.1.1', minAppVersion='0.3.16')
(out / 'explorador-musical.rpmx').write_text(json.dumps(p, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(out / 'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in sorted(out.glob('*.rpmx'))), encoding='utf-8')
