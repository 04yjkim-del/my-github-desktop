import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _lime = Color(0xffd7ff38);
const _bg = Color(0xff050608);
const _card = Color(0xff12151c);
const _field = Color(0xff1a1e27);
const _muted = Color(0xff9aa3b2);

/// 웹 index.html 의 인트로 + 로그인/회원가입을 Flutter로 옮긴 화면.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.introVisible,
    required this.signupMode,
    required this.onStart,
    required this.onToggle,
    required this.onLogin,
    required this.onSignup,
    required this.onForgot,
  });

  final bool introVisible;
  final bool signupMode;
  final VoidCallback onStart;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SafeArea(
        child: introVisible
            ? IntroPanel(onStart: onStart)
            : AuthPanel(
                signupMode: signupMode,
                onToggle: onToggle,
                onLogin: onLogin,
                onSignup: onSignup,
                onForgot: onForgot,
              ),
      ),
    );
  }
}

class IntroPanel extends StatefulWidget {
  const IntroPanel({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<IntroPanel> createState() => _IntroPanelState();
}

class _IntroPanelState extends State<IntroPanel> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _IntroSlide(
      number: '01',
      eyebrow: 'NOW',
      title: "What's trending\nright now",
      hitWord: 'right now',
      copy: 'Reels, challenges, and memes in one place. Scroll to catch the vibe before it\'s over.',
      tags: ['#HotNow', '#ScrollWorthy'],
    ),
    _IntroSlide(
      number: '02',
      eyebrow: 'BATTLE',
      title: 'Online battles / new stage every week',
      hitWord: 'Online battles',
      copy: 'Post on trend, rack up votes, win TOP prizes. Themes change every weekend.',
      tags: ['#TOP3', '#Prizes'],
    ),
    _IntroSlide(
      number: '03',
      eyebrow: 'WATCH',
      title: null,
      hitWord: 'Watch and win prizes.',
      copy: null,
      lines: [
        'Predict and win merch.',
        'Like and comment like Instagram.',
        'Watch and win prizes.',
      ],
      tags: const [],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY DROP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hot picks · Vote · Prizes',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _lime.withOpacity(0.5)),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: _lime,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => _IntroSlideCard(slide: _slides[index]),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? _lime : Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        const Text(
          '››  SWIPE',
          style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ready to join us?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: widget.onStart,
              child: const Text('Get started'),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.number,
    required this.eyebrow,
    required this.title,
    required this.hitWord,
    required this.copy,
    required this.tags,
    this.lines,
  });

  final String number;
  final String eyebrow;
  final String? title;
  final String hitWord;
  final String? copy;
  final List<String> tags;
  final List<String>? lines;
}

