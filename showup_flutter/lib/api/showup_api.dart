import '../home_screen.dart';
import '../vote_screen.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_session.dart';
import 'mock_data.dart';
import 'models.dart';

/// show up 사용자 API 묶음.
/// 서버가 없으면 mock 데이터로 자동 폴백합니다 (웹 script.js 와 동일한 방식).
class ShowUpApi {
  ShowUpApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  bool usingMock = false;
  String? lastInfoMessage;
  UserProfile? currentUser;

  List<HomeChallenge> feed = List<HomeChallenge>.from(MockData.feed);
  List<HomeChallenge> ranking = List<HomeChallenge>.from(MockData.ranked());
  List<HomeChallenge> candidates = List<HomeChallenge>.from(MockData.feed);
  VotePhase votePhase = VotePhase.general;
  String? votedCandidateId;
  PredictionSnapshot prediction = const PredictionSnapshot(locked: false);

  Future<void> init() async {
    await AuthSession.load();
    if (!AuthSession.isLoggedIn) {
      usingMock = true;
      _useMockLists();
      return;
    }

    try {
      final me = await _client.get('/api/users/me');
      currentUser = UserProfile.fromJson(me);
      usingMock = false;
      await refreshAppData();
    } on ApiException catch (err) {
      usingMock = true;
      lastInfoMessage = err.message;
      if (err.status == 401) await AuthSession.clear();
      _useMockLists();
    }
  }

  Future<void> refreshAppData() async {
    await Future.wait([
      _loadFeed(),
      _loadRanking(),
      _loadChallengeBundle(),
    ]);
  }

  Future<void> login(String loginId, String password) async {
    final data = await _client.post(
      '/api/auth/login',
      auth: false,
      body: {
        'loginId': loginId,
        'password': password,
      },
    );
    final token = readNullableString(data['token']) ??
        readNullableString(data['accessToken']) ??
        readNullableString(data['jwt']);
    if (token == null) {
      throw ApiException('로그인 응답에 토큰이 없습니다.');
    }
    await AuthSession.save(token);
    usingMock = false;
    lastInfoMessage = null;
    if (data['user'] is Map) {
      currentUser = UserProfile.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    } else {
      final me = await _client.get('/api/users/me');
      currentUser = UserProfile.fromJson(me);
    }
    await refreshAppData();
  }

  Future<void> logout() async {
    try {
      if (AuthSession.isLoggedIn) {
        await _client.post('/api/auth/logout');
      }
    } catch (_) {
      // 서버가 꺼져 있어도 로컬 세션은 지웁니다.
    }
    await AuthSession.clear();
    currentUser = null;
    usingMock = true;
    _useMockLists();
  }

  Future<String> sendSignupPhoneCode(String phone) async {
    final data = await _client.post(
      '/api/auth/phone/send-signup',
      auth: false,
      body: {'phone': phone},
    );
    return readString(data['message'], '인증번호가 발송되었습니다.');
  }

  Future<String> verifySignupPhone(String phone, String code) async {
    final data = await _client.post(
      '/api/auth/phone/verify-signup',
      auth: false,
      body: {'phone': phone, 'code': code},
    );
    final proof = readNullableString(data['signupPhoneProof']) ??
        readNullableString(data['proof']) ??
        readNullableString(data['token']);
    if (proof == null) {
      throw ApiException('휴대폰 인증 proof 를 받지 못했습니다.');
    }
    return proof;
  }

  Future<void> signup(SignupPayload payload) async {
    final data = await _client.post(
      '/api/auth/signup',
      auth: false,
      body: payload.toJson(),
    );
    final token = readNullableString(data['token']) ??
        readNullableString(data['accessToken']);
    if (token != null) {
      await AuthSession.save(token);
      usingMock = false;
      if (data['user'] is Map) {
        currentUser = UserProfile.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      }
      await refreshAppData();
      return;
    }
    await login(payload.loginId, payload.password);
  }

