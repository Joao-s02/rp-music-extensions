import 'dart:convert';
String run(String request) {
  final Map<String,dynamic> input=jsonDecode(request) as Map<String,dynamic>;
  final String operation=input['operation'] as String;
  final String stage=input['stage'] as String;
  if(operation=='lyrics' && stage=='start') {
    final String title=Uri.encodeQueryComponent(input['title'] as String);
    final String artist=Uri.encodeQueryComponent(input['artist'] as String);
    return jsonEncode(<String,dynamic>{'next':'lyrics','request':<String,dynamic>{'url':'https://lrclib.net/api/get?track_name='+title+'&artist_name='+artist}});
  }
  if(operation=='lyrics' && stage=='lyrics') {
    final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
    if(response['status']!=200) return jsonEncode(<String,dynamic>{'plainLyrics':''});
    final Map<String,dynamic> data=jsonDecode(response['body'] as String) as Map<String,dynamic>;
    return jsonEncode(<String,dynamic>{'plainLyrics':data['plainLyrics']});
  }
  if(stage=='start') {
    String id=operation=='resolve' ? input['id'] as String : (input['query'] as String).trim();
    final int marker=id.indexOf('/track/');
    if(marker>=0) {id=id.substring(marker+7);}
    final int question=id.indexOf('?');
    if(question>=0) id=id.substring(0,question);
    final int slash=id.indexOf('/');
    if(slash>=0) id=id.substring(0,slash);
    if(id.startsWith('spotify:track:')) id=id.substring(14);
    if(!RegExp(r'^[a-zA-Z0-9]{22}$').hasMatch(id)) return jsonEncode(<String,dynamic>{'error':'Pega un enlace público de canción de Spotify o su ID. Sin cuenta solo se ofrecen vistas previas, no canciones completas.'});
    return jsonEncode(<String,dynamic>{'next':'embed','context':<String,dynamic>{'id':id},'request':<String,dynamic>{'url':'https://open.spotify.com/embed/track/'+id,'headers':<String,dynamic>{'User-Agent':'Mozilla/5.0'}}});
  }
  if(stage=='embed') {
    final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
    final String html=response['body'] as String;
    final String marker='<script id="__NEXT_DATA__" type="application/json">';
    final int begin=html.indexOf(marker);
    if(response['status']!=200 || begin<0) return jsonEncode(<String,dynamic>{'error':'Spotify cambió su página pública o la canción no está disponible.'});
    final String tail=html.substring(begin+marker.length);
    final int end=tail.indexOf('</script>');
    if(end<0) return jsonEncode(<String,dynamic>{'error':'Respuesta de Spotify incompatible.'});
    final Map<String,dynamic> data=jsonDecode(tail.substring(0,end)) as Map<String,dynamic>;
    final Map<String,dynamic> entity=data['props']['pageProps']['state']['data']['entity'] as Map<String,dynamic>;
    final dynamic preview=entity['audioPreview'];
    if(preview is! Map || preview['url'] is! String) return jsonEncode(<String,dynamic>{'error':'Esta canción no ofrece vista previa pública sin cuenta.'});
    if(operation=='resolve') return jsonEncode(<String,dynamic>{'url':preview['url']});
    String artists='';
    final dynamic people=entity['artists'];
    if(people is List) for(final dynamic person in people) {if(person is Map && person['name'] is String) {if(artists.isNotEmpty) artists+=', '; artists+=person['name'] as String;}}
    final String id=(input['context'] as Map<String,dynamic>)['id'] as String;
    return jsonEncode(<String,dynamic>{'tracks':<dynamic>[<String,dynamic>{'id':id,'title':entity['title'],'artist':artists,'album':'Vista previa pública'}]});
  }
  return jsonEncode(<String,dynamic>{'error':'Operación no disponible.'});
}
