import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/extension_http_transport.dart';
import 'package:rp_music/domain/lyrics.dart';
Future<void> main() async {
 final root=File.fromUri(Platform.script).parent.parent;
 final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/0.3.13/youtube-explorer-windows.rpmx').readAsStringSync()) as Map<String,dynamic>);
 final runtime=ProgramRuntime();var stage='start';Map<String,dynamic> context={};Map<String,dynamic>? response;
 Map<String,dynamic> result={};
 for(var i=0;i<7;i++) {
  result=await runtime.execute(p.source,{'event':'source','operation':'metadata','stage':stage,'title':'La Incondicional','artist':'Luis Miguel','album':'Sin álbum','albumLocked':false,'durationMs':258000,'context':context,if(response!=null)'response':response});
  if(result['request']==null) break;
  context=Map<String,dynamic>.from(result['context'] as Map);stage=result['next'] as String;
  final request=Map<String,dynamic>.from(result['request'] as Map);
  stdout.writeln('Etapa: $stage · ${Uri.parse(request['url'] as String).host}');
  for(var retry=0;retry<3;retry++){try{response=await ExtensionHttpTransport.request(request,p);if(stage.startsWith('metadata')) File('${root.parent.path}/0.3.13-$stage.json').writeAsStringSync(jsonEncode(response));break;}catch(e){if(retry==2)rethrow;await Future<void>.delayed(const Duration(seconds:2));}}
 }
 final lyrics=Lyrics.parse(result['syncedLyrics'] as String? ?? '');
 if(lyrics.lines.isEmpty) throw StateError('No synced lyrics in live result');
 stdout.writeln(jsonEncode({'tags':result['tags'],'timedLines':lyrics.lines.length}));
 if(result['tags'] is! Map || result['tags']['albumVerified']!=true || (result['tags']['album'] as String).toLowerCase()!='busca una mujer') throw StateError('No verified album in live result: ${result.keys}');
 File('${root.parent.path}/0.3.13-live-lyrics-result.json').writeAsStringSync(jsonEncode(result));
 stdout.writeln('Consulta pública real: ${lyrics.lines.length} líneas con tiempos; álbum Busca una mujer identificado desde Sin álbum. Texto no mostrado.');
}