  Future<void> forgotPassword({
    required String name,
    required String contact,
  }) async {
    await _client.post(
      '/api/auth/password/forgot',
      auth: false,
      body: {'name': name, 'contact': contact},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _client.post(
      '/api/auth/password/reset',
      auth: false,
      body: {'token': token, 'password': password},
    );
  }

  Future<void> castVote(HomeChallenge candidate) async {
    final candidateId = candidate.id ?? candidate.title;
    await _runOrMock(
      () => _client.post(
        '/api/challenges/current/votes',
        body: {'candidateId': candidateId},
      ),
      onMock: () {
        votedCandidateId = candidateId;
      },
    );
    votedCandidateId = candidateId;
  }

  Future<void> cancelVote() async {
    await _runOrMock(
      () => _client.delete('/api/challenges/current/votes'),
      onMock: () => votedCandidateId = null,
    );
    votedCandidateId = null;
  }

  Future<void> submitPrediction({
    required HomeChallenge first,
    required HomeChallenge second,
    required HomeChallenge third,
  }) async {
    await _runOrMock(
      () => _client.post(
        '/api/challenges/current/prediction',
        body: {
          'firstPlaceId': first.id ?? first.title,
          'secondPlaceId': second.id ?? second.title,
          'thirdPlaceId': third.id ?? third.title,
        },
      ),
      onMock: () {
        prediction = PredictionSnapshot(
          locked: true,
          first: first,
          second: second,
          third: third,
        );
      },
    );
    prediction = PredictionSnapshot(
      locked: true,
      first: first,
      second: second,
      third: third,
    );
  }

  Future<void> toggleLike(String videoId, bool liked) async {
    await _runOrMock(() async {
      if (liked) {
        await _client.post('/api/videos/$videoId/like');
      } else {
        await _client.delete('/api/videos/$videoId/like');
      }
    });
  }

  Future<List<HomeChallenge>> searchProfiles(String query) async {
    if (usingMock) {
      final q = query.toLowerCase();
      return feed
          .where(
            (item) =>
                item.title.toLowerCase().contains(q) ||
                item.handle.toLowerCase().contains(q),
          )
          .toList();
    }
    final data = await _client.get(
      '/api/search',
      query: {'q': query, 'type': 'user'},
    );
    return homeChallengesFromList(data['users'] ?? data['items'] ?? data['results']);
  }

  Future<void> withdraw() async {
    await _client.post('/api/users/me/withdraw');
    await logout();
  }

  Future<void> _loadFeed() async {
    await _runOrMock(
      () async {
        final data = await _client.get('/api/home-feed');
        final items = homeChallengesFromList(data['items'] ?? data['videos'] ?? data['feed']);
        if (items.isNotEmpty) feed = items;
      },
      onMock: () => feed = List<HomeChallenge>.from(MockData.feed),
    );
  }

  Future<void> _loadRanking() async {
    await _runOrMock(
      () async {
        final data = await _client.get('/api/ranking');
        final items = homeChallengesFromList(data['items'] ?? data['ranking'] ?? data['entries']);
        if (items.isNotEmpty) ranking = items;
      },
      onMock: () => ranking = List<HomeChallenge>.from(MockData.ranked()),
    );
  }

  Future<void> _loadChallengeBundle() async {
    await _runOrMock(
      () async {
        final challenge = await _client.get('/api/challenges/current');
        votePhase = votePhaseFromApi(readNullableString(challenge['phase']));

        final candidateData = await _client.get('/api/challenges/current/candidates');
        final items = homeChallengesFromList(
          candidateData['items'] ?? candidateData['candidates'] ?? candidateData['users'],
        );
        if (items.isNotEmpty) candidates = items;

        votedCandidateId = readNullableString(
          candidateData['myVote']?['candidateId'] ?? challenge['myVote']?['candidateId'],
        );

        final predictionData = await _client.get('/api/challenges/current/prediction');
        final locked = predictionData['locked'] == true ||
            readNullableString(predictionData['status']) == 'locked';
        prediction = PredictionSnapshot(
          locked: locked,
          first: _pickFromPrediction(predictionData['first'] ?? predictionData['firstPlace']),
          second: _pickFromPrediction(predictionData['second'] ?? predictionData['secondPlace']),
          third: _pickFromPrediction(predictionData['third'] ?? predictionData['thirdPlace']),
        );
      },
      onMock: () {
        votePhase = VotePhase.general;
        candidates = List<HomeChallenge>.from(MockData.feed);
        votedCandidateId = null;
        prediction = const PredictionSnapshot(locked: false);
      },
    );
  }

  HomeChallenge? _pickFromPrediction(dynamic raw) {
    if (raw is Map) {
      return homeChallengeFromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is String) {
      return candidates.cast<HomeChallenge?>().firstWhere(
            (item) => item?.id == raw || item?.title == raw,
            orElse: () => null,
          );
    }
    return null;
  }

  Future<void> _runOrMock(
    Future<void> Function() action, {
    void Function()? onMock,
  }) async {
    if (usingMock) {
      onMock?.call();
      return;
    }
    try {
      await action();
      usingMock = false;
    } on ApiException catch (err) {
      if (err.isNetwork) {
        usingMock = true;
        lastInfoMessage = '서버 연결 실패 · 샘플 데이터로 표시합니다';
        onMock?.call();
        return;
      }
      rethrow;
    }
  }

  void _useMockLists() {
    feed = List<HomeChallenge>.from(MockData.feed);
    ranking = List<HomeChallenge>.from(MockData.ranked());
    candidates = List<HomeChallenge>.from(MockData.feed);
    votePhase = VotePhase.general;
    votedCandidateId = null;
    prediction = const PredictionSnapshot(locked: false);
  }
}
