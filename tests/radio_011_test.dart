import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rp_music/extensions/program_controller.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/javascript_screen_service.dart';

import 'music_screens_test.dart' show MemoryStore;

void main() {
  test(
    'radio0.1.1 refreshes URL and records click in a single request',
    () async {
      final package = ProgramPackage.parse(
        jsonDecode(
          File('dist/extensions-repository/previews/0.3.10/radio-internet.rpmx')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final programs = ProgramController(MemoryStore());
      addTearDown(programs.dispose);
      await programs.install(package, package.permissions);
      await programs.savePrivate(package.id, {
        'items': [
          {
            'id': 'station-1',
            'title': 'Station',
            'artist': 'Country',
            'album': 'Live',
            'url': 'https://old.example.com/live.mp3',
          },
        ],
        'favorites': [],
      });
      var calls = 0;
      final service = JavascriptScreenService(
        programs,
        transport: (request, p) async {
          calls++;
          expect(request['url'], endsWith('/json/url/station-1'));
          return {
            'status': 200,
            'body': jsonEncode({
              'ok': 'true',
              'stationuuid': 'station-1',
              'name': 'Station',
              'url': 'https://new.example.com/live.mp3',
            }),
          };
        },
      );
      final result = await service.run(package.id, {'action': 'play:0'});
      expect(result['error'], isFalse);
      expect(result['playRemote']['url'], 'https://new.example.com/live.mp3');
      expect(calls, 1);
    },
  );
  test('radio0.1.1 rejects downgraded or mismatched stream replies', () async {
    final package = ProgramPackage.parse(
      jsonDecode(
        File('dist/extensions-repository/previews/0.3.10/radio-internet.rpmx')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final programs = ProgramController(MemoryStore());
    addTearDown(programs.dispose);
    await programs.install(package, package.permissions);
    await programs.savePrivate(package.id, {
      'items': [
        {
          'id': 'station-1',
          'title': 'Station',
          'url': 'https://old.example.com/live.mp3',
        },
      ],
    });
    for (final values in [
      {'stationuuid': 'station-1', 'url': 'http://insecure.example.com/a'},
      {'stationuuid': 'different', 'url': 'https://other.example.com/a'},
    ]) {
      final service = JavascriptScreenService(
        programs,
        transport: (r, p) async => {
          'status': 200,
          'body': jsonEncode({'ok': true, ...values}),
        },
      );
      final result = await service.run(package.id, {'action': 'play:0'});
      expect(result['error'], isTrue);
      expect(result['playRemote'], isNull);
    }
  });
}
