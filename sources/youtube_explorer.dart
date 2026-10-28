import 'dart:convert';

String columnText(dynamic value) {
  if (value is! Map) return '';
  final dynamic renderer=value['musicResponsiveListItemFlexColumnRenderer'];
  if(renderer is! Map || renderer['text'] is! Map) return '';
  final Map text=renderer['text'] as Map;
  final dynamic runs=text.containsKey('runs') ? text['runs'] : <dynamic>[];
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
    if(row is Map && row['flexColumns'] is List) {
      String id='';
      if(row.containsKey('playlistItemData')) {
        final Map item=row['playlistItemData'] as Map;
        if(item.containsKey('videoId')) id=item['videoId'] as String;
      }
      final List<dynamic> columns=row['flexColumns'] as List<dynamic>;
      final String title=columns.isEmpty ? '' : columnText(columns[0]);
      if(id is String && id.length==11 && title.isNotEmpty) {
        String artist=''; String album=''; int duration=0;
        for(final dynamic col in columns) {
          final String column=columnText(col);
          for(final String part in column.split(' • ')) {
            final String time=part.trim();
            if(RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(time)) {
              int seconds=0;
              for(final String digits in time.split(':')) {seconds=seconds*60+int.parse(digits);}
              duration=seconds*1000;
            }
          }
          final dynamic renderer=col is Map ? col['musicResponsiveListItemFlexColumnRenderer'] : null;
          final dynamic runs=renderer is Map && renderer['text'] is Map && renderer['text'].containsKey('runs') ? renderer['text']['runs'] : <dynamic>[];
          if(runs is List) {for(final dynamic run in runs) {
            if(run is Map && run.containsKey('text') && run['text'] is String && run.containsKey('navigationEndpoint') && run['navigationEndpoint'] is Map) {
              final Map endpoint=run['navigationEndpoint'] as Map;
              if(endpoint.containsKey('browseEndpoint') && endpoint['browseEndpoint'] is Map) {
                final Map browseEndpoint=endpoint['browseEndpoint'] as Map;
                final dynamic rawBrowse=browseEndpoint.containsKey('browseId') ? browseEndpoint['browseId'] : '';
                final String browse=rawBrowse is String ? rawBrowse : '';
                if(browse.startsWith('UC')) {if(artist.isNotEmpty) artist+=', ';artist+=run['text'] as String;}
                if(browse.startsWith('MPRE')) album=run['text'] as String;
              }
            }
          }}
        }
        final dynamic fixed=row.containsKey('fixedColumns') ? row['fixedColumns'] : <dynamic>[];
        if(fixed is List) {for(final dynamic col in fixed) {
          final dynamic renderer=col is Map ? col['musicResponsiveListItemFixedColumnRenderer'] : null;
          final dynamic runs=renderer is Map && renderer['text'] is Map && renderer['text'].containsKey('runs') ? renderer['text']['runs'] : <dynamic>[];
          if(runs is List) {for(final dynamic run in runs) {
            if(run is Map && run['text'] is String) {
              final List<String> parts=(run['text'] as String).split(':');
              if(RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(run['text'] as String)) {
                int seconds=0;
                for(final String part in parts) {seconds=seconds*60+int.parse(part);}
                duration=seconds*1000;
              }
            }
          }}
        }}
        if(artist.isEmpty && columns.length>1) artist=columnText(columns[1]).split(' • ')[0];
        output.add(<String,dynamic>{'id':id,'title':title,'artist':artist.isEmpty ? 'YouTube Music' : artist,'album':album.isEmpty ? 'Sin álbum' : album,'durationMs':duration,'artwork':'https://i.ytimg.com/vi/'+id+'/mqdefault.jpg'});
      }
    }
    for(final dynamic value in node.values) {output.addAll(songs(value,depth+1));}
  } else if(node is List) {for(final dynamic value in node) {output.addAll(songs(value,depth+1));}}
  return output;
}
// Shared source fragment bundled into the installable programs, never imported
// dynamically by dart_eval. Provider-specific matching belongs in this repo.
String stringValue(dynamic value) => value is String ? value : '';
String cleanTitle(String value) {
  String text=value.replaceAll(RegExp(r'\((official[^)]*|audio[^)]*|video[^)]*|lyrics?[^)]*|letra[^)]*|visualizer[^)]*)\)',caseSensitive:false),' ');
  text=text.replaceAll(RegExp(r'\[(official[^\]]*|audio[^\]]*|video[^\]]*|lyrics?[^\]]*|letra[^\]]*|visualizer[^\]]*)\]',caseSensitive:false),' ');
  return text.replaceAll(RegExp(r'\s+'),' ').trim();
}
String cleanArtist(String value) => value.replaceAll(RegExp(r'\s*-\s*Topic$',caseSensitive:false),'').replaceAll(RegExp(r'VEVO$',caseSensitive:false),'').split(' • ')[0].trim();
String normal(String value) {
  String text=value.toLowerCase();
  final List<String> from=<String>['á','à','ä','â','é','è','ë','ê','í','ì','ï','î','ó','ò','ö','ô','ú','ù','ü','û','ñ'];
  final List<String> to=<String>['a','a','a','a','e','e','e','e','i','i','i','i','o','o','o','o','u','u','u','u','n'];
  for(int i=0;i<from.length;i++) {text=text.replaceAll(from[i],to[i]);}
  return text.replaceAll(RegExp(r'[^a-z0-9\u0400-\u9fff]+'),' ').replaceAll(RegExp(r'\s+'),' ').trim();
}
String version(String value) {
  final String text=' '+normal(value)+' ';
  String output='';
  for(final String word in <String>['live','remix','acoustic','instrumental','slowed','sped','nightcore','cover']) {
    if(text.contains(' '+word+' ')) output+=word+' ';
  }
  if(text.contains(' en vivo ')) output+='live ';
  return output;
}
bool similar(String a,String b,int threshold) {
  if(a==b && a.isNotEmpty) return true;
  if(a.isEmpty || b.isEmpty) return false;
  final List<String> left=a.split(' ');
  final List<String> right=b.split(' ');
  int hits=0;
  for(final String word in left) {if(right.contains(word)) hits++;}
  return 200*hits>=threshold*(left.length+right.length);
}
bool matches(String title,String artist,int duration,String candidateTitle,String candidateArtist,int candidateDuration) {
  if(version(title)!=version(candidateTitle)) return false;
  if(!similar(normal(cleanTitle(title)),normal(cleanTitle(candidateTitle)),82)) return false;
  if(!similar(normal(cleanArtist(artist)),normal(cleanArtist(candidateArtist)),55)) return false;
  if(duration>0 && candidateDuration>0) {
    final int difference=(duration-candidateDuration).abs();
    if(difference>5000 && difference*1000>duration*25) return false;
  }
  return true;
}
Map<String,dynamic> networkStep(String url,String next,Map<String,dynamic> context) => <String,dynamic>{'request':<String,dynamic>{'url':url,'delayMs':url.startsWith('https://musicbrainz.org/') ? 1100 : 0,'headers':<String,dynamic>{'User-Agent':'RP-Music/0.3.5 (https://github.com/Joao-s02/rp_music)'}},'next':next,'context':context};
Map<String,dynamic> startLyrics(Map<String,dynamic> input) {
  final String title=cleanTitle(input['title'] as String);
  final String artist=cleanArtist(input['artist'] as String);
  final Map<String,dynamic> context=<String,dynamic>{'title':title,'artist':artist,'durationMs':input['durationMs'] ?? 0,'album':input['album'] ?? ''};
  return networkStep('https://lrclib.net/api/search?track_name='+Uri.encodeQueryComponent(title)+'&artist_name='+Uri.encodeQueryComponent(artist),'lyrics-search',context);
}
Map<String,dynamic> lyricsResult(Map<String,dynamic> input) {
  final Map<String,dynamic> c=input['context'] as Map<String,dynamic>;
  final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
  if(response['status']!=200 && input['operation']!='metadata') return <String,dynamic>{'error':'No se pudo conectar con el proveedor de letras. Reintenta más tarde.'};
  final dynamic decoded=response['status']==200 ? jsonDecode(response['body'] as String) : <dynamic>[];
  if(decoded is! List) return <String,dynamic>{'error':'Respuesta de letras incompatible.'};
  dynamic best;
  int bestScore=-1;
  for(final dynamic row in decoded) {
    if(row is Map && row['trackName'] is String && row['artistName'] is String) {
      final int duration=row['duration']==null ? 0 : (int.tryParse(row['duration'].toString().split('.')[0]) ?? 0)*1000;
      if(matches(c['title'] as String,c['artist'] as String,c['durationMs'] as int,row['trackName'] as String,row['artistName'] as String,duration)) {
        int score=0;
        if(normal(c['album'] as String)==normal(stringValue(row['albumName']))) score+=3;
        if(row['syncedLyrics'] is String && (row['syncedLyrics'] as String).isNotEmpty) score+=1;
        if(score>bestScore) {best=row;bestScore=score;}
      }
    }
  }
  if(best==null && input['stage']=='lyrics-search' && response['status']==200) {
    return networkStep('https://lrclib.net/api/search?q='+Uri.encodeQueryComponent((c['title'] as String)+' '+(c['artist'] as String)),'lyrics-fallback',c);
  }
  final Map<String,dynamic> output=<String,dynamic>{'plainLyrics':'','complete':false};
  if(best!=null) {
    output['syncedLyrics']=best['syncedLyrics'];output['plainLyrics']=best['plainLyrics'] ?? '';output['instrumental']=best['instrumental']==true;
    output['tags']=<String,dynamic>{'title':best['trackName'],'artist':best['artistName'],'album':best['albumName']};
  }
  if(input['operation']=='metadata') {
    c['result']=output;
    final String title=best==null ? c['title'] as String : best['trackName'] as String;
    final String artist=best==null ? c['artist'] as String : best['artistName'] as String;
    final String query='recording:"'+title.replaceAll('"','')+'" AND artist:"'+artist.replaceAll('"','')+'"';
    return networkStep('https://musicbrainz.org/ws/2/recording/?fmt=json&limit=10&query='+Uri.encodeQueryComponent(query),'metadata-recordings',c);
  }
  return output;
}
String credit(dynamic rows) {
  String output='';
  if(rows is List) {for(final dynamic row in rows) {if(row is Map) {output+=stringValue(row['name'])+stringValue(row['joinphrase']);}}}
  return output;
}
Map<String,dynamic> metadataResult(Map<String,dynamic> input) {
  final Map<String,dynamic> c=input['context'] as Map<String,dynamic>;
  final Map<String,dynamic> output=c['result'] as Map<String,dynamic>;
  final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
  if(response['status']!=200) return output;
  final dynamic data=jsonDecode(response['body'] as String);
  if(data is! Map) return output;
  if(input['stage']=='metadata-recordings') {
    final dynamic recordings=data['recordings'];
    dynamic best;
    dynamic chosen;
    int rank=-1;
    final dynamic currentTags=output['tags'];
    final String wanted=currentTags is Map ? stringValue(currentTags['album']) : c['album'] as String;
    if(recordings is List) {for(final dynamic row in recordings) {
      if(row is Map && row['title'] is String && row['id'] is String) {
        if(matches(c['title'] as String,c['artist'] as String,c['durationMs'] as int,row['title'] as String,credit(row['artist-credit']),row['length'] is int ? row['length'] as int : 0)) {
          final dynamic releases=row['releases'];
          if(releases is List) {for(final dynamic r in releases) {
            if(r is Map && r['id'] is String && r['title'] is String && r['status']=='Official') {
              int points=0;
              if(wanted.isNotEmpty && normal(wanted)==normal(r['title'] as String)) points+=100;
              if(r['release-group'] is Map && r['release-group']['primary-type']=='Album') points+=10;
              if(stringValue(r['date']).isNotEmpty) points+=1;
              if(points>rank) {chosen=r;rank=points;best=row;}
            }
          }}
        }
      }
    }}
    if(best==null || chosen==null) return output;
    c['recordingId']=best['id'];
    c['releaseId']=chosen['id'];
    c['recordingTitle']=best['title'];
    return networkStep('https://musicbrainz.org/ws/2/release/'+(chosen['id'] as String)+'?fmt=json&inc=recordings+artist-credits','metadata-release',c);
  }
  if(input['stage']=='metadata-release') {
    final dynamic media=data['media'];
    if(media is! List) return output;
    for(final dynamic disc in media) {if(disc is Map && disc['tracks'] is List) {
      for(final dynamic track in disc['tracks']) {if(track is Map && track['recording'] is Map && track['recording']['id']==c['recordingId']) {
        final String artist=credit(track['artist-credit']);
        final String albumArtist=credit(data['artist-credit']);
        final Map<String,dynamic> tags=<String,dynamic>{'title':track['title'] ?? c['recordingTitle'],'album':data['title'],'date':data['date'],'trackNumber':track['position'],'trackTotal':disc['track-count'],'discNumber':disc['position'],'discTotal':media.length};
        if(artist.isNotEmpty) tags['artist']=artist;
        if(albumArtist.isNotEmpty) tags['albumArtist']=albumArtist;
        output['tags']=tags;
        output['artwork']='https://coverartarchive.org/release/'+(c['releaseId'] as String)+'/front-500';
        output['complete']=true;
        return output;
      }}
    }}
  }
  return output;
}

String run(String request) {
  final Map<String,dynamic> input=jsonDecode(request) as Map<String,dynamic>;
  final String operation=input['operation'] as String;
  final String stage=input['stage'] as String;
  if(operation=='browse') return jsonEncode(explorerBrowse(input));
  if(operation=='lyrics' || operation=='metadata') {
    if(stage=='start') return jsonEncode(startLyrics(input));
    if(stage=='lyrics-search' || stage=='lyrics-fallback') return jsonEncode(lyricsResult(input));
    if(stage=='metadata-recordings' || stage=='metadata-release') return jsonEncode(metadataResult(input));
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
