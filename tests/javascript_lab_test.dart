import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/javascript_program_runtime.dart';
import 'package:rp_music/extensions/javascript_view_schema.dart';

void main(){
 final root=Directory(Platform.environment['RP_EXTENSIONS_REPO'] ?? 'dist/extensions-repository');
 ProgramPackage load(String path)=>ProgramPackage.parse(jsonDecode(File('${root.path}/$path').readAsStringSync()) as Map<String,dynamic>);
 test('real JavaScript lab implements its own routes, forms and actions',()async{
  final package=load('previews/js-lab-0.1.0/laboratorio-js.rpmx');
  Map<String,dynamic> state={};
  Future<Map<String,dynamic>> action(String action,{Map<String,dynamic> fields=const {},List<dynamic> tracks=const []})async{
   final result=await JavascriptProgramRuntime.execute(package.source,{'action':action,'state':state,'fields':fields,'tracks':tracks});
   validateJavascriptView(result['view']);state=Map<String,dynamic>.from(result['state'] as Map);return result;
  }
  await action('open');await action('name',fields:{'nickname':'Demo'});expect(state['name'],'Demo');
  await action('panel');await action('plus');expect(state['count'],1);expect(state['page'],'panel');
  final tracks=[{'id':'opaque','title':'Song','artist':'Artist'}];
  final library=await action('library',tracks:tracks);expect(jsonEncode(library['view']),contains('Song'));
  final play=await action('play:opaque',tracks:tracks);expect(play['play'],'opaque');
  expect((await action('play:unknown',tracks:tracks))['play'],null);
  await action('home');expect(state['page'],'home');expect(state['count'],1);
 });
 test('published YouTube packages remain unchanged and execute through Dart',()async{
  final stableFile=File('${root.path}/previews/0.3.5/youtube-music-android.rpmx');
  expect(sha256.convert(stableFile.readAsBytesSync()).toString(),'7caf7c3a08f5f7d1f3daf48d5ee384b71be8d087840859d8563686017ff88d2d');
  final stable=load('previews/0.3.5/youtube-music-android.rpmx');
  final explorer=load('previews/explorer-0.1.0/youtube-explorer.rpmx');
  expect(sha256.convert(File('${root.path}/previews/explorer-0.1.0/youtube-explorer.rpmx').readAsBytesSync()).toString(),'75f155625bc759ac48bd7aae97d6570937eac06139886b204a7a3b38cf137348');
  expect(stable.engine,'dart');expect(explorer.engine,'dart');
  final runtime=ProgramRuntime();
  final lyrics=await runtime.execute(stable.source,{'event':'source','operation':'lyrics','stage':'start','title':'Song','artist':'Artist','album':'','durationMs':0});
  expect(lyrics['request'],isA<Map>());
  final browse=await runtime.execute(explorer.source,{'event':'source','operation':'browse','stage':'start','query':'Artist','kind':'artist','date':'20261028'});
  expect(browse['request'],isA<Map>());
 });
}
