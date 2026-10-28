import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/extension_http_transport.dart';
Future<void> main() async {
 final root=File.fromUri(Platform.script).parent.parent;
 final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/0.3.11/youtube-explorer-windows.rpmx').readAsStringSync()) as Map<String,dynamic>);
 final runtime=ProgramRuntime();
 Future<Map<String,dynamic>> call(Map<String,dynamic> input) => runtime.execute(p.source,{'event':'source','operation':'browse','stage':'start','date':'20261028',...input});
 final query=await call({'query':'The Weeknd My Dear Melancholy','kind':'album'});
 final search=await call({'query':'The Weeknd My Dear Melancholy','kind':'album','stage':query['next'],'context':query['context'],'response':await ExtensionHttpTransport.request(Map<String,dynamic>.from(query['request'] as Map),p)});
 final entity=search['entities'][0];print('Selected ${entity['title']}');
 final request=await call({'query':'','kind':'album','id':entity['id']});
 final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(request['request'] as Map),p);
 File('${root.parent.path}/0.3.11-live-album-response.json').writeAsStringSync(jsonEncode(response));
 final album=await call({'query':'','kind':'album','id':entity['id'],'stage':request['next'],'context':request['context'],'response':response});
 print(jsonEncode({'collection':album['collection'],'count':album['tracks'].length,'cursor':album['cursor']}));
}
