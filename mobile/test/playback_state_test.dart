import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
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

    setUp(() {
      player = _MockAudioPlayer();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
    });

    blocTest<PodcastBloc, PodcastState>(
      'stop clears the now-playing episode',
      build: () => PodcastBloc(_MockPodcastRepository(), player: player),
      seed: () => const EpisodeListSuccess(_podcast, [_episode], _episode, true),
      act: (bloc) => bloc.add(EpisodeStopped()),
      verify: (bloc) {
        final state = bloc.state as EpisodeListSuccess;
        expect(state.nowPlaying, isNull);
        expect(state.isPlaying, isFalse);
        expect(state.episodes, [_episode]);
        verify(() => player.stop()).called(1);
      },
    );
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
