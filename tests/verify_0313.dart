import 'dart:convert';
import 'dart:io';
import 'package:rp_music/extensions/program_runtime.dart';
import 'package:rp_music/extensions/program_package.dart';
void check(bool value,String message){if(!value)throw StateError(message);}
Future<void> main() async {
 final root=File.fromUri(Platform.script).parent.parent;
 final runtime=ProgramRuntime();
 for(final name in ['youtube-music-android','youtube-music-windows','youtube-explorer','youtube-explorer-windows']) {
  final p=ProgramPackage.parse(jsonDecode(File('${root.path}/previews/0.3.13/$name.rpmx').readAsStringSync()) as Map<String,dynamic>);
  Future<Map<String,dynamic>> call(String stage,Map context,dynamic response) => runtime.execute(p.source,{'event':'source','operation':'metadata','stage':stage,'context':context,'response':{'status':200,'body':jsonEncode(response)}});
  final c={'title':'Song','artist':'Artist','album':'Sin álbum','durationMs':200000,'albumLocked':false};
  final lyrics=await call('lyrics-search',c,[{'trackName':'Song','artistName':'Artist','duration':200,'albumName':'Lyrics compilation','syncedLyrics':'[00:01]Hello','plainLyrics':'Hello'}]);
  check(lyrics['next']=='metadata-recordings','recording lookup $name');
  Map release(String id,String title,String date,{String type='Album',List<String> secondary=const []})=>{'id':id,'title':title,'date':date,'status':'Official','release-group':{'primary-type':type,'secondary-types':secondary}};
  final releases=[release('single','Song','1980',type:'Single'),release('comp','Hits','1970',secondary:['Compilation']),release('later','Original','2001'),release('original','Original','1990')];
  (releases.last['release-group'] as Map).remove('secondary-types');
  Map recording(List<Map> values)=>{'recordings':[{'id':'recording','title':'Song','length':200000,'artist-credit':[{'name':'Artist'}],'releases':values}]};
  final found=await call('metadata-recordings',lyrics['context'],recording(releases));
  if(found['context']==null) throw StateError('Missing context: $found');
  check(found['context']['releaseId']=='original','unknown album chooses official album, stable edition $name: $found');
  final missingLength=recording(releases);(missingLength['recordings'] as List)[0].remove('length');
  final optional=await call('metadata-recordings',lyrics['context'],missingLength);
  check(optional['context']['releaseId']=='original','optional length absent $name');
  final nullFields=jsonDecode(jsonEncode(recording([{'id':'missing','title':'Ignored','status':'Official','release-group':null},...releases]))) as Map;
  (nullFields['recordings'] as List)[0]['length']=null;
  final nullable=await call('metadata-recordings',lyrics['context'],nullFields);
  check(nullable['context']['releaseId']=='original','null fields rejected safely $name');
  final intro=jsonDecode(jsonEncode(recording(releases))) as Map;
  (intro['recordings'] as List)[0]['length']=208000;
  final compatible=await call('metadata-recordings',lyrics['context'],intro);
  check(compatible['context']['releaseId']=='original','small intro offset permitted for album only $name');
  (intro['recordings'] as List)[0]['length']=300000;
  final wrongDuration=await call('metadata-recordings',lyrics['context'],intro);
  check(wrongDuration['request']==null,'large duration difference rejected $name');
  final soundtrack=await call('metadata-recordings',lyrics['context'],recording([release('soundtrack','Original Soundtrack','1991',secondary:['Soundtrack'])]));
  check(soundtrack['context']['releaseId']=='soundtrack','valid soundtrack album is not mistaken for compilation $name');
  final reversed=await call('metadata-recordings',lyrics['context'],recording(releases.reversed.toList()));
  check(reversed['context']['releaseId']=='original','order independent $name');
  final partial=await runtime.execute(p.source,{'event':'source','operation':'metadata','stage':'metadata-release','context':found['context'],'response':{'status':503,'body':''}});
  check(partial['tags']['album']=='Original' && partial['tags']['albumVerified']==true && partial['complete']==false,'identified album survives release-detail failure $name');
  check(partial['syncedLyrics']=='[00:01]Hello','partial metadata keeps LRC $name');
  final result=await call('metadata-release',found['context'],{'title':'Original','date':'1990','artist-credit':[{'name':'Artist'}],'media':[{'position':1,'track-count':10,'tracks':[{'recording':{'id':'recording'},'title':'Song','position':3,'artist-credit':[{'name':'Artist'}]}]}]});
  check(result['tags']['album']=='Original' && result['tags']['albumVerified']==true && result['tags']['trackNumber']==3,'verified album tags $name');
  check(result['syncedLyrics']=='[00:01]Hello','lyrics survive metadata $name');
  final known={...Map<String,dynamic>.from(lyrics['context']),'album':'Known'};
  final kept=await call('metadata-recordings',known,recording([...releases,release('known','Known','2010')]));
  check(kept['context']['releaseId']=='known','known album wins $name');
  final locked=await call('lyrics-search',{...c,'album':'Locked','albumLocked':true},[]);
  check(locked['next']=='lyrics-fallback','lyrics still allowed $name');
  final lockedEnd=await call('lyrics-fallback',locked['context'],[]);
  check(lockedEnd['request']==null,'batch identity never reselected $name');
  final different=recording(releases);(different['recordings'] as List)[0]['title']='Other song';
  final rejected=await call('metadata-recordings',lyrics['context'],different);
  check(rejected['request']==null,'reject unrelated recording $name');
  stdout.writeln('$name: álbum desconocido/conocido, orden estable, etiquetas, LRC, lote y rechazo correctos');
 }
}
