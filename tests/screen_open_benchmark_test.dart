import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rp_music/data/local_store.dart';
import 'package:rp_music/extensions/program_controller.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/javascript_program_runtime.dart';
import 'package:rp_music/extensions/javascript_screen_service.dart';

class TimedStore extends LocalStore {
  TimedStore(super.directory):super(baseName:'extensions');
  final writes=<int>[];
  int bytes=0;
  @override Future<void> save(Map<String,dynamic> value) async {
    bytes=utf8.encode(jsonEncode(value)).length;
    final watch=Stopwatch()..start();
    await super.save(value);
    writes.add(watch.elapsedMicroseconds);
  }
}
void main() {
  test('diagnostic screen open timings; not an Android benchmark', () async {
    final repo=Directory('dist/extensions-repository');
    final temp=await Directory.systemTemp.createTemp('rp_screen_timing_');
    final store=TimedStore(temp);
    final programs=ProgramController(store);
    final report=<String,dynamic>{'platform':Platform.operatingSystem,'mode':'flutter-test JIT; not Android/release','packages':<dynamic>[]};
    try {
      final catalog=jsonDecode(File('${repo.path}/catalog.json').readAsStringSync()) as Map;
      for(final raw in catalog['extensions'] as List) {
        final row=raw as Map;
        final variants=row['versions'] as List?;
        final path=variants!=null && variants.isNotEmpty?(variants.last as Map)['path']:row['path'];
        final package=ProgramPackage.parse(jsonDecode(File('${repo.path}/$path').readAsStringSync()) as Map<String,dynamic>);
        programs.installed[package.id]=InstalledProgram(package,package.permissions,enabled:true);
      }
      await programs.persist();
      final service=JavascriptScreenService(programs,transport:(_,_)async=>throw StateError('Opening must not request network'));
      for(final item in programs.installed.values.where((p)=>p.package.engine=='javascript')) {
        final rows=<Map<String,dynamic>>[];
        for(var i=0;i<6;i++) {
          store.writes.clear();
          final watch=Stopwatch()..start();
          await service.run(item.package.id,{'action':'open','fields':<String,String>{}});
          final total=watch.elapsedMicroseconds/1000;
          final writes=List<int>.of(store.writes);
          final runtimeWatch=Stopwatch()..start();
          await JavascriptProgramRuntime.execute(item.package.source,{'action':'open','stage':'start','fields':<String,String>{},'state':programs.privateData[item.package.id]??{}});
          rows.add({'totalMs':total,'registryWrites':writes.length,'saveMs':writes.fold<int>(0,(a,b)=>a+b)/1000,'directRuntimeMs':runtimeWatch.elapsedMicroseconds/1000,'registryBytes':store.bytes});
        }
        (report['packages'] as List).add({'id':item.package.id,'runs':rows});
      }
      File('${repo.path}/tests/SCREEN-OPEN-WINDOWS-JIT.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      for(final package in report['packages'] as List) {
        final runs=package['runs'] as List;
        double average(String key)=>runs.skip(1).map((r)=>(r[key] as num).toDouble()).reduce((a,b)=>a+b)/5;
        // Diagnostic data only; there is no agreed performance budget.
        printOnFailure(jsonEncode(report));
        stdout.writeln('${package['id']}: first=${runs.first['totalMs']}ms; warm mean=${average('totalMs').toStringAsFixed(1)}ms; saves=${average('saveMs').toStringAsFixed(1)}ms; direct runtime=${average('directRuntimeMs').toStringAsFixed(1)}ms; bytes=${runs.last['registryBytes']}');
      }
    } finally {
      programs.dispose();
      // Only the newly created temporary directory is removed.
      final path=temp.absolute.path;
      if(!path.startsWith('${Directory.systemTemp.absolute.path}${Platform.pathSeparator}rp_screen_timing_')) {
        throw StateError('Unexpected temporary directory');
      }
      await temp.delete(recursive:true);
    }
  });
}
