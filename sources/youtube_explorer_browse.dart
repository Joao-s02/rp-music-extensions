Map explorerScope(dynamic node,int depth) {
  if(depth>35) return <String,dynamic>{};
  if(node is Map) {
    for(final String key in <String>['musicPlaylistShelfRenderer','musicPlaylistShelfContinuation','musicShelfRenderer','musicShelfContinuation']) {
      if(node.containsKey(key)) return node[key] as Map;
    }
    for(final dynamic value in node.values) {final Map found=explorerScope(value,depth+1);if(found.isNotEmpty) return found;}
  } else if(node is List) {for(final dynamic value in node) {final Map found=explorerScope(value,depth+1);if(found.isNotEmpty) return found;}}
  return <String,dynamic>{};
}
String explorerText(dynamic value) {
  return columnText(<String,dynamic>{'musicResponsiveListItemFlexColumnRenderer':<String,dynamic>{'text':value}});
}
String explorerId(dynamic node,int depth) {
  if(depth>12) return '';
  if(node is Map) {
    if((node.containsKey('browseId') && node['browseId'] is String)) return node['browseId'] as String;
    if((node.containsKey('playlistId') && node['playlistId'] is String)) return 'VL'+(node['playlistId'] as String);
    for(final dynamic v in node.values) {final String id=explorerId(v,depth+1);if(id.isNotEmpty) return id;}
  } else if(node is List) {for(final dynamic v in node) {final String id=explorerId(v,depth+1);if(id.isNotEmpty) return id;}}
  return '';
}
List<dynamic> explorerEntities(dynamic node,int depth) {
  final List<dynamic> out=<dynamic>[];
  if(depth>35) return out;
  if(node is Map) {
    for(final String key in <String>['musicResponsiveListItemRenderer','musicTwoRowItemRenderer']) {
      if(node.containsKey(key)) {
      final dynamic row=node[key];
      if(row is Map) {
        if(row.containsKey('playlistItemData')==false) {
        String title=explorerText(row.containsKey('title') ? row['title'] : '');
        dynamic navigation=row.containsKey('navigationEndpoint') ? row['navigationEndpoint'] : null;
        if((row.containsKey('flexColumns') && row['flexColumns'] is List) && (row['flexColumns'] as List).isNotEmpty) {
          final dynamic first=row['flexColumns'][0];
          title=columnText(first);
          if(navigation==null) navigation=first;
        }
        final String id=explorerId(navigation,0);
        String kind='';
        if(id.startsWith('UC')) kind='artist';
        if(id.startsWith('MPRE')) kind='album';
        if(id.startsWith('VL')) kind='playlist';
        if(kind.isNotEmpty && title.isNotEmpty) out.add(<String,dynamic>{'id':id,'kind':kind,'title':title});
      }
    }
    }
    }
    for(final dynamic v in node.values) {out.addAll(explorerEntities(v,depth+1));if(out.length>=100) break;}
  } else if(node is List) {for(final dynamic v in node) {out.addAll(explorerEntities(v,depth+1));if(out.length>=100) break;}}
  return out;
}
String explorerCursor(dynamic node,int depth) {
  if(depth>35) return '';
  if(node is Map) {
    if((node.containsKey('nextContinuationData') && node['nextContinuationData'] is Map) && node['nextContinuationData']['continuation'] is String) return node['nextContinuationData']['continuation'] as String;
    if((node.containsKey('continuationCommand') && node['continuationCommand'] is Map) && node['continuationCommand']['token'] is String) return node['continuationCommand']['token'] as String;
    for(final dynamic v in node.values) {final String c=explorerCursor(v,depth+1);if(c.isNotEmpty) return c;}
  } else if(node is List) {for(final dynamic v in node) {final String c=explorerCursor(v,depth+1);if(c.isNotEmpty) return c;}}
  return '';
}
String explorerTitle(dynamic node,int depth) {
  if(depth>12) return '';
  if(node is Map) {
    for(final String key in <String>['musicDetailHeaderRenderer','musicResponsiveHeaderRenderer','musicImmersiveHeaderRenderer','musicVisualHeaderRenderer']) {
      if(node.containsKey(key) && node[key] is Map) {final String text=explorerText(node[key]['title']);if(text.isNotEmpty) return text;}
    }
    for(final dynamic v in node.values) {final String text=explorerTitle(v,depth+1);if(text.isNotEmpty) return text;}
  } else if(node is List) {for(final dynamic v in node) {final String text=explorerTitle(v,depth+1);if(text.isNotEmpty) return text;}}
  return '';
}
Map<String,dynamic> explorerBrowse(Map<String,dynamic> input) {
  if(input['stage']=='start') {
    String endpoint=(input.containsKey('id') && input['id'] is String) ? 'browse' : 'search';
    final Map<String,dynamic> body=<String,dynamic>{'context':<String,dynamic>{'client':<String,dynamic>{'clientName':'WEB_REMIX','clientVersion':'1.'+(input['date'] as String)+'.01.00','hl':'es','gl':'BO'}}};
    if((input.containsKey('cursor') && input['cursor'] is String)) {body['continuation']=input['cursor'];}
    else if((input.containsKey('id') && input['id'] is String)) {body['browseId']=input['id'];}
    else {
      String query=input['query'] as String;
      if(query.contains('://')) {
        final Uri url=Uri.parse(query);
        if(url.scheme!='https' || !<String>['music.youtube.com','www.youtube.com','youtube.com'].contains(url.host) || url.queryParameters['list']==null || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(url.queryParameters['list'] as String)) return <String,dynamic>{'error':'Introduce un enlace HTTPS de una lista pública de YouTube.'};
        body['browseId']='VL'+(url.queryParameters['list'] as String);endpoint='browse';
      } else {
        body['query']=query;
        final String kind=input['kind'] as String;
        final Map<String,dynamic> filters=<String,dynamic>{'song':'EgWKAQIIAWoMEA4QChADEAQQCRAF','artist':'EgWKAQIgAWoMEA4QChADEAQQCRAF','album':'EgWKAQIYAWoMEA4QChADEAQQCRAF','playlist':'EgWKAQIoAWoMEA4QChADEAQQCRAF'};
        body['params']=filters[kind];
      }
    }
    final Map<String,dynamic> context=<String,dynamic>{};
    if(body.containsKey('browseId')) {context['id']=body['browseId'];context['kind']=endpoint=='browse' && input.containsKey('id') ? input['kind'] : 'playlist';}
    if(input.containsKey('id')) {context['id']=input['id'];context['kind']=input['kind'];}
    return <String,dynamic>{'next':'explorer-page','context':context,'request':<String,dynamic>{'method':'POST','url':'https://music.youtube.com/youtubei/v1/'+endpoint+'?prettyPrint=false','headers':<String,dynamic>{'User-Agent':'Mozilla/5.0'},'body':body}};
  }
  final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
  if(response['status']!=200) return <String,dynamic>{'error':'No se pudo abrir la colección pública. Puede ser privada o no estar disponible.'};
  final dynamic data=jsonDecode(response['body'] as String);
  dynamic scope=data;
  if(input.containsKey('context') && input['context'] is Map) {
    final Map c=input['context'] as Map;
    if(c.containsKey('id') && c['kind']!='artist') {final Map shelf=explorerScope(data,0);if(shelf.isNotEmpty) scope=shelf;}
  }
  final List<dynamic> entities=<dynamic>[];final List<String> seen=<String>[];
  for(final dynamic row in explorerEntities(scope,0)) {final String key=row['kind']+':'+row['id'];if(!seen.contains(key) && entities.length<100) {seen.add(key);entities.add(row);}}
  final String cursor=explorerCursor(scope,0);
  final Map<String,dynamic> result=<String,dynamic>{'title':explorerTitle(data,0),'tracks':songs(scope,0),'entities':entities};
  if(cursor.isNotEmpty) result['cursor']=cursor;
  if(input.containsKey('context') && input['context'] is Map) {
    final Map c=input['context'] as Map;
    if(c.containsKey('id')) {
      final String title=explorerTitle(data,0);
      result['collection']=<String,dynamic>{'id':c['id'],'kind':c['kind'],'title':title.isEmpty ? 'Colección' : title};
    }
  }
  return result;
}
