import 'package:flutter/material.dart';

import 'auth_screens.dart';
import 'home_screen.dart';

void main() {
  runApp(const ShowUpApp());
}

class Challenge {
  const Challenge({
    required this.title,
    required this.handle,
    required this.views,
    required this.likes,
    required this.votes,
  });

  final String title;
  final String handle;
  final int views;
  final int likes;
  final int votes;

  int get score => (views + likes * 0.2).round();
}

const challenges = <Challenge>[
  Challenge(title: 'K-pop Hook Dance', handle: '@dance.signal', views: 184000, likes: 24000, votes: 8240),
  Challenge(title: 'One Take Fit Check', handle: '@daily.fit', views: 139000, likes: 18000, votes: 7690),
  Challenge(title: 'Street Move Battle', handle: '@move.ground', views: 121000, likes: 15000, votes: 7120),
  Challenge(title: 'Voice Sync Challenge', handle: '@sync.room', views: 96000, likes: 12000, votes: 6540),
  Challenge(title: 'Comedy Reaction Cut', handle: '@quick.laugh', views: 88000, likes: 10000, votes: 6020),
  Challenge(title: 'Glow Step Challenge', handle: '@show.runner', views: 92000, likes: 13000, votes: 5810),
];

HomeChallenge toHomeChallenge(Challenge challenge) {
  return HomeChallenge(
    title: challenge.title,
    handle: challenge.handle,
    views: challenge.views,
    likes: challenge.likes,
    votes: challenge.votes,
  );
}

class ShowUpApp extends StatelessWidget {
  const ShowUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'show up',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffd7ff38)),
        scaffoldBackgroundColor: const Color(0xffeef0f3),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const ShowUpShell(),
    );
  }
}

enum MainTab { home, camera, vote, bet, rank }

class ShowUpShell extends StatefulWidget {
  const ShowUpShell({super.key});

  @override
  State<ShowUpShell> createState() => _ShowUpShellState();
}

class _ShowUpShellState extends State<ShowUpShell> {
  bool authVisible = true;
  bool introVisible = true;
  bool signupMode = false;
  bool cameraNoticeSeen = false;
  bool rankingExpanded = false;
  int feedIndex = 0;
  int predictionEditsLeft = 3;
  MainTab tab = MainTab.home;
  final picks = <int, Challenge?>{1: null, 2: null, 3: null};

  void toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void enterApp(String label) {
    setState(() => authVisible = false);
    toast('$label 완료');
  }