class _IntroSlideCard extends StatelessWidget {
  const _IntroSlideCard({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff0c0f16), Color(0xff1a2030)],
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slide.number,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              slide.eyebrow,
              style: const TextStyle(
                color: _lime,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            if (slide.lines != null)
              ...slide.lines!.map((line) {
                final isHit = line == slide.hitWord;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    line,
                    style: TextStyle(
                      color: isHit ? _lime : Colors.white,
                      fontSize: isHit ? 28 : 22,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                );
              })
            else
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                  children: _titleSpans(slide.title!, slide.hitWord),
                ),
              ),
            if (slide.copy != null) ...[
              const SizedBox(height: 14),
              Text(
                slide.copy!,
                style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
              ),
            ],
            const Spacer(),
            if (slide.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: slide.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _titleSpans(String title, String hit) {
    final index = title.indexOf(hit);
    if (index < 0) return [TextSpan(text: title)];
    return [
      TextSpan(text: title.substring(0, index)),
      TextSpan(text: hit, style: const TextStyle(color: _lime)),
      TextSpan(text: title.substring(index + hit.length)),
    ];
  }
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({
    super.key,
    required this.signupMode,
    required this.onToggle,
    required this.onLogin,
    required this.onSignup,
    required this.onForgot,
  });

  final bool signupMode;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: Text('su', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 10),
              const Text(
                'show up',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => onToggle(false),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: signupMode ? _muted : _lime,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => onToggle(true),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    color: signupMode ? _lime : _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
              ),
              child: signupMode
                  ? SignupForm(onSubmit: onSignup)
                  : LoginForm(onLogin: onLogin, onForgot: onForgot),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onLogin, required this.onForgot});

  final VoidCallback onLogin;
  final VoidCallback onForgot;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final id = _idController.text.trim();
    final password = _passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 입력해 주세요.');
      return;
    }
    setState(() => _error = null);
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Login',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        AuthField(
          label: 'ID',
          hint: 'Phone number or ID',
          controller: _idController,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AuthField(
          label: 'Password',
          hint: 'Password',
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Color(0xffff6b6b), fontSize: 13)),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _submit,
            child: const Text('Login'),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.onForgot,
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key, required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _name = TextEditingController();
  final _birth = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  bool _termsService = false;
  bool _termsPrivacy = false;
  bool _termsMarketing = false;
  bool _codeSent = false;
  bool _phoneVerified = false;
  String? _hint;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _birth.dispose();
    _email.dispose();
    _username.dispose();
    _loginId.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _canCreate {
    return _name.text.trim().isNotEmpty &&
        _birth.text.trim().length >= 8 &&
        _email.text.contains('@') &&
        _username.text.trim().isNotEmpty &&
        _loginId.text.trim().length >= 6 &&
        _password.text.length >= 8 &&
        _password.text == _passwordConfirm.text &&
        _phoneVerified &&
        _termsService &&
        _termsPrivacy;
  }

  void _sendCode() {
    final phone = _phone.text.trim();
    if (phone.length < 8) {
      setState(() => _error = '휴대폰 번호를 확인해 주세요.');
      return;
    }
    setState(() {
      _error = null;
      _codeSent = true;
      _phoneVerified = false;
      _hint = '인증번호가 발송되었습니다. (프로토타입: 아무 6자리 입력)';
    });
  }

  void _confirmCode() {
    if (_code.text.trim().length != 6) {
      setState(() => _error = '인증번호 6자리를 입력해 주세요.');
      return;
    }
    setState(() {
      _error = null;
      _phoneVerified = true;
      _hint = '휴대폰 인증이 완료되었습니다.';
    });
  }

  void _submit() {
    if (_password.text != _passwordConfirm.text) {
      setState(() => _error = '비밀번호가 서로 다릅니다.');
      return;
    }
    if (!_canCreate) {
      setState(() => _error = '필수 항목·휴대폰 인증·약관 동의를 완료해 주세요.');
      return;
    }
    setState(() => _error = null);
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign up',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Only users aged 13 or older can sign up.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        AuthField(label: 'Name', hint: 'John Doe', controller: _name, onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        AuthField(
          label: 'Date of birth',
          hint: 'MM/DD/YYYY',
          controller: _birth,
          keyboardType: TextInputType.number,
          inputFormatters: [_BirthDateFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        AuthField(
          label: 'Email',
          hint: 'name@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        AuthField(label: 'Username', hint: 'showup_name', controller: _username, onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        AuthField(label: 'ID', hint: 'showup_id (6+ chars)', controller: _loginId, onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        AuthField(
          label: 'Password',
          hint: '8+ chars, include a special character',
          controller: _password,
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        AuthField(
          label: 'Confirm password',
          hint: 'Re-enter password',
          controller: _passwordConfirm,
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        if (_passwordConfirm.text.isNotEmpty && _password.text != _passwordConfirm.text)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('비밀번호가 서로 다릅니다.', style: TextStyle(color: Color(0xffff6b6b), fontSize: 12)),
          ),
        const SizedBox(height: 10),
        AuthField(
          label: 'Phone',
          hint: '+1 555-010-0000',
          controller: _phone,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {
            _phoneVerified = false;
            _codeSent = false;
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _lime,
              side: const BorderSide(color: _lime),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _phoneVerified ? null : _sendCode,
            child: Text(_phoneVerified ? 'Phone verified' : 'Verify phone'),
          ),
        ),
        if (_codeSent && !_phoneVerified) ...[
          const SizedBox(height: 10),
          AuthField(
            label: 'Verification code',
            hint: '6-digit code',
            controller: _code,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _confirmCode,
              child: const Text('Confirm code'),
            ),
          ),
        ],
        if (_hint != null) ...[
          const SizedBox(height: 8),
          Text(_hint!, style: TextStyle(color: _phoneVerified ? _lime : Colors.white70, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and policy agreement',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              _TermCheck(
                value: _termsService,
                label: 'Terms of Service [Required]',
                onChanged: (v) => setState(() => _termsService = v ?? false),
              ),
              _TermCheck(
                value: _termsPrivacy,
                label: 'Privacy Policy [Required]',
                onChanged: (v) => setState(() => _termsPrivacy = v ?? false),
              ),
              _TermCheck(
                value: _termsMarketing,
                label: 'Marketing emails [Optional]',
                onChanged: (v) => setState(() => _termsMarketing = v ?? false),
              ),
              const SizedBox(height: 6),
              const Text(
                'Users under 17 need guardian consent to change protection settings. Prizes may be subject to taxes. Winners under 18 need guardian consent to claim prizes.',
                style: TextStyle(color: _muted, fontSize: 11, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _canCreate
              ? '가입할 준비가 되었습니다.'
              : '필수 항목, 휴대폰 인증, 필수 약관 동의를 완료하면 가입 버튼이 활성화됩니다.',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xffff6b6b), fontSize: 13)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _canCreate ? _lime : Colors.white24,
              foregroundColor: _canCreate ? Colors.black : Colors.white54,
              disabledBackgroundColor: Colors.white24,
              disabledForegroundColor: Colors.white54,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _canCreate ? _submit : null,
            child: const Text('Create account'),
          ),
        ),
      ],
    );
  }
}

class _TermCheck extends StatelessWidget {
  const _TermCheck({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: _lime,
      checkColor: Colors.black,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.white),
          cursorColor: _lime,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _field,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _lime, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// MM/DD/YYYY 자동 포맷 (웹 생년월일 입력과 비슷하게).
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
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
