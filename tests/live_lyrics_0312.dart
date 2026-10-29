import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/extension_http_transport.dart';
import 'package:rp_music/domain/lyrics.dart';
Future<void> main() async {
 final root=File.fromUri(Platform.script).parent.parent;
 final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/0.3.12/youtube-explorer-windows.rpmx').readAsStringSync()) as Map<String,dynamic>);
 final runtime=ProgramRuntime();var stage='start';Map<String,dynamic> context={};Map<String,dynamic>? response;
 Map<String,dynamic> result={};
 for(var i=0;i<4;i++) {
  result=await runtime.execute(p.source,{'event':'source','operation':'metadata','stage':stage,'title':'La Incondicional','artist':'Luis Miguel','album':'Busca una mujer','albumLocked':true,'durationMs':0,'context':context,if(response!=null)'response':response});
  if(result['request']==null) break;
  context=Map<String,dynamic>.from(result['context'] as Map);stage=result['next'] as String;
  response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(result['request'] as Map),p);
 }
 final lyrics=Lyrics.parse(result['syncedLyrics'] as String? ?? '');
 if(lyrics.lines.isEmpty) throw StateError('No synced lyrics in live result');
 File('${root.parent.path}/0.3.12-live-lyrics-result.json').writeAsStringSync(jsonEncode(result));
 stdout.writeln('Consulta pública real: ${lyrics.lines.length} líneas con tiempos; identidad del álbum no reemplazada. Texto no mostrado.');
}
