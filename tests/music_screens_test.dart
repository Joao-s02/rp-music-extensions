import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rp_music/extensions/program_package.dart';
import 'package:rp_music/extensions/program_controller.dart';
import 'package:rp_music/extensions/javascript_screen_service.dart';
import 'package:rp_music/extensions/javascript_screen_view.dart';
import 'package:rp_music/app/library_controller.dart';
import 'package:rp_music/data/local_store.dart';
import 'package:rp_music/data/music_files.dart';
import 'package:rp_music/playback/music_handler.dart';

import '../../../test/playback_and_ui_test.dart' show FakePlayer;

class MemoryStore extends LocalStore {
  MemoryStore() : super(Directory('unused-screen-tests'));
  Map<String, dynamic> data = {};
  @override
  Future<void> save(Map<String, dynamic> value) async {
    data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> load() async => data;
}

ProgramPackage loadScreen(String slug) => ProgramPackage.parse(
  jsonDecode(
    File('dist/extensions-repository/previews/js-music-0.1.0/$slug.rpmx')
        .readAsStringSync(),
  ) as Map<String, dynamic>,
);
Map<String, dynamic> response(Object body) => {
  'status': 200,
  'body': jsonEncode(body),
  'cookies': <String>[],
};
Map<String, dynamic> song(int i) => {
  'musicResponsiveListItemRenderer': {
    'playlistItemData': {'videoId': 'demo${i.toString().padLeft(7, '0')}'},
    'flexColumns': [
      {
        'musicResponsiveListItemFlexColumnRenderer': {
          'text': {
            'runs': [
              {'text': 'Song $i'},
            ],
          },
        },
      },
      {
        'musicResponsiveListItemFlexColumnRenderer': {
          'text': {
            'runs': [
              {
                'text': 'Artist',
                'navigationEndpoint': {
                  'browseEndpoint': {'browseId': 'UCdemo'},
                },
              },
            ],
          },
        },
      },
    ],
  },
};
Map<String, dynamic> radio(int i, {String? url, int hls = 0}) => {
  'stationuuid': 'station-$i',
  'name': 'Radio $i',
  'country': 'Bolivia',
  'tags': 'rock,pop',
  'url_resolved': url ?? 'https://stream.example.com/live$i.mp3',
  'codec': 'MP3',
  'hls': hls,
};

void main() {
  test('explorer package navigates artist/album, real continuation and back through QuickJS', () async {
    final p = loadScreen('explorador-musical'),
        programs = ProgramController(MemoryStore());
    addTearDown(programs.dispose);
    await programs.install(p, p.permissions);
    final requests = <Map<String, dynamic>>[];
    final service = JavascriptScreenService(
      programs,
      transport: (request, package) async {
        requests.add(request);
        final body = request['body'] as Map;
        if (body['query'] != null) {
          return response({
            'contents': [
              {
                'musicTwoRowItemRenderer': {
                  'title': {
                    'runs': [
                      {'text': 'Demo artist'},
                    ],
                  },
                  'navigationEndpoint': {
                    'browseEndpoint': {'browseId': 'UCdemo'},
                  },
                },
              },
            ],
          });
        }
        if (body['browseId'] == 'UCdemo') {
          return response({
            'contents': [
              {
                'musicTwoRowItemRenderer': {
                  'title': {
                    'runs': [
                      {'text': 'Demo album'},
                    ],
                  },
                  'navigationEndpoint': {
                    'browseEndpoint': {'browseId': 'MPREdemo'},
                  },
                },
              },
            ],
          });
        }
        return response({
          'musicPlaylistShelfRenderer': {
            'contents': List.generate(100, song),
            'continuations': body['continuation'] == null
                ? [
                    {
                      'nextContinuationData': {'continuation': 'next-page'},
                    },
                  ]
                : [],
          },
          'recommendations': {
            'nextContinuationData': {'continuation': 'wrong'},
          },
        });
      },
    );
    await service.run(p.id, {
      'action': 'search:artist',
      'fields': {'query': 'Demo'},
    });
    await service.run(p.id, {'action': 'item:0'});
    await service.run(p.id, {'action': 'item:0'});
    expect(programs.privateData[p.id]!['items'], hasLength(100));
    expect(programs.privateData[p.id]!['cursor'], 'next-page');
    await service.run(p.id, {'action': 'next'});
    expect(programs.privateData[p.id]!['page'], 1);
    await service.run(p.id, {'action': 'more'});
    expect((requests.last['body'] as Map)['continuation'], 'next-page');
    expect(programs.privateData[p.id]!['cursor'], '');
    await service.run(p.id, {'action': 'back'});
    expect((requests.last['body'] as Map)['browseId'], 'UCdemo');
  });
  test('explorer prepares AAC audio and reports unavailable tracks without corrupting state', () async {
    final p = loadScreen('explorador-musical'),
        programs = ProgramController(MemoryStore());
    addTearDown(programs.dispose);
    await programs.install(p, p.permissions);
    await programs.savePrivate(p.id, {
      'items': [
        {
          'id': 'abcdefghijk',
          'title': 'Song',
          'artist': 'Artist',
          'kind': 'song',
        },
      ],
    });
    var fail = false;
    final service = JavascriptScreenService(
      programs,
      transport: (r, p) async {
        if (r['method'] == 'POST') {
          return response({
            'playabilityStatus': {'status': fail ? 'LOGIN_REQUIRED' : 'OK'},
            'streamingData': {
              'adaptiveFormats': [
                {
                  'itag': 140,
                  'mimeType': 'audio/mp4',
                  'url': 'https://audio.googlevideo.com/audio.m4a',
                },
              ],
            },
          });
        }
        return {
          'status': 200,
          'body': 'ytcfg.set({"STS":123,"INNERTUBE_CONTEXT":{"client":{"visitorData":"visitor"}}});',
          'cookies': ['visitor=cookie'],
        };
      },
    );
    final result = await service.run(p.id, {'action': 'item:0'});
    expect(
      result['playRemote']['url'],
      'https://audio.googlevideo.com/audio.m4a',
    );
    final track = service.remoteTrack(p.id, result['playRemote']);
    expect(track.sourceId, p.id);
    fail = true;
    final unavailable = await service.run(p.id, {'action': 'item:0'});
    expect(unavailable['playRemote'], isNull);
    expect(jsonEncode(unavailable['view']), contains('no está disponible'));
    final invalid = await service.run(p.id, {
      'action': 'search:playlist',
      'fields': {'query': 'https://evil.org/playlist?list=PLdemo'},
    });
    expect(jsonEncode(invalid['view']), contains('enlace HTTPS'));
  });
  test('radio filters unsafe and HLS stations, favorites persist and playback refreshes UUID', () async {
    final store = MemoryStore(), programs = ProgramController(store);
    addTearDown(programs.dispose);
    final p = loadScreen('radio-internet');
    await programs.install(p, p.permissions);
    final requests = <Map<String, dynamic>>[];
    final service = JavascriptScreenService(
      programs,
      transport: (r, p) async {
        requests.add(r);
        final url = r['url'] as String;
        if (url.contains('/byuuid/')) {
          return response([radio(1, url: 'https://new.example.com/live.mp3')]);
        }
        if (url.contains('/json/url/')) return response({'ok': true});
        return response([
          radio(1),
          radio(2, url: 'http://insecure.example.com/audio'),
          radio(3, hls: 1),
        ]);
      },
    );
    await service.run(p.id, {
      'action': 'search',
      'fields': {'name': 'Radio', 'country': 'Bolivia', 'tag': 'rock'},
    });
    expect(programs.privateData[p.id]!['items'], hasLength(1));
    expect(requests.first['url'], contains('country=Bolivia'));
    expect(requests.first['headers']['User-Agent'], 'RP-Music/0.3.9');
    await service.run(p.id, {'action': 'fav:0'});
    expect(programs.privateData[p.id]!['favorites'], hasLength(1));
    final restored = ProgramController(store);
    addTearDown(restored.dispose);
    await restored.initialize();
    expect(restored.privateData[p.id]!['favorites'], hasLength(1));
    await service.run(p.id, {'action': 'favorites'});
    final play = await service.run(p.id, {'action': 'play:0'});
    expect(play['playRemote']['url'], 'https://new.example.com/live.mp3');
    expect(requests.last['url'], contains('/json/url/station-1'));
    await service.run(p.id, {'action': 'fav:0'});
    expect(programs.privateData[p.id]!['favorites'], isEmpty);
  });
  test('radio fails over mirrors and paginates without pretending a failed query succeeded', () async {
    final programs = ProgramController(MemoryStore());
    addTearDown(programs.dispose);
    final p = loadScreen('radio-internet');
    await programs.install(p, p.permissions);
    var calls = 0, offline = false;
    final service = JavascriptScreenService(
      programs,
      transport: (r, p) async {
        calls++;
        if (offline || calls == 1) throw const SocketException('offline');
        return response(List.generate(40, radio));
      },
    );
    await service.run(p.id, {'action': 'popular'});
    expect(calls, 2);
    expect(programs.privateData[p.id]!['mirror'], 1);
    expect(programs.privateData[p.id]!['hasMore'], isTrue);
    await service.run(p.id, {'action': 'more'});
    expect(programs.privateData[p.id]!['offset'], 40);
    offline = true;
    final result = await service.run(p.id, {
      'action': 'search',
      'fields': {'name': 'test'},
    });
    expect(jsonEncode(result['view']), contains('No se pudo consultar'));
    expect(programs.installed[p.id]!.failures, 0);
  });
  for (final slug in ['explorador-musical', 'radio-internet']) {
    testWidgets('$slug renders its actual package at 360px with large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final programs = ProgramController(MemoryStore()), p = loadScreen(slug);
      await tester.runAsync(() => programs.install(p, p.permissions));
      final library = LibraryController(MemoryStore(), MusicFiles()),
          audio = MusicHandler(player: FakePlayer());
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: JavascriptScreenView(
                programs: programs,
                extensionId: p.id,
                library: library,
                audio: audio,
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pumpAndSettle();
      expect(find.text(p.name), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await audio.close();
      library.dispose();
      programs.dispose();
    });
  }
}
