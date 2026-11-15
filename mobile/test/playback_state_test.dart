import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openair/core/audio/audio_controller.dart';
import 'package:openair/features/podcasts/bloc/podcast_bloc.dart';
import 'package:openair/features/podcasts/models/podcast_model.dart';
import 'package:openair/features/podcasts/repository/podcast_repository.dart';
import 'package:openair/features/tv/bloc/tv_bloc.dart';
import 'package:openair/features/tv/models/channel_model.dart';
import 'package:openair/features/tv/repository/channel_repository.dart';
import 'package:openair/features/vod/bloc/vod_bloc.dart';
import 'package:openair/features/vod/models/vod_model.dart';
import 'package:openair/features/vod/repository/vod_repository.dart';

class _MockPodcastRepository extends Mock implements PodcastRepository {}

class _MockVodRepository extends Mock implements VodRepository {}

class _MockChannelRepository extends Mock implements ChannelRepository {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockStreamUrl extends Mock implements StreamUrlResponse {}

const _podcast = Podcast(id: 'p1', title: 'Podcast', isPremium: false);
const _episode = Episode(
  id: 'e1',
  podcastId: 'p1',
  title: 'Episode',
  audioUrl: 'https://example.com/e1.mp3',
  isPremium: false,
);

void main() {
  group('PodcastBloc', () {
    late _MockAudioPlayer player;
    late _MockPodcastRepository repo;
    late AudioController audio;
    late PodcastBloc bloc;

    setUpAll(() {
      registerFallbackValue(AudioSource.uri(Uri.parse('https://example.com/a')));
    });

    setUp(() {
      player = _MockAudioPlayer();
      when(() => player.playerStateStream)
          .thenAnswer((_) => const Stream<PlayerState>.empty());
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.play()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      when(() => player.setAudioSource(any())).thenAnswer((_) async => null);

      repo = _MockPodcastRepository();
      when(() => repo.getEpisodes(any())).thenAnswer((_) async => [_episode]);
      when(() => repo.getEpisodeStreamUrl(any(), any()))
          .thenAnswer((_) async => 'https://example.com/e1.mp3');

      audio = AudioController(player: player);
      bloc = PodcastBloc(repo, audio);
    });

    tearDown(() async {
      await bloc.close();
      await audio.close();
    });

    /// Lets queued bloc events and stream updates run.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    Future<EpisodeListSuccess> loadedState() async {
      bloc.add(const EpisodesLoaded('p1', _podcast));
      await settle();
      return bloc.state as EpisodeListSuccess;
    }

    test('playing an episode goes through the shared player', () async {
      await loadedState();

      bloc.add(const EpisodePlayRequested(_episode));
      await settle();

      expect(audio.state!.id, AudioController.episodeId('e1'));
      expect(audio.state!.subtitle, 'Podcast');
      expect((bloc.state as EpisodeListSuccess).nowPlaying, _episode);
    });

    test('stop clears the now-playing episode', () async {
      await loadedState();
      bloc.add(const EpisodePlayRequested(_episode));
      await settle();

      bloc.add(EpisodeStopped());
      await settle();

      final state = bloc.state as EpisodeListSuccess;
      expect(state.nowPlaying, isNull);
      expect(state.isPlaying, isFalse);
      expect(state.episodes, [_episode]);
      expect(audio.state, isNull);
    });

    test('follows the shared player when it is stopped from elsewhere',
        () async {
      await loadedState();
      bloc.add(const EpisodePlayRequested(_episode));
      await settle();

      // For example from the mini player or the lock screen.
      await audio.stop();
      await settle();

      expect((bloc.state as EpisodeListSuccess).nowPlaying, isNull);
    });

    test('opening a podcast shows an episode that is already playing',
        () async {
      await audio.play(
        id: AudioController.episodeId('e1'),
        url: 'https://example.com/e1.mp3',
        title: 'Episode',
        isLive: false,
      );

      final state = await loadedState();

      expect(state.nowPlaying, _episode);
    });
  });

  group('VodBloc', () {
    late _MockVodRepository repo;

    setUp(() {
      repo = _MockVodRepository();
      when(() => repo.getStreamUrl(any()))
          .thenAnswer((_) async => 'https://example.com/v1.m3u8');
      when(() => repo.getVod(search: any(named: 'search')))
          .thenAnswer((_) async => <VodItem>[]);
    });

    const loaded = VodSuccess(
      items: [],
      categories: ['All'],
      selectedCategory: 'All',
    );

    blocTest<VodBloc, VodState>(
      'playing the same video twice produces two play requests',
      build: () => VodBloc(repo),
      seed: () => loaded,
      act: (bloc) => bloc
        ..add(const VodStreamRequested('v1', 'Video'))
        ..add(const VodStreamRequested('v1', 'Video')),
      expect: () => [
        isA<VodSuccess>().having((s) => s.playRequest, 'playRequest', 1),
        isA<VodSuccess>().having((s) => s.playRequest, 'playRequest', 2),
      ],
    );

    blocTest<VodBloc, VodState>(
      'searching after playing does not create a new play request',
      build: () => VodBloc(repo),
      seed: () => loaded,
      act: (bloc) => bloc
        ..add(const VodStreamRequested('v1', 'Video'))
        ..add(const VodSearched('news')),
      verify: (bloc) =>
          expect((bloc.state as VodSuccess).playRequest, 1),
    );
  });

  group('TvBloc', () {
    late _MockChannelRepository repo;

    setUp(() {
      repo = _MockChannelRepository();
      final stream = _MockStreamUrl();
      when(() => stream.url).thenReturn('https://example.com/tv.m3u8');
      when(() => repo.getStreamUrl(any())).thenAnswer((_) async => stream);
    });

    blocTest<TvBloc, TvState>(
      'playing a channel keeps the channel list and can be repeated',
      build: () => TvBloc(repo),
      seed: () => const TvChannelsSuccess(<Channel>[]),
      act: (bloc) => bloc
        ..add(const TvStreamRequested('c1', 'Channel'))
        ..add(const TvStreamRequested('c1', 'Channel')),
      expect: () => [
        isA<TvChannelsSuccess>()
            .having((s) => s.playRequest, 'playRequest', 1)
            .having((s) => s.streamUrl, 'streamUrl', 'https://example.com/tv.m3u8'),
        isA<TvChannelsSuccess>().having((s) => s.playRequest, 'playRequest', 2),
      ],
    );
  });
}
