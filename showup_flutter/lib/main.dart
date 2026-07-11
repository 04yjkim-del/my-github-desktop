import 'package:flutter/material.dart';

import 'api/api_exception.dart';
import 'api/models.dart';
import 'api/showup_api.dart';
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
  final ShowUpApi api = ShowUpApi();

  bool authVisible = true;
  bool introVisible = true;
  bool signupMode = false;
  bool cameraNoticeSeen = false;
  bool reelsVisible = false;
  bool booting = true;
  int feedIndex = 0;
  MainTab tab = MainTab.home;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await api.init();
    if (!mounted) return;
    setState(() {
      booting = false;
      authVisible = api.currentUser == null;
      introVisible = authVisible;
    });
    _showApiModeToast();
  }

  List<HomeChallenge> get _feed => api.feed;
  List<HomeChallenge> get _ranking => api.ranking;
  List<HomeChallenge> get _candidates => api.candidates;

  HomeChallenge get _currentFeedItem {
    if (_feed.isEmpty) return const HomeChallenge(title: 'No feed', handle: '@showup', views: 0, likes: 0, votes: 0);
    return _feed[feedIndex % _feed.length];
  }

  String? get _votedCandidateTitle {
    final votedId = api.votedCandidateId;
    if (votedId == null) return null;
    for (final item in _candidates) {
      if (item.id == votedId || item.title == votedId) return item.title;
    }
    return votedId;
  }

  Map<int, HomeChallenge>? get _predictionPicks {
    final prediction = api.prediction;
    if (prediction.first == null && prediction.second == null && prediction.third == null) {
      return null;
    }
    return {
      if (prediction.first != null) 1: prediction.first!,
      if (prediction.second != null) 2: prediction.second!,
      if (prediction.third != null) 3: prediction.third!,
    };
  }

  void toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showApiModeToast() {
    if (api.usingMock) {
      toast(api.lastInfoMessage ?? '서버 없음 · 샘플 데이터로 표시합니다');
    }
  }

  Future<void> _refreshUi() async {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> handleLogin(String loginId, String password) async {
    await api.login(loginId, password);
    if (!mounted) return;
    setState(() => authVisible = false);
    toast('로그인 완료');
    _showApiModeToast();
  }

  Future<void> handleSignup(SignupPayload payload) async {
    await api.signup(payload);
    if (!mounted) return;
    setState(() => authVisible = false);
    toast('회원가입 완료');
    _showApiModeToast();
  }

  Future<String> handleSendPhoneCode(String phone) {
    return api.sendSignupPhoneCode(phone);
  }

  Future<String> handleVerifyPhone(String phone, String code) {
    return api.verifySignupPhone(phone, code);
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
    if (booting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: tab.index,
              children: [
                HomeScreen(
                  challenge: _currentFeedItem,
                  ranking: _ranking,
                  onOpenReels: openReels,
                  onNextFeed: nextFeed,
                  onAction: handleHomeAction,
                ),
                CameraScreen(
                  onUpload: handleUpload,
                  onAction: handleCameraAction,
                ),
                VoteScreen(
                  candidates: _candidates,
                  ranking: _ranking,
                  externalPhase: api.votePhase,
                  votedCandidateTitle: _votedCandidateTitle,
                  onVote: handleVote,
                  onAction: handleVoteAction,
                ),
                BetScreen(
                  candidates: _candidates,
                  externalLocked: api.prediction.locked,
                  externalPicks: _predictionPicks,
                  onLock: handleBetLock,
                  onAction: handleBetAction,
                ),
                RankScreen(
                  entries: _ranking,
                  onAction: handleRankAction,
                ),
                ProfileScreen(
                  posts: _feed,
                  onAction: handleProfileAction,
                  onOpenSettings: openSettings,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNav(current: tab, onTap: changeTab),
        ),
        if (authVisible)
          AuthGate(
            introVisible: introVisible,
            signupMode: signupMode,
            onStart: () => setState(() => introVisible = false),
            onToggle: (value) => setState(() => signupMode = value),
            onLogin: handleLogin,
            onSignup: handleSignup,
            onSendPhoneCode: handleSendPhoneCode,
            onVerifyPhone: handleVerifyPhone,
            onForgot: openForgotDialog,
          ),
        if (reelsVisible)
          ReelsViewer(
            challenge: _currentFeedItem,
            onClose: closeReels,
            onAction: handleReelsAction,
          ),
      ],
    );
  }

  void nextFeed() {
    if (_feed.isEmpty) return;
    setState(() => feedIndex = (feedIndex + 1) % _feed.length);
  }

  Future<void> handleVote(HomeChallenge candidate) async {
    try {
      if (api.votedCandidateId == (candidate.id ?? candidate.title)) {
        await api.cancelVote();
        toast('투표를 취소했습니다');
      } else {
        await api.castVote(candidate);
        toast('${candidate.title}에 투표했습니다');
      }
      await _refreshUi();
    } on ApiException catch (err) {
      toast(err.message);
    }
  }

  Future<void> handleBetLock(Map<int, HomeChallenge> result) async {
    final first = result[1];
    final second = result[2];
    final third = result[3];
    if (first == null || second == null || third == null) {
      toast('1~3등을 모두 선택해 주세요');
      return;
    }
    try {
      await api.submitPrediction(first: first, second: second, third: third);
      toast('예측 확정: 1.${first.title} / 2.${second.title} / 3.${third.title}');
      await _refreshUi();
    } on ApiException catch (err) {
      toast(err.message);
    }
  }

  void handleHomeAction(String action) {
    final current = _currentFeedItem;
    switch (action) {
      case 'like':
        _toggleLike(current, true);
      case 'unlike':
        _toggleLike(current, false);
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
          _runSearch(action.substring(7));
        }
    }
  }

  Future<void> _toggleLike(HomeChallenge item, bool liked) async {
    final videoId = item.id;
    if (videoId == null) {
      toast(liked ? '좋아요를 눌렀습니다' : '좋아요를 취소했습니다');
      return;
    }
    try {
      await api.toggleLike(videoId, liked);
      toast(liked ? '좋아요를 눌렀습니다' : '좋아요를 취소했습니다');
    } on ApiException catch (err) {
      toast(err.message);
    }
  }

  Future<void> _runSearch(String query) async {
    try {
      final results = await api.searchProfiles(query);
      toast(results.isEmpty ? '검색 결과가 없습니다' : '검색 결과 ${results.length}건');
    } on ApiException catch (err) {
      toast(err.message);
    }
  }

  void handleReelsAction(String action) {
    final current = _currentFeedItem;
    switch (action) {
      case 'comment':
        openComments(current);
      case 'like':
        _toggleLike(current, true);
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

  Future<void> handleSettingsAction(String action) async {
    switch (action) {
      case 'logout':
        await api.logout();
        if (!mounted) return;
        setState(() {
          authVisible = true;
          introVisible = false;
          signupMode = false;
          tab = MainTab.home;
        });
        toast('로그아웃되었습니다');
        _showApiModeToast();
      case 'withdraw':
        try {
          await api.withdraw();
          if (!mounted) return;
          setState(() {
            authVisible = true;
            introVisible = false;
            tab = MainTab.home;
          });
          toast('탈퇴 요청이 접수되었습니다');
        } on ApiException catch (err) {
          toast(err.message);
        }
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
        _cancelVoteFromApi();
      default:
        break;
    }
  }

  Future<void> _cancelVoteFromApi() async {
    try {
      await api.cancelVote();
      await _refreshUi();
      toast('투표를 취소했습니다');
    } on ApiException catch (err) {
      toast(err.message);
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
        openShare('DROP clip · show up');
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
      onComplete: () => toast('AI 검수 중 (업로드 API는 다음 단계)'),
    );
  }

  void openForgotDialog() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff12151c),
        title: const Text('Forgot password?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '이름과 전화번호(또는 이메일)로 본인 확인 후 비밀번호를 재설정합니다.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: contactController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
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
            onPressed: () async {
              try {
                await api.forgotPassword(
                  name: nameController.text.trim(),
                  contact: contactController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
                openResetPasswordDialog();
              } catch (err) {
                toast(err.toString().replaceFirst('ApiException: ', ''));
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void openResetPasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff12151c),
        title: const Text('New password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
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
            onPressed: () async {
              if (passwordController.text != confirmController.text) {
                toast('비밀번호가 서로 다릅니다');
                return;
              }
              try {
                await api.resetPassword(
                  token: 'forgot-flow',
                  password: passwordController.text,
                );
                if (context.mounted) Navigator.pop(context);
                toast('비밀번호가 변경되었습니다');
              } catch (err) {
                toast(err.toString().replaceFirst('ApiException: ', ''));
              }
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
