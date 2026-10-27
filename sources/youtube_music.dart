import 'dart:convert';

String columnText(dynamic value) {
  if (value is! Map) return '';
  final dynamic renderer=value['musicResponsiveListItemFlexColumnRenderer'];
  if(renderer is! Map || renderer['text'] is! Map) return '';
  final dynamic runs=renderer['text']['runs'];
  if(runs is! List) return '';
  String result='';
  for(final dynamic run in runs) { if(run is Map && run['text'] is String) result+=run['text'] as String; }
  return result;
}
List<dynamic> songs(dynamic node,int depth) {
  final List<dynamic> output=<dynamic>[];
  if(depth>40) return output;
  if(node is Map) {
    final dynamic row=node['musicResponsiveListItemRenderer'];
    if(row is Map && row['playlistItemData'] is Map && row['flexColumns'] is List) {
      final dynamic id=row['playlistItemData']['videoId'];
      final List<dynamic> columns=row['flexColumns'] as List<dynamic>;
      final String title=columns.isEmpty ? '' : columnText(columns[0]);
      if(id is String && id.length==11 && title.isNotEmpty) output.add(<String,dynamic>{'id':id,'title':title,'artist':columns.length>1 ? columnText(columns[1]) : 'YouTube Music','artwork':'https://i.ytimg.com/vi/'+id+'/mqdefault.jpg'});
    }
    for(final dynamic value in node.values) {output.addAll(songs(value,depth+1));if(output.length>=30) break;}
  } else if(node is List) {for(final dynamic value in node) {output.addAll(songs(value,depth+1));if(output.length>=30) break;}}
  return output;
}
String run(String request) {
  final Map<String,dynamic> input=jsonDecode(request) as Map<String,dynamic>;
  final String operation=input['operation'] as String;
  final String stage=input['stage'] as String;
  if(operation=='lyrics' && stage=='start') {
    final String title=Uri.encodeQueryComponent(input['title'] as String);
    final String artist=Uri.encodeQueryComponent(input['artist'] as String);
    final int duration=(input['durationMs'] as int) ~/ 1000;
    return jsonEncode(<String,dynamic>{'next':'lyrics-result','request':<String,dynamic>{'url':'https://lrclib.net/api/get?track_name='+title+'&artist_name='+artist+(duration>0 ? '&duration='+duration.toString() : '')}});
  }
  if(operation=='lyrics' && stage=='lyrics-result') {
    final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
    if(response['status']==404) return jsonEncode(<String,dynamic>{'plainLyrics':''});
    if(response['status']!=200) return jsonEncode(<String,dynamic>{'error':'No se pudo consultar la letra.'});
    final Map<String,dynamic> data=jsonDecode(response['body'] as String) as Map<String,dynamic>;
    if(data['instrumental']==true) return jsonEncode(<String,dynamic>{'plainLyrics':'Instrumental'});
    return jsonEncode(<String,dynamic>{'syncedLyrics':data['syncedLyrics'],'plainLyrics':data['plainLyrics']});
  }
  if(operation=='search' && stage=='start') {
    final String query=(input['query'] as String).trim();
    return jsonEncode(<String,dynamic>{'next':'search-result','request':<String,dynamic>{'method':'POST','url':'https://music.youtube.com/youtubei/v1/search?prettyPrint=false','headers':<String,dynamic>{'User-Agent':'Mozilla/5.0'},'body':<String,dynamic>{'context':<String,dynamic>{'client':<String,dynamic>{'clientName':'WEB_REMIX','clientVersion':'1.'+(input['date'] as String)+'.01.00','hl':'es','gl':'BO'}},'query':query,'params':'EgWKAQIIAWoMEA4QChADEAQQCRAF'}}});
  }
  if(operation=='search' && stage=='search-result') {
    final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
    if(response['status']!=200) return jsonEncode(<String,dynamic>{'error':'No se pudo buscar en YouTube Music.'});
    final List<dynamic> output=<dynamic>[];
    final List<String> seen=<String>[];
    final List<dynamic> found=songs(jsonDecode(response['body'] as String),0);
    for(final dynamic row in found) {final String id=row['id'] as String;if(!seen.contains(id) && output.length<30) {seen.add(id);output.add(row);}}
    return jsonEncode(<String,dynamic>{'tracks':output});
  }
  if(operation=='resolve' && stage=='start') {
    final String id=input['id'] as String;
    if(id.length!=11) return jsonEncode(<String,dynamic>{'error':'Canción inválida.'});
    return jsonEncode(<String,dynamic>{'next':'prepare','context':<String,dynamic>{'id':id},'request':<String,dynamic>{'url':'https://www.youtube.com/watch?v='+id+'&hl=en','headers':<String,dynamic>{'User-Agent':'Mozilla/5.0'}}});
  }
  if(operation=='resolve' && stage=='prepare') {
    final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
    final String html=response['body'] as String;
    final int marker=html.indexOf('ytcfg.set({');
    if(response['status']!=200 || marker<0) return jsonEncode(<String,dynamic>{'error':'No se pudo preparar la canción.'});
    final String tail=html.substring(marker);
    final int begin=tail.indexOf('{');
    final int end=tail.indexOf('});');
    if(begin<0 || end<begin) return jsonEncode(<String,dynamic>{'error':'Formato del servicio no compatible.'});
    final Map<String,dynamic> config=jsonDecode(tail.substring(begin,end+1)) as Map<String,dynamic>;
    final Map<String,dynamic> context=input['context'] as Map<String,dynamic>;
    final Map<String,dynamic> headers=<String,dynamic>{'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36','X-Youtube-Client-Name':'VISIONOS','X-Youtube-Client-Version':'1.02','Origin':'https://www.youtube.com'};
    final List<dynamic> cookies=response['cookies'] as List<dynamic>;
    String cookie='';
    for(final dynamic part in cookies) {if(part is String) {if(cookie.isNotEmpty) cookie+='; '; cookie+=part;}}
    if(cookie.isNotEmpty) headers['Cookie']=cookie;
    final dynamic inner=config['INNERTUBE_CONTEXT'];
    if(inner is Map && inner['client'] is Map && inner['client']['visitorData'] is String) headers['X-Goog-Visitor-Id']=inner['client']['visitorData'];
    final Map<String,dynamic> body=<String,dynamic>{'context':<String,dynamic>{'client':<String,dynamic>{'clientName':'VISIONOS','clientVersion':'1.02','deviceMake':'Apple','deviceModel':'RealityDevice17,1','osName':'visionOS','osVersion':'26.5.23O471','hl':'en','timeZone':'UTC','utcOffsetMinutes':0}},'videoId':context['id']};
    if(config['STS']!=null) body['playbackContext']=<String,dynamic>{'contentPlaybackContext':<String,dynamic>{'html5Preference':'HTML5_PREF_WANTS','signatureTimestamp':config['STS']}};
    return jsonEncode(<String,dynamic>{'next':'audio','request':<String,dynamic>{'method':'POST','url':'https://www.youtube.com/youtubei/v1/player?prettyPrint=false','headers':headers,'body':body}});
  }
  if(operation=='resolve' && stage=='audio') {
    final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
    final Map<String,dynamic> data=jsonDecode(response['body'] as String) as Map<String,dynamic>;
    if(response['status']!=200 || data['playabilityStatus'] is! Map || data['playabilityStatus']['status']!='OK' || data['streamingData'] is! Map) return jsonEncode(<String,dynamic>{'error':'La canción no está disponible sin cuenta.'});
    final dynamic formats=data['streamingData']['adaptiveFormats'];
    String fallback='';
    if(formats is List) {
      for(final dynamic format in formats) {
        if(format is Map && format['url'] is String && format['mimeType'] is String && (format['mimeType'] as String).contains('audio/mp4')) {
          if(format['itag']==140) return jsonEncode(<String,dynamic>{'url':format['url']});
          if(format['itag']==139) fallback=format['url'] as String;
        }
      }
    }
    if(fallback.isNotEmpty) return jsonEncode(<String,dynamic>{'url':fallback});
    return jsonEncode(<String,dynamic>{'error':'No hay audio AAC compatible disponible.'});
  }
  return jsonEncode(<String,dynamic>{'error':'Operación no compatible.'});
}
