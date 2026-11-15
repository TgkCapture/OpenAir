import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openair/core/audio/audio_controller.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStates;
  late AudioController audio;

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('https://example.com/a')));
  });

  setUp(() {
    player = _MockAudioPlayer();
    playerStates = StreamController<PlayerState>.broadcast();
    when(() => player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.seek(any())).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.setAudioSource(any())).thenAnswer((_) async => null);
    when(() => player.playing).thenReturn(false);
    audio = AudioController(player: player);
  });

  tearDown(() async {
    await audio.close();
    await playerStates.close();
  });

  Future<void> playRadio(String channelId) => audio.play(
        id: AudioController.radioId(channelId),
        url: 'https://example.com/$channelId',
        title: 'Channel $channelId',
        isLive: true,
      );

  /// Lets the player-state listener run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts with nothing loaded', () {
    expect(audio.state, isNull);
  });

  test('play loads the item, then reports playing once the player is ready',
      () async {
    await playRadio('1');

    expect(audio.state!.id, 'radio:1');
    expect(audio.state!.isLoading, isTrue);
    expect(audio.state!.isPlaying, isFalse);
    verify(() => player.setAudioSource(any())).called(1);
    verify(() => player.play()).called(1);

    playerStates.add(PlayerState(true, ProcessingState.ready));
    await settle();

    expect(audio.state!.isPlaying, isTrue);
    expect(audio.state!.isLoading, isFalse);
  });

  test('playing a second item replaces the first, so only one is audible',
      () async {
    await playRadio('1');
    await playRadio('2');

    expect(audio.state!.id, 'radio:2');
    // The player is stopped before each new source is loaded.
    verify(() => player.stop()).called(2);
  });

  test('stop clears the state and stops the player', () async {
    await playRadio('1');
    await audio.stop();

    expect(audio.state, isNull);
    verify(() => player.stop()).called(2);
  });

  test('toggle pauses when playing', () async {
    await playRadio('1');
    when(() => player.playing).thenReturn(true);

    await audio.toggle();

    verify(() => player.pause()).called(1);
  });

  test('toggle resumes a live stream from the live point', () async {
    await playRadio('1');
    when(() => player.playing).thenReturn(false);

    await audio.toggle();

    verify(() => player.seek(null)).called(1);
    verify(() => player.play()).called(2);
  });

  test('a stream that cannot be loaded clears the state and reports an error',
      () async {
    when(() => player.setAudioSource(any())).thenThrow(Exception('bad stream'));
    final errors = <String>[];
    final sub = audio.errors.listen(errors.add);

    await playRadio('1');
    await settle();

    expect(audio.state, isNull);
    expect(errors, ['Could not play Channel 1']);
    await sub.cancel();
  });

  test('player updates are ignored when nothing is loaded', () async {
    playerStates.add(PlayerState(true, ProcessingState.ready));
    await settle();

    expect(audio.state, isNull);
  });
}
