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
