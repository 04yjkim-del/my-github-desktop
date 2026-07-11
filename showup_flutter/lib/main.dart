import 'package:flutter/material.dart';

import 'auth_screens.dart';
import 'bet_screen.dart';
import 'camera_screen.dart';
import 'extra_modals.dart';
import 'home_screen.dart';
import 'overlays.dart';
import 'profile_screen.dart';
import 'rank_screen.dart';
import 'settings_screen.dart';
import 'vote_screen.dart';

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

enum MainTab { home, camera, vote, bet, rank, profile }

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
  bool reelsVisible = false;
  int feedIndex = 0;
  MainTab tab = MainTab.home;

  void toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void enterApp(String label) {
    setState(() => authVisible = false);
    toast('$label 완료');
  }

  void openReels() {
    setState(() => reelsVisible = true);
  }

  void closeReels() {
    setState(() => reelsVisible = false);
  }

  void openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => NotificationsSheet(
        onClaimPrize: () => ExtraModals.openPrizeClaimFlow(context),
      ),
    );
  }

  void openComments(HomeChallenge challenge) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CommentsSheet(
        challenge: challenge,
        onCommentMenu: (author) => ExtraModals.showCommentMenu(context, author),
      ),
    );
  }

  void openShare(String preview) {
    ExtraModals.showShareSheet(context, preview: preview);
  }

  void openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(onAction: handleSettingsAction),
      ),
    );
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
                  onOpenReels: openReels,
                  onNextFeed: nextFeed,
                  onAction: handleHomeAction,
                ),
                CameraScreen(
                  onUpload: handleUpload,
                  onAction: handleCameraAction,
                ),
                VoteScreen(
                  candidates: challenges.map(toHomeChallenge).toList(),
                  ranking: rankedChallenges(),
                  onVote: (candidate) => toast('${candidate.title}에 투표했습니다'),
                  onAction: handleVoteAction,
                ),
                BetScreen(
                  candidates: challenges.map(toHomeChallenge).toList(),
                  onLock: (result) => toast(
                    '예측 확정: 1.${result[1]!.title} / 2.${result[2]!.title} / 3.${result[3]!.title}',
                  ),
                  onAction: handleBetAction,
                ),
                RankScreen(
                  entries: challenges.map(toHomeChallenge).toList(),
                  onAction: handleRankAction,
                ),
                ProfileScreen(
                  posts: challenges.map(toHomeChallenge).toList(),
                  onAction: handleProfileAction,
                  onOpenSettings: openSettings,
                ),
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
        if (reelsVisible)
          ReelsViewer(
            challenge: toHomeChallenge(challenges[feedIndex]),
            onClose: closeReels,
            onAction: handleReelsAction,
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
    final current = toHomeChallenge(challenges[feedIndex]);
    switch (action) {
      case 'like':
        toast('좋아요를 눌렀습니다');
      case 'unlike':
        toast('좋아요를 취소했습니다');
      case 'comment':
        openComments(current);
      case 'report':
        toast('신고가 접수되었습니다 (프로토타입)');
      case 'share':
        openShare('${current.title} · ${current.handle}');
      case 'notify':
        openNotifications();
      case 'search-empty':
        toast('검색어를 입력해 주세요');
      default:
        if (action.startsWith('search:')) {
          toast('프로필 검색: ${action.substring(7)}');
        }
    }
  }

  void handleReelsAction(String action) {
    final current = toHomeChallenge(challenges[feedIndex]);
    switch (action) {
      case 'comment':
        openComments(current);
      case 'like':
        toast('좋아요를 눌렀습니다');
      case 'report':
        toast('신고가 접수되었습니다 (프로토타입)');
      case 'share':
        openShare('${current.title} · ${current.handle}');
      default:
        break;
    }
  }

  void handleProfileAction(String action) {
    switch (action) {
      case 'notify':
        openNotifications();
      case 'interest':
        ExtraModals.openInterestList(context);
      case 'photo':
        ExtraModals.showProfilePhoto(context);
      case 'copy-url':
        toast('프로필 URL 복사됨');
      case 'share-profile':
        openShare('@showup_name · User profile');
      case 'qr':
        ExtraModals.openQrScreen(context);
      case 'post-menu':
        final title = action.contains(':') ? action.substring(action.indexOf(':') + 1) : 'Post';
        ExtraModals.showProfilePostMenu(context, title);
      default:
        if (action.startsWith('post:')) {
          openReels();
        } else if (action.startsWith('post-menu:')) {
          ExtraModals.showProfilePostMenu(context, action.substring(10));
        }
    }
  }

  void handleSettingsAction(String action) {
    switch (action) {
      case 'logout':
        setState(() {
          authVisible = true;
          introVisible = false;
          signupMode = false;
          tab = MainTab.home;
        });
        toast('로그아웃되었습니다');
      case 'withdraw':
        toast('탈퇴 요청은 서버 연결 후 처리됩니다');
      case 'terms':
        ExtraModals.showTerms(context);
      case 'prize-claim':
        ExtraModals.openPrizeClaimFlow(context);
      default:
        toast('${action.replaceAll('-', ' ')} (프로토타입)');
    }
  }

  void handleVoteAction(String action) {
    switch (action) {
      case 'notify':
        openNotifications();
      case 'vote-closed':
        toast('투표가 마감되었습니다');
      case 'vote-already':
        toast('이미 다른 후보에 투표했습니다. 같은 버튼을 다시 누르면 취소됩니다.');
      case 'vote-cancel':
        toast('투표를 취소했습니다');
      default:
        break;
    }
  }

  void handleBetAction(String action) {
    switch (action) {
      case 'bet-locked':
        toast('이미 확정된 예측은 수정할 수 없습니다');
      case 'bet-incomplete':
        toast('1~3등을 모두 선택해 주세요');
      default:
        break;
    }
  }

  void handleRankAction(String action) {
    switch (action) {
      case 'settings':
        openSettings();
      case 'winners':
        toast('예측 당첨자는 일요일 6PM 이후 발표됩니다');
      default:
        break;
    }
  }

  void handleCameraAction(String action) {
    switch (action) {
      case 'back':
        changeTab(MainTab.home);
      case 'record-start':
        toast('녹화 시작');
      case 'record-stop':
        toast('녹화 종료 · 미리보기 준비됨');
      case 'music':
        toast('음원을 선택했습니다');
      case 'flip':
        toast('카메라를 전환했습니다');
      case 'flip-blocked':
        toast('녹화 중에는 카메라를 전환할 수 없습니다');
      case 'gallery':
        toast('갤러리에서 영상을 불러왔습니다 (프로토타입)');
      case 'gallery-blocked':
        toast('녹화 중에는 갤러리를 열 수 없습니다');
      case 'save':
        toast('임시 저장했습니다');
      case 'save-empty':
        toast('먼저 촬영하거나 갤러리에서 영상을 선택하세요');
      case 'share':
        toast('공유 링크를 준비했습니다 (프로토타입)');
      case 'share-empty':
        toast('공유할 영상이 없습니다');
      case 'drop-empty':
        toast('DROP 할 영상이 없습니다');
      case 'drop-blocked':
        toast('녹화를 먼저 종료해 주세요');
      default:
        break;
    }
  }

  void handleUpload() {
    ExtraModals.showAdBreak(
      context,
      onComplete: () => toast('AI 검수 중'),
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
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Feed'),
        NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'DROP'),
        NavigationDestination(icon: Icon(Icons.how_to_vote_outlined), selectedIcon: Icon(Icons.how_to_vote), label: 'Vote'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Predict'),
        NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard), label: 'Ranking'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
