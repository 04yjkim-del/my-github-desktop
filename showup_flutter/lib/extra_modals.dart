import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _lime = Color(0xffd7ff38);
const _muted = Color(0xff6b7280);

/// 웹 index.html 에 남아 있던 모달/보조 화면들.
class ExtraModals {
  static Future<void> showShareSheet(BuildContext context, {required String preview}) {
    const options = [
      ('Copy link', Icons.link_rounded),
      ('Messages', Icons.message_outlined),
      ('Instagram', Icons.camera_alt_outlined),
      ('More apps', Icons.ios_share_rounded),
    ];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(preview, style: const TextStyle(color: _muted)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final option in options)
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${option.$1} (prototype)')),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xfff3f4f6),
                              child: Icon(option.$2),
                            ),
                            const SizedBox(height: 6),
                            Text(option.$1, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showTerms(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Show Up Terms of Service\n\n'
            '1. Users aged 13 or older may create an account.\n'
            '2. Uploaded videos must follow community guidelines.\n'
            '3. Prize claims require identity verification.\n'
            '4. Users under 18 may need guardian consent for prizes.\n\n'
            'Privacy Policy\n\n'
            'We collect account, device, and usage data to operate weekly challenges, voting, and payouts.',
            style: TextStyle(height: 1.45),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  static Future<void> showProfilePhoto(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Profile photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 72,
                backgroundColor: _lime.withOpacity(0.25),
                child: const Text('SU', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change photo (prototype)')),
                  );
                },
                child: const Text('Change photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showAdBreak(BuildContext context, {VoidCallback? onComplete}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('AD'),
        content: const Text('Sponsored break\n\nContinue after the ad.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              onComplete?.call();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static Future<void> showProfilePostMenu(BuildContext context, String title) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit post (prototype)')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted (prototype)')));
                },
              ),
              ListTile(
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showCommentMenu(BuildContext context, String author) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Comment options · $author', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report comment'),
                onTap: () {
                  Navigator.pop(context);
                  showCommentReport(context, author);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Block user'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blocked $author (prototype)')));
                },
              ),
              ListTile(title: const Text('Cancel'), onTap: () => Navigator.pop(context)),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showCommentReport(BuildContext context, String author) {
    const reasons = [
      '욕설·비방',
      '스팸·광고',
      '혐오·차별',
      '개인정보 노출',
      '챌린지·영상과 무관',
      '기타',
    ];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Comment Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(author, style: const TextStyle(color: _muted)),
                const SizedBox(height: 12),
                for (final reason in reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Report submitted: $reason')),
                          );
                        },
                        child: Text(reason),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Report해도 Comment은 그대로 보입니다. 해당 사용자의 Comment을 없애려면 메뉴에서 차단하세요.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void openInterestList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const InterestListScreen()),
    );
  }

  static void openQrScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const QrProfileScreen()),
    );
  }

  static void openGuardianVerify(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const GuardianVerifyScreen()),
    );
  }

  static void openPrizeClaimFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const PrizeClaimFlowScreen()),
    );
  }
}

class InterestListScreen extends StatefulWidget {
  const InterestListScreen({super.key});

  @override
  State<InterestListScreen> createState() => _InterestListScreenState();
}

class _InterestListScreenState extends State<InterestListScreen> {
  final _search = TextEditingController();
  static const _users = [
    '@dance.signal',
    '@daily.fit',
    '@move.ground',
    '@sync.room',
    '@quick.laugh',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty ? _users : _users.where((u) => u.contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Interest', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Interest 추가한 참가자입니다', style: TextStyle(color: _muted)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Interest 목록이 비어 있습니다', style: TextStyle(color: _muted))),
            )
          else
            for (final user in filtered)
              ListTile(
                leading: CircleAvatar(child: Text(user[1].toUpperCase())),
                title: Text(user, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: const Icon(Icons.favorite, color: _lime),
              ),
        ],
      ),
    );
  }
}

