import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/extension_http_transport.dart';

void check(bool value, String message) { if (!value) throw StateError(message); }
Future<void> main(List<String> args) async {
  final root=File.fromUri(Platform.script).parent.parent;
  final runtime=ProgramRuntime();
  final package=ProgramPackage.parse(jsonDecode(await File('${root.path}/previews/0.3.5/youtube-music-android.rpmx').readAsString()) as Map<String,dynamic>);
  Future<Map<String,dynamic>> call(Map<String,dynamic> input) => runtime.execute(package.source,{'event':'source',...input});
  final start=await call({'operation':'lyrics','stage':'start','title':'Canción (Official Video)','artist':'Artista - Topic','durationMs':180000,'album':'Disco'});
  check((start['request'] as Map)['url'].toString().contains('track_name=Canci%C3%B3n&artist_name=Artista'),'Normalización');
  final c=start['context'];
  final fallback=await call({'operation':'lyrics','stage':'lyrics-search','context':c,'response':{'status':200,'body':'[]'}});
  check(fallback['next']=='lyrics-fallback','Fallback');
  final result=await call({'operation':'lyrics','stage':'lyrics-fallback','context':c,'response':{'status':200,'body':jsonEncode([
    {'trackName':'Canción (Live)','artistName':'Artista','duration':180,'plainLyrics':'No'},
    {'trackName':'Canción','artistName':'Otro','duration':180,'plainLyrics':'No'},
    {'trackName':'Canción','artistName':'Artista','duration':360,'plainLyrics':'No'},
    {'trackName':'Canción','artistName':'Artista','duration':180,'albumName':'Disco','plainLyrics':'Correcta','syncedLyrics':'[00:01]Correcta'},
  ])}});
  check(result['syncedLyrics']=='[00:01]Correcta','Selección de versión/duración');
  final metadata=await call({'operation':'metadata','stage':'lyrics-search','context':c,'response':{'status':200,'body':'[]'}});
  check(metadata['next']=='lyrics-fallback','Metadatos permiten fallback');
  final local=ProgramPackage.parse(jsonDecode(await File('${root.path}/previews/0.3.5/letras-locales.rpmx').readAsString()) as Map<String,dynamic>);
  final localStart=await runtime.execute(local.source,{'event':'lyrics','operation':'lyrics','stage':'start','title':'Prueba','artist':'Artista','album':'','durationMs':0});
  check(localStart['request'] is Map,'Paquete letras local real');
  stdout.writeln('5 comprobaciones de paquetes/intérprete aprobadas.');

  if(args.contains('--youtube')) {
    for(final query in ['Junior H Las Noches','Bad Bunny BAILE INoLVIDABLE','Luis Miguel La Incondicional']) {
    final first=await call({'operation':'search','stage':'start','query':query,'date':DateTime.now().toUtc().toIso8601String().substring(0,10).replaceAll('-','')});
    final response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(first['request'] as Map),package);
    final result=await call({'operation':'search','stage':'search-result','response':response});
    check(result['tracks'] is List && (result['tracks'] as List).isNotEmpty,'Búsqueda YouTube');
    final song=(result['tracks'] as List).first as Map;
    stdout.writeln(jsonEncode(song));
    var stage='start'; Map<String,dynamic> context={}; Map<String,dynamic>? last;
    for(var i=0;i<4;i++) {
      final output=await call({'operation':'lyrics','stage':stage,'context':context,'response':?last,'title':song['title'],'artist':song['artist'],'album':song['album'],'durationMs':song['durationMs']});
      if(output['request']==null) {
        final text=output['syncedLyrics'] ?? output['plainLyrics'] ?? '';
        check(text is String && text.isNotEmpty,'Letra del resultado real YouTube');
        stdout.writeln('YouTube → letras: ${text.length} caracteres, sincronizada ${output['syncedLyrics'] is String && (output['syncedLyrics'] as String).isNotEmpty}');
        break;
      }
      stage=output['next'] as String;context=Map<String,dynamic>.from(output['context'] as Map);
      last=await ExtensionHttpTransport.request(Map<String,dynamic>.from(output['request'] as Map),package);
      if(i==3) throw StateError('Límite de letras');
    }
    }
  }

  if(args.contains('--live')) {
    for(final song in [
      {'title':'Las Noches','artist':'Junior H','album':'','durationMs':0},
      {'title':'BAILE INoLVIDABLE','artist':'Bad Bunny','album':'','durationMs':0},
      {'title':'La Incondicional','artist':'Luis Miguel','album':'','durationMs':0},
    ]) {
      var stage='start'; Map<String,dynamic> context={}; Map<String,dynamic>? response;
      for(var i=0;i<8;i++) {
        final output=await call({...song,'operation':'metadata','stage':stage,'context':context,'response':?response});
        if(output['request']==null) {
          check(output['error']==null,'Red: ${output['error']}');
          final text=output['syncedLyrics'] ?? output['plainLyrics'] ?? '';
          check(text is String && text.isNotEmpty,'Letra real no encontrada');
          stdout.writeln('${song['title']}: letra ${text.length} caracteres; campos ${(output['tags'] as Map?)?.keys.join(',')}; edición ${output['complete']}; portada ${output['artwork']!=null}');
          break;
        }
        stage=output['next'] as String;
        context=Map<String,dynamic>.from(output['context'] as Map);
        response=await ExtensionHttpTransport.request(Map<String,dynamic>.from(output['request'] as Map),package);
        stdout.writeln('Etapa $stage: HTTP ${response['status']}');
        if(i==7) throw StateError('Límite de etapas');
      }
    }
  }
}
