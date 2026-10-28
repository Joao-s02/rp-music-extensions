import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/extension_http_transport.dart';

void check(bool valid,String message) {if(!valid) throw StateError(message);}
Future<void> main(List<String> args) async {
 final root=File.fromUri(Platform.script).parent.parent;
 final runtime=ProgramRuntime();
 for(final name in ['youtube-music-android','youtube-music-windows','youtube-explorer','youtube-explorer-windows']) {
  final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/0.3.11/$name.rpmx').readAsStringSync()) as Map<String,dynamic>);
  Future<Map<String,dynamic>> call(Map<String,dynamic> input) => runtime.execute(p.source,{'event':'source','stage':'start','date':'20261028',...input});
  final photo=await call({'operation':'artistArtwork','artist':'Luis Miguel'});
  check(photo['request'] is Map,'photo request $name');
  final fixture={'contents':[{'musicTwoRowItemRenderer':{'title':{'runs':[{'text':'Luis Miguel'}]},'navigationEndpoint':{'browseEndpoint':{'browseId':'UCtest'}},'thumbnailRenderer':{'thumbnails':[{'url':'https://lh3.googleusercontent.com/test'}]}}}]};
  final image=await call({'operation':'artistArtwork','stage':'artist-photo','context':photo['context'],'response':{'status':200,'body':jsonEncode(fixture)}});
  check(image['artwork']=='https://lh3.googleusercontent.com/test','photo matching $name: ${jsonEncode(image)}');
  final mismatch=await call({'operation':'artistArtwork','stage':'artist-photo','context':{'artist':'Other'},'response':{'status':200,'body':jsonEncode(fixture)}});
  check(mismatch.isEmpty,'photo ambiguous identity $name');
  final recordings=await call({'operation':'metadata','stage':'metadata-recordings','context':{'title':'Song','artist':'Artist','durationMs':200000,'album':'Original','result':{'tags':{'title':'Song'}}},'response':{'status':200,'body':jsonEncode({'recordings':[{'id':'recording','title':'Song','length':200000,'artist-credit':[{'name':'Artist'}],'releases':[{'id':'wrong','title':'Compilation','status':'Official','date':'2000','release-group':{'primary-type':'Album'}}]}]})}});
  check(recordings['request']==null,'must reject different album $name');
  final unknown=await call({'operation':'metadata','stage':'metadata-recordings','context':{'title':'Song','artist':'Artist','durationMs':200000,'album':'Sin álbum','result':{}},'response':{'status':200,'body':'{"recordings":[]}'}});
  check(unknown['request']==null,'must not guess unknown album $name');
  final locked=await call({'operation':'metadata','stage':'lyrics-search','context':{'title':'Song','artist':'Artist','durationMs':200000,'album':'Original','albumLocked':true},'response':{'status':200,'body':jsonEncode([{'trackName':'Song','artistName':'Artist','albumName':'Compilation','duration':200,'plainLyrics':'Text'}])}});
  check(locked['request']==null && locked['tags']['album']==null && locked['tags']['title']=='Song','locked album skips edition lookup and lyrics never change album $name');
  final exact=await call({'operation':'metadata','stage':'metadata-recordings','context':{'title':'Song','artist':'Artist','durationMs':200000,'album':'Original','result':{}},'response':{'status':200,'body':jsonEncode({'recordings':[{'id':'recording','title':'Song','length':200000,'artist-credit':[{'name':'Artist'}],'releases':[{'id':'b','title':'Original','status':'Official','date':'2000'},{'id':'a','title':'Original','status':'Official','date':'2000'}]}]})}});
  check(exact['context']['releaseId']=='a','stable edition tie break $name');
  if(p.sourceSpec!.browse) {
   final song={'musicResponsiveListItemRenderer':{'playlistItemData':{'videoId':'abcdefghijk'},'flexColumns':[{'musicResponsiveListItemFlexColumnRenderer':{'text':{'runs':[{'text':'Song'}]}}}]}};
   final header={'musicResponsiveHeaderRenderer':{'title':{'runs':[{'text':'Original'}]},'straplineTextOne':{'runs':[{'text':'Artist','navigationEndpoint':{'browseEndpoint':{'browseId':'UCartist'}}}]},'thumbnail':{'thumbnails':[{'url':'https://lh3.googleusercontent.com/album'}]}}};
   final page=await call({'operation':'browse','stage':'explorer-page','context':{'id':'MPREtest','kind':'album'},'response':{'status':200,'body':jsonEncode({'header':header,'musicPlaylistShelfRenderer':{'contents':[song]}})}});
   check(page['collection']['artwork']=='https://lh3.googleusercontent.com/album' && page['collection']['artist']=='Artist','album identity/cover $name');
   check(page['tracks'][0]['album']=='Original','album tracks $name');
  }
  if(args.contains('--live')) {
   final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(photo['request'] as Map),p);
   final actual=await call({'operation':'artistArtwork','stage':'artist-photo','context':photo['context'],'response':response});
   check(actual['artwork'] is String,'live photo $name');
   stdout.writeln('$name foto real: ${Uri.parse(actual['artwork'] as String).host}');
  }
  stdout.writeln('$name: intérprete real, edición incorrecta rechazada y foto validada');
 }
}
