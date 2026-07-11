import '../home_screen.dart';

/// 서버가 꺼져 있을 때 웹 프로토타입과 같은 샘플 데이터.
class MockData {
  static const feed = <HomeChallenge>[
    HomeChallenge(
      id: 'mock-1',
      title: 'K-pop Hook Dance',
      handle: '@dance.signal',
      views: 184000,
      likes: 24000,
      votes: 8240,
    ),
    HomeChallenge(
      id: 'mock-2',
      title: 'One Take Fit Check',
      handle: '@daily.fit',
      views: 139000,
      likes: 18000,
      votes: 7690,
    ),
    HomeChallenge(
      id: 'mock-3',
      title: 'Street Move Battle',
      handle: '@move.ground',
      views: 121000,
      likes: 15000,
      votes: 7120,
    ),
    HomeChallenge(
      id: 'mock-4',
      title: 'Voice Sync Challenge',
      handle: '@sync.room',
      views: 96000,
      likes: 12000,
      votes: 6540,
    ),
    HomeChallenge(
      id: 'mock-5',
      title: 'Comedy Reaction Cut',
      handle: '@quick.laugh',
      views: 88000,
      likes: 10000,
      votes: 6020,
    ),
    HomeChallenge(
      id: 'mock-6',
      title: 'Glow Step Challenge',
      handle: '@show.runner',
      views: 92000,
      likes: 13000,
      votes: 5810,
    ),
  ];

  static List<HomeChallenge> ranked() {
    final rows = List<HomeChallenge>.from(feed)
      ..sort((a, b) => b.score.compareTo(a.score));
    return rows;
  }
}
