import '../home_screen.dart';
import '../vote_screen.dart';

int readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String readString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? readNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

HomeChallenge homeChallengeFromJson(Map<String, dynamic> json) {
  final handle = readNullableString(json['handle']) ??
      readNullableString(json['username']) ??
      readNullableString(json['loginId']) ??
      readNullableString(json['user']?['username']) ??
      '@user';

  final normalizedHandle = handle.startsWith('@') ? handle : '@$handle';

  return HomeChallenge(
    id: readNullableString(json['id']) ??
        readNullableString(json['videoId']) ??
        readNullableString(json['userId']) ??
        readNullableString(json['candidateId']),
    title: readString(
      json['title'] ?? json['videoTitle'] ?? json['challengeTitle'] ?? 'Untitled',
    ),
    handle: normalizedHandle,
    views: readInt(json['views'] ?? json['viewCount']),
    likes: readInt(json['likes'] ?? json['likeCount']),
    votes: readInt(json['votes'] ?? json['voteCount']),
  );
}

List<HomeChallenge> homeChallengesFromList(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((item) => homeChallengeFromJson(Map<String, dynamic>.from(item)))
      .toList();
}

VotePhase votePhaseFromApi(String? phase) {
  switch (phase) {
    case 'general_open':
      return VotePhase.general;
    case 'top10_open':
      return VotePhase.top10;
    case 'final_open':
      return VotePhase.finalRound;
    case 'general_closed':
    case 'top10_closed':
    case 'final_closed':
    case 'top10_confirmed':
    case 'top3_confirmed':
    case 'winners_confirmed':
    case 'idle':
      return VotePhase.closed;
    default:
      return VotePhase.general;
  }
}

class SignupPayload {
  const SignupPayload({
    required this.name,
    required this.birthDate,
    required this.email,
    required this.username,
    required this.loginId,
    required this.password,
    required this.phone,
    required this.signupPhoneProof,
    required this.termsService,
    required this.termsPrivacy,
    required this.termsMarketing,
  });

  final String name;
  final String birthDate;
  final String email;
  final String username;
  final String loginId;
  final String password;
  final String phone;
  final String signupPhoneProof;
  final bool termsService;
  final bool termsPrivacy;
  final bool termsMarketing;

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthDate': birthDate,
        'email': email,
        'username': username,
        'loginId': loginId,
        'password': password,
        'phone': phone,
        'signupPhoneProof': signupPhoneProof,
        'terms': {
          'service': termsService,
          'privacy': termsPrivacy,
          'marketing': termsMarketing,
        },
      };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.loginId,
    this.displayName,
  });

  final String id;
  final String username;
  final String loginId;
  final String? displayName;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: readString(json['id'] ?? json['userId']),
      username: readString(json['username'] ?? json['handle']),
      loginId: readString(json['loginId'] ?? json['login_id']),
      displayName: readNullableString(json['name'] ?? json['displayName']),
    );
  }
}

class PredictionSnapshot {
  const PredictionSnapshot({
    required this.locked,
    this.first,
    this.second,
    this.third,
  });

  final bool locked;
  final HomeChallenge? first;
  final HomeChallenge? second;
  final HomeChallenge? third;
}
