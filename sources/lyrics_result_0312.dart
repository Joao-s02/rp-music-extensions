// Timed lyrics belong to the matching performance; album tags remain separate.
bool timedLyrics(String text) => RegExp(r'\[\d{1,3}:[0-5]\d(?:[.:]\d{1,3})?\]').hasMatch(text);
int lyricRank(Map row,Map c) {
  int score=timedLyrics(stringValue(row['syncedLyrics'])) ? 100 : 0;
  if(normal(stringValue(row['albumName']))==normal(c['album'] as String)) score+=3;
  if(stringValue(row['plainLyrics']).isNotEmpty) score+=1;
  return score;
}
Map<String,dynamic> lyricsResult(Map<String,dynamic> input) {
  final Map<String,dynamic> c=input['context'] as Map<String,dynamic>;
  final Map<String,dynamic> response=input['response'] as Map<String,dynamic>;
  dynamic best=c.containsKey('lyricCandidate') ? c['lyricCandidate'] : null;
  int bestScore=best==null ? -1 : lyricRank(best as Map,c);
  final dynamic decoded=response['status']==200 ? jsonDecode(response['body'] as String) : <dynamic>[];
  if(decoded is! List) return <String,dynamic>{'error':'Respuesta de letras incompatible.'};
  for(final dynamic row in decoded) {
    if(row is Map && row['trackName'] is String && row['artistName'] is String) {
      int duration=0;
      final dynamic seconds=row['duration'];
      if(seconds is int) duration=(seconds as int)*1000;
      if(seconds is double) duration=((seconds as double)*1000).round();
      if(matches(c['title'] as String,c['artist'] as String,c['durationMs'] as int,row['trackName'] as String,row['artistName'] as String,duration)) {
        final Map<String,dynamic> candidate=<String,dynamic>{'albumName':stringValue(row['albumName']),
          'syncedLyrics':stringValue(row['syncedLyrics']),'plainLyrics':stringValue(row['plainLyrics']),
          'instrumental':row.containsKey('instrumental') && row['instrumental']==true};
        final int score=lyricRank(candidate,c);
        if(score>bestScore) {best=candidate;bestScore=score;}
      }
    }
  }
  final bool synced=best!=null && timedLyrics(stringValue(best['syncedLyrics']));
  if(!synced && input['stage']=='lyrics-search' && response['status']==200) {
    // Respect the host's context limit when retaining a text-only candidate.
    if(best==null || utf8.encode(jsonEncode(best)).length<45000) {
      if(best!=null) c['lyricCandidate']=best;
      return networkStep('https://lrclib.net/api/search?q='+Uri.encodeQueryComponent((c['title'] as String)+' '+(c['artist'] as String)),'lyrics-fallback',c);
    }
  }
  final Map<String,dynamic> output=<String,dynamic>{'plainLyrics':'','complete':false};
  if(best!=null) {
    output['syncedLyrics']=best['syncedLyrics'];output['plainLyrics']=best['plainLyrics'];output['instrumental']=best['instrumental'];
    output['tags']=<String,dynamic>{'title':c['title'],'artist':c['artist']};
  }
  c.remove('lyricCandidate');
  if(response['status']!=200 && best==null && input['operation']!='metadata') return <String,dynamic>{'error':'No se pudo conectar con el proveedor de letras.'};
  if(input['operation']=='metadata') {
    if(c['albumLocked']==true) {output['complete']=best!=null;return output;}
    c['result']=output;
    final String title=c['title'] as String;final String artist=c['artist'] as String;
    final String query='recording:"'+title.replaceAll('"','')+'" AND artist:"'+artist.replaceAll('"','')+'"';
    return networkStep('https://musicbrainz.org/ws/2/recording/?fmt=json&limit=10&query='+Uri.encodeQueryComponent(query),'metadata-recordings',c);
  }
  return output;
}