class QrProfileScreen extends StatelessWidget {
  const QrProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101218),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('SHOW UP', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 64,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemBuilder: (context, index) {
                    final dark = (index + index ~/ 8) % 3 == 0;
                    return ColoredBox(color: dark ? Colors.black : Colors.white);
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('@Y_JXXKK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class GuardianVerifyScreen extends StatefulWidget {
  const GuardianVerifyScreen({super.key});

  @override
  State<GuardianVerifyScreen> createState() => _GuardianVerifyScreenState();
}

class _GuardianVerifyScreenState extends State<GuardianVerifyScreen> {
  bool verified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('보호자 본인 인증', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              '만 14~16세 참가자의 보호자가 본인 휴대폰으로 PASS 인증을 완료합니다.',
              style: TextStyle(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (verified)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xfff7ffe0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _lime),
                ),
                child: const Text('보호자 인증이 완료되었습니다.', style: TextStyle(fontWeight: FontWeight.w800)),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
                onPressed: () => setState(() => verified = true),
                child: const Text('Complete guardian PASS (demo)'),
              ),
          ],
        ),
      ),
    );
  }
}

class PrizeClaimFlowScreen extends StatefulWidget {
  const PrizeClaimFlowScreen({super.key});

  @override
  State<PrizeClaimFlowScreen> createState() => _PrizeClaimFlowScreenState();
}

class _PrizeClaimFlowScreenState extends State<PrizeClaimFlowScreen> {
  int step = 0;
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _name = TextEditingController();
  final _claimBirth = TextEditingController();
  final _contact = TextEditingController();
  final _routing = TextEditingController();
  final _account = TextEditingController();
  final _holder = TextEditingController();
  bool phoneVerified = false;
  bool guardianRequested = false;

  @override
  void dispose() {
    _phone.dispose();
    _birth.dispose();
    _guardianPhone.dispose();
    _name.dispose();
    _claimBirth.dispose();
    _contact.dispose();
    _routing.dispose();
    _account.dispose();
    _holder.dispose();
    super.dispose();
  }

  void next() => setState(() => step += 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForStep(step), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StepDots(step: step, total: 4),
          const SizedBox(height: 20),
          if (step == 0) ...[
            const Text('Phone verification required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Phone verification is required for prize claims and payouts.', style: TextStyle(color: _muted)),
            const SizedBox(height: 16),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: '+1 555-010-0000')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() => phoneVerified = true),
              child: Text(phoneVerified ? 'Phone verified' : 'Verify phone'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Later'))),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
                    onPressed: phoneVerified ? next : null,
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
          if (step == 1) ...[
            const Text('Confirm date of birth', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(
              controller: _birth,
              decoration: const InputDecoration(labelText: 'Date of birth', hintText: 'MM/DD/YYYY'),
              inputFormatters: [_BirthDateFormatter()],
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
              onPressed: _birth.text.length >= 8 ? next : null,
              child: const Text('Next'),
            ),
          ],
          if (step == 2) ...[
            const Text('Guardian consent', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Users under 18 need a parent or guardian to verify. We send a consent link to the guardian\'s phone.',
              style: TextStyle(color: _muted, height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(controller: _guardianPhone, decoration: const InputDecoration(labelText: 'Guardian phone number')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ExtraModals.openGuardianVerify(context),
              child: const Text('Open guardian link (demo)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => setState(() => guardianRequested = true),
              child: Text(guardianRequested ? 'Consent requested' : 'Request guardian consent'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
              onPressed: guardianRequested ? next : null,
              child: const Text('Continue prize claim'),
            ),
          ],
          if (step == 3) ...[
            const Text('Submit prize claim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Prizes are paid after identity checks and fraud review. ACH transfer within 7 days of announcement.',
              style: TextStyle(color: _muted, height: 1.35),
            ),
            const SizedBox(height: 16),
            _claimField('Name', _name, 'John Doe'),
            _claimField('Date of birth', _claimBirth, 'MM/DD/YYYY'),
            _claimField('Contact', _contact, '+1 555-010-0000'),
            _claimField('Routing number (ABA)', _routing, '021000021'),
            _claimField('Checking account', _account, '1234567890'),
            _claimField('Account holder', _holder, 'John Doe'),
            const SizedBox(height: 12),
            const Text(
              'Account holder must exactly match Name. Personal checking only.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prize claim submitted (prototype)')),
                );
              },
              child: const Text('Submit claim'),
            ),
          ],
        ],
      ),
    );
  }

  String _titleForStep(int value) => switch (value) {
        0 => 'Prize claim',
        1 => 'Birth confirmation',
        2 => 'Guardian consent',
        _ => 'Payout info',
      };

  Widget _claimField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final active = index <= step;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? _lime : const Color(0xffe5e7eb),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _BirthDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(capped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
