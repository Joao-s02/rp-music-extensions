// Exact video identity gives a source fallback independent of MusicBrainz.
Map watchMetadataRow(dynamic node,String id,int depth) {
  if(depth>35) return <String,dynamic>{};
  if(node is Map) {
    if(node.containsKey('playlistPanelVideoRenderer')) {
      final Map row=node['playlistPanelVideoRenderer'] as Map;
      if(row.containsKey('videoId') && stringValue(row['videoId'])==id) return row;
    }
    for(final dynamic value in node.values) {final Map row=watchMetadataRow(value,id,depth+1);if(row.isNotEmpty) return row;}
  } else if(node is List) {for(final dynamic value in node) {final Map row=watchMetadataRow(value,id,depth+1);if(row.isNotEmpty) return row;}}
  return <String,dynamic>{};
}
String watchText(dynamic value) {
  if(value is! Map) return '';
  final Map textNode=value as Map;
  if(textNode.containsKey('simpleText')) return stringValue(textNode['simpleText']);
  String text='';
  if(textNode.containsKey('runs') && textNode['runs'] is List) {for(final dynamic raw in textNode['runs']) {final Map run=raw as Map;text+=stringValue(run['text']);}}
  return text;
}
Map<String,dynamic> watchMetadataStart(Map<String,dynamic> input) {
  final Map<String,dynamic> context=<String,dynamic>{'input':input};
  return <String,dynamic>{'request':<String,dynamic>{'url':'https://music.youtube.com/youtubei/v1/next?prettyPrint=false','method':'POST','body':<String,dynamic>{'videoId':input['id'],'context':<String,dynamic>{'client':<String,dynamic>{'clientName':'WEB_REMIX','clientVersion':'1.'+(input['date'] as String)+'.01.00','hl':'es','gl':'BO'}}}},'next':'metadata-source','context':context};
}
Map<String,dynamic> watchMetadataResult(Map<String,dynamic> input) {
  final Map context=input['context'] as Map;
  final Map<String,dynamic> original=Map<String,dynamic>.from(context['input'] as Map);
  original['sourceChecked']=true;
  final Map response=input['response'] as Map;
  if(response['status']==200) {
    final Map row=watchMetadataRow(jsonDecode(response['body'] as String),original['id'] as String,0);
    if(row.isNotEmpty && row.containsKey('longBylineText') && row['longBylineText'] is Map) {
      String album='';String artist='';
      final Map byline=row['longBylineText'] as Map;
      if(byline.containsKey('runs') && byline['runs'] is List) {for(final dynamic raw in byline['runs']) {
        final Map run=raw as Map;
        if(run.containsKey('navigationEndpoint') && run['navigationEndpoint'] is Map) {
          final Map endpoint=run['navigationEndpoint'] as Map;
          if(endpoint.containsKey('browseEndpoint') && endpoint['browseEndpoint'] is Map) {
            final Map browse=endpoint['browseEndpoint'] as Map;
            final String id=browse.containsKey('browseId') ? stringValue(browse['browseId']) : '';
            if(id.startsWith('MPRE')) album=stringValue(run['text']);
            if(id.startsWith('UC')) {if(artist.isNotEmpty) artist+=', ';artist+=stringValue(run['text']);}
          }
        }
      }}
      final String title=watchText(row['title']);
      if(album.isNotEmpty && recordingMatches(original['title'] as String,original['artist'] as String,0,title,artist,0)) {
        original['album']=album;
        original['verifiedSourceTags']=<String,dynamic>{'album':album,'albumVerified':true};
        original['verifiedSourceArtwork']=songArtwork(row,'');
      }
    }
  }
  return startLyrics(original);
}