  void changeTab(MainTab next) {
    setState(() => tab = next);
    if (next == MainTab.camera && !cameraNoticeSeen) {
      cameraNoticeSeen = true;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xff101218),
          title: const Text('처음 한 번만 안내합니다', style: TextStyle(color: Colors.white)),
          content: const Text(
            '카메라 권한이 필요합니다. 노출, 도용, 동일 영상 반복 업로드는 제한됩니다.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인 및 허용'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: tab.index,
              children: [
                HomeScreen(
                  challenge: toHomeChallenge(challenges[feedIndex]),
                  ranking: rankedChallenges(),
                  onNext: nextFeed,
                  onAction: handleHomeAction,
                ),
                CameraScreen(onUpload: handleUpload, onGallery: () => toast('갤러리 선택')),
                VoteScreen(onVote: () => toast('투표를 해주셔서 감사합니다')),
                BetScreen(
                  picks: picks,
                  editsLeft: predictionEditsLeft,
                  onPick: openPickSheet,
                  onLock: lockPrediction,
                ),
                RankScreen(expanded: rankingExpanded, onToggle: toggleRanking),
              ],
            ),
          ),
          bottomNavigationBar: BottomNav(current: tab, onTap: changeTab),
        ),
        if (authVisible) AuthGate(
          introVisible: introVisible,
          signupMode: signupMode,
          onStart: () => setState(() => introVisible = false),
          onToggle: (value) => setState(() => signupMode = value),
          onLogin: () => enterApp('로그인'),
          onSignup: () => enterApp('회원가입'),
          onForgot: openForgotDialog,
        ),
      ],
    );
  }

  void nextFeed() {
    setState(() => feedIndex = (feedIndex + 1) % challenges.length);
  }

  List<HomeChallenge> rankedChallenges() {
    final rows = challenges.map(toHomeChallenge).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return rows;
  }

  void handleHomeAction(String action) {
    switch (action) {
      case 'like':
        toast('좋아요를 눌렀습니다');
      case 'unlike':
        toast('좋아요를 취소했습니다');
      case 'comment':
        toast('댓글 화면은 다음 단계에서 연결됩니다');
      case 'report':
        toast('신고가 접수되었습니다 (프로토타입)');
      case 'share':
        toast('공유 링크를 복사했습니다 (프로토타입)');
      case 'notify':
        toast('새 알림이 없습니다');
      case 'search-empty':
        toast('검색어를 입력해 주세요');
      default:
        if (action.startsWith('search:')) {
          toast('프로필 검색: ${action.substring(7)}');
        }
    }
  }

  void handleUpload() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('upload ad'),
        content: const Text('광고 시청 후 업로드 완료 처리와 AI 검수가 시작됩니다.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              toast('AI 검수 중');
            },
            child: const Text('광고 완료'),
          ),
        ],
      ),
    );
  }

  void openForgotDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff12151c),
        title: const Text('Forgot password?', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이름과 전화번호(또는 이메일)로 본인 확인 후 비밀번호를 재설정합니다.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone or email',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffd7ff38),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              openResetPasswordDialog();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void openResetPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff12151c),
        title: const Text('New password', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffd7ff38),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              toast('비밀번호가 변경되었습니다');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void openPickSheet(int rank) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: challenges.take(5).map((challenge) {
          final duplicate = picks.entries.any((entry) => entry.key != rank && entry.value == challenge);
          return ListTile(
            enabled: !duplicate,
            title: Text(challenge.title),
            subtitle: Text(challenge.handle),
            onTap: duplicate ? null : () {
              final changing = picks[rank] != null && picks[rank] != challenge;
              if (changing && predictionEditsLeft <= 0) {
                Navigator.pop(context);
                toast('수정 횟수를 모두 사용했습니다');
                return;
              }
              setState(() {
                if (changing) predictionEditsLeft -= 1;
                picks[rank] = challenge;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void lockPrediction() {
    final completed = picks.values.every((value) => value != null);
    toast(completed ? '행운을 빕니다' : '1~3등을 모두 선택하세요');
  }

  void toggleRanking() {
    setState(() => rankingExpanded = !rankingExpanded);
  }
}

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key, required this.onUpload, required this.onGallery});

  final VoidCallback onUpload;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: darkGradient(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: WordBackground(words: ['UPLOAD', 'FILTER', 'MUSIC', '1 MIN', 'NO COPY'])),
            const Text('촬영 또는 갤러리 업로드', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const Text('영상 길이 1분 · 미리보기/재촬영 가능 · AI 검수 진행', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 18),
            Row(
              children: [
                IconButton.filled(onPressed: () {}, iconSize: 38, icon: const Icon(Icons.fiber_manual_record)),
                const SizedBox(width: 10),
                FilledButton(onPressed: onGallery, child: const Text('갤러리')),
                const SizedBox(width: 10),
                FilledButton(onPressed: onUpload, child: const Text('업로드')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key, required this.onVote});

  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        const Text('투표 일정', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const Text('TOP5 기준은 투표수만 반영합니다. 좋아요와 댓글은 바이럴 지표입니다.'),
        const SizedBox(height: 12),
        for (final c in challenges)
          Card(
            child: ListTile(
              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${c.handle} · ${c.votes}표'),
              trailing: FilledButton(onPressed: onVote, child: const Text('투표')),
            ),
          ),
      ],
    );
  }
}

class BetScreen extends StatelessWidget {
  const BetScreen({
    super.key,
    required this.picks,
    required this.editsLeft,
    required this.onPick,
    required this.onLock,
  });

  final Map<int, Challenge?> picks;
  final int editsLeft;
  final ValueChanged<int> onPick;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        const Text('승부 예측', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const Text('일요일 3PM부터 5:50PM까지. 1~3등을 모두 맞춰야 인정됩니다.'),
        const SizedBox(height: 14),
        for (final rank in [1, 2, 3])
          Card(
            child: ListTile(
              title: Text('$rank등'),
              subtitle: Text(picks[rank]?.title ?? '미선택'),
              onTap: () => onPick(rank),
            ),
          ),
        Text('수정 가능 $editsLeft회'),
        FilledButton(onPressed: onLock, child: const Text('예측 확정')),
      ],
    );
  }
}

class RankScreen extends StatelessWidget {
  const RankScreen({super.key, required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final rows = List<Challenge>.generate(50, (index) => challenges[index % challenges.length])
      ..sort((a, b) => b.score.compareTo(a.score));
    final visible = rows.take(expanded ? 50 : 10).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        const Text('실시간 랭킹', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const Text('참가자 랭킹만 노출합니다. 내부 반영표는 관리자만 확인합니다.'),
        const SizedBox(height: 12),
        for (var i = 0; i < visible.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(visible[i].title),
              trailing: Text('${visible[i].score}점'),
            ),
          ),
        OutlinedButton(onPressed: onToggle, child: Text(expanded ? '접기' : '더보기')),
        const Card(
          child: ListTile(
            title: Text('심사위원 당첨자 발표'),
            subtitle: Text('예측 성공자 중 랜덤 추첨 5명 · 일요일 6PM 이후 공개'),
          ),
        ),
      ],
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.current, required this.onTap});

  final MainTab current;
  final ValueChanged<MainTab> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (index) => onTap(MainTab.values[index]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Camera'),
        NavigationDestination(icon: Icon(Icons.how_to_vote_outlined), selectedIcon: Icon(Icons.how_to_vote), label: 'Vote'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Bet'),
        NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard), label: 'Rank'),
      ],
    );
  }
}

class WordBackground extends StatelessWidget {
  const WordBackground({super.key, required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: words.map((word) => Text(
        word,
        style: TextStyle(color: Colors.white.withOpacity(0.16), fontSize: 46, fontWeight: FontWeight.w900),
      )).toList(),
    );
  }
}

BoxDecoration darkGradient(double radius) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff07080c), Color(0xff181b23)],
    ),
    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 16))],
  );
}
