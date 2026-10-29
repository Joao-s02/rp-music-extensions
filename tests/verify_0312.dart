import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/program_package.dart';
void check(bool value,String message){if(!value)throw StateError(message);}
Future<void> main() async {
 final root=File.fromUri(Platform.script).parent.parent;
 final runtime=ProgramRuntime();
 for(final name in ['youtube-music-android','youtube-music-windows','youtube-explorer','youtube-explorer-windows','letras-locales']) {
  final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/0.3.12/$name.rpmx').readAsStringSync()) as Map<String,dynamic>);
  Future<Map<String,dynamic>> call(List<Map<String,dynamic>> rows,{String stage='lyrics-search',Map<String,dynamic>? context,int status=200}) => runtime.execute(p.source,{'event':name=='letras-locales'?'lyrics':'source','operation':'lyrics','stage':stage,'context':context ?? {'title':'Song','artist':'Artist','album':'Original','durationMs':200000},'response':{'status':status,'body':jsonEncode(rows)}});
  final plain={'trackName':'Song','artistName':'Artist','duration':200,'albumName':'Original','plainLyrics':'Plain text','syncedLyrics':'','instrumental':false};
  final sync={...plain,'albumName':'Other edition','syncedLyrics':'[00:00]First\n[00:02]Second'};
  final selected=await call([plain,sync]);
  check(selected['syncedLyrics']==sync['syncedLyrics'],'synced wins over album-only plain $name');
  final initial=await call([plain]);check(initial['request'] is Map && initial['next']=='lyrics-fallback','search broader for sync $name');
  final upgraded=await call([sync],stage:'lyrics-fallback',context:Map<String,dynamic>.from(initial['context'] as Map));
  check(upgraded['syncedLyrics']==sync['syncedLyrics'],'fallback upgrades plain $name');
  final failed=await call([],stage:'lyrics-fallback',status:503,context:Map<String,dynamic>.from(initial['context'] as Map));
  check(failed['plainLyrics']=='Plain text','keep text when second search fails $name');
  final unrelated=await call([{...sync,'duration':300}],stage:'lyrics-fallback',context:Map<String,dynamic>.from(initial['context'] as Map));
  check(unrelated['syncedLyrics']=='','reject different performance $name: ${jsonEncode(unrelated)}');
  if(name!='letras-locales') {
   final result=await runtime.execute(p.source,{'event':'source','operation':'metadata','stage':'lyrics-search','context':{'title':'Song','artist':'Artist','album':'Original','albumLocked':true,'durationMs':200000},'response':{'status':200,'body':jsonEncode([plain,sync])}});
   check(result['request']==null && result['tags']['album']==null && result['syncedLyrics']==sync['syncedLyrics'],'album metadata identity preserved $name');
  }
  stdout.writeln('$name: prioridad LRC, alternativa, fallo parcial, identidad y duración correctas');
 }
}
