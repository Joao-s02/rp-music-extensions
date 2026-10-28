import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/extension_http_transport.dart';
void check(bool value,String message) {if(!value) throw StateError(message);}
Future<void> main(List<String> args) async {
 final root=File.fromUri(Platform.script).parent.parent;
 final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/explorer-0.1.0/youtube-explorer.rpmx').readAsStringSync()) as Map<String,dynamic>);
 final runtime=ProgramRuntime();
 Future<Map<String,dynamic>> call(Map<String,dynamic> input) => runtime.execute(p.source,{'event':'source','operation':'browse','stage':'start','date':'20261028',...input});
 final start=await call({'query':'Luis Miguel','kind':'artist'});
 check((start['request'] as Map)['url'].toString().contains('/search?'),'search request');
 final browse=await call({'id':'MPREtest','kind':'album','query':''});
 check((browse['request'] as Map)['body']['browseId']=='MPREtest','browse id');
 final next=await call({'id':'MPREtest','kind':'album','query':'','cursor':'next'});
 check((next['request'] as Map)['body']['continuation']=='next','pagination');
 final invalid=await call({'query':'https://evil.example/playlist?list=PLabc','kind':'playlist'});
 check(invalid['error'] is String,'foreign link rejection');
 final fixture={'contents':[{'musicTwoRowItemRenderer':{'title':{'runs':[{'text':'Album'}]},'navigationEndpoint':{'browseEndpoint':{'browseId':'MPREtest'}}}}, {'musicResponsiveListItemRenderer':{'playlistItemData':{'videoId':'abcdefghijk'},'flexColumns':[{'musicResponsiveListItemFlexColumnRenderer':{'text':{'runs':[{'text':'Song'}]}}}]}}, {'continuationItemRenderer':{'continuationEndpoint':{'continuationCommand':{'token':'next'}}}}]};
 final page=await call({'stage':'explorer-page','response':{'status':200,'body':jsonEncode(fixture)}});
 check((page['tracks'] as List).length==1 && (page['entities'] as List).length==1 && page['cursor']=='next','page parsing');
 final collectionFixture={'musicPlaylistShelfRenderer':{'contents':[fixture['contents']![1]]}, 'continuations':[{'nextContinuationData':{'continuation':'recommendations'}}]};
 final scoped=await call({'stage':'explorer-page','context':{'id':'VLtest','kind':'playlist'},'response':{'status':200,'body':jsonEncode(collectionFixture)}});
 check(scoped['cursor']==null && (scoped['tracks'] as List).length==1,'exclude recommendations');
 final lyrics=await call({'operation':'lyrics','title':'Song','artist':'Artist','durationMs':0,'album':''});
 check(lyrics['request'] is Map,'inherited lyrics');
 stdout.writeln('7 comprobaciones del paquete real en dart_eval aprobadas.');
 if(args.contains('--live')) {
   for(final kind in ['artist','album','playlist']) {
     final request=await call({'query':'Luis Miguel','kind':kind});
     final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(request['request'] as Map),p);
     final page=await call({'stage':'explorer-page','response':response});
     check(page['error']==null && (page['entities'] as List).isNotEmpty,'live '+kind);
     final entity=(page['entities'] as List).first as Map;
     final open=await call({'id':entity['id'],'kind':entity['kind'],'query':''});
     final openedResponse=await ExtensionHttpTransport.request(Map<String,dynamic>.from(open['request'] as Map),p);
     final opened=await call({'stage':'explorer-page','response':openedResponse,'context':open['context']});
     check(opened['error']==null && ((opened['tracks'] as List).isNotEmpty || (opened['entities'] as List).isNotEmpty),'open '+kind);
     if(kind=='playlist' && opened['cursor'] is String) {
       final more=await call({'id':entity['id'],'kind':entity['kind'],'query':'','cursor':opened['cursor']});
       final nextResponse=await ExtensionHttpTransport.request(Map<String,dynamic>.from(more['request'] as Map),p);
       final nextPage=await call({'stage':'explorer-page','response':nextResponse,'context':more['context']});
       File('dist/explorer-continuation.json').writeAsStringSync(nextResponse['body'] as String);
       File('dist/explorer-first-page.json').writeAsStringSync(openedResponse['body'] as String);
       stdout.writeln(jsonEncode({'nextStatus':nextResponse['status'],'nextTracks':(nextPage['tracks'] as List?)?.length,'error':nextPage['error'],'sameCursor':nextPage['cursor']==opened['cursor']}));
       check(nextPage['error']==null && (nextPage['tracks'] as List).isNotEmpty && nextPage['cursor']!=opened['cursor'],'playlist continuation');
       stdout.writeln('Continuación real: '+(nextPage['tracks'] as List).length.toString()+' pistas.');
     }
     stdout.writeln('$kind: '+jsonEncode({'entities':(page['entities'] as List).length,'tracks':(opened['tracks'] as List).length,'children':(opened['entities'] as List).length,'more':opened['cursor']!=null}));
   }
 }
 if(args.contains('--long')) {
   final start=await call({'query':'500 canciones','kind':'playlist'});
   final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(start['request'] as Map),p);
   final page=await call({'stage':'explorer-page','response':response});
   bool verified=false;
   for(final entity in (page['entities'] as List).take(8)) {
     final open=await call({'id':entity['id'],'kind':'playlist','query':''});
     final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(open['request'] as Map),p);
     final first=await call({'stage':'explorer-page','response':response,'context':open['context']});
     if(first['cursor'] is String) {
       final more=await call({'id':entity['id'],'kind':'playlist','query':'','cursor':first['cursor']});
       final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(more['request'] as Map),p);
       final second=await call({'stage':'explorer-page','response':response,'context':more['context']});
       check(second['error']==null && (second['tracks'] as List).isNotEmpty && second['cursor']!=first['cursor'],'real long collection');
       stdout.writeln('Lista larga real: '+(first['tracks'] as List).length.toString()+' + '+(second['tracks'] as List).length.toString()+' pistas.');
       File('${root.path}/tests/explorer-live-list.json').writeAsStringSync(jsonEncode({'id':entity['id'],'kind':'playlist'}));
       verified=true;break;
     }
   }
   if(!verified) stdout.writeln('Paginación real omitida: los candidatos públicos no ofrecieron continuación.');
 }

}
