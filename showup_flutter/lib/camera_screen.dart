import 'dart:async';

import 'package:flutter/material.dart';

const _lime = Color(0xffd7ff38);

/// 웹 index.html 카메라(DROP) 화면을 Flutter로 옮긴 프로토타입.
/// 실제 카메라/갤러리 SDK는 아직 연결하지 않고, UI·흐름만 맞춥니다.
class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.onUpload,
    required this.onAction,
  });

  final VoidCallback onUpload;
  final ValueChanged<String> onAction;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _frontCamera = false;
  bool _recording = false;
  bool _hasClip = false;
  bool _saved = false;
  String? _musicTitle;
  String? _status;
  int _seconds = 0;
  Timer? _timer;

  static const _tracks = [
    'Trend Pulse',
    'Night Hook',
    'City Beat',
    'No Music',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _facingLabel => _frontCamera ? 'Front camera' : 'Back camera';

  String get _recLabel {
    final m = (_seconds ~/ 60).toString().padLeft(1, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return 'REC $m:$s';
  }

  void _toggleRecord() {
    if (_recording) {
      _timer?.cancel();
      setState(() {
        _recording = false;
        _hasClip = true;
        _status = 'Preview ready · ${_recLabel.replaceFirst('REC ', '')}';
      });
      widget.onAction('record-stop');
      return;
    }

    setState(() {
      _recording = true;
      _hasClip = false;
      _saved = false;
      _seconds = 0;
      _status = 'Recording… up to 1 min';
    });
    widget.onAction('record-start');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _seconds += 1);
      if (_seconds >= 60) {
        _toggleRecord();
      }
    });
  }

  Future<void> _pickMusic() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xff12151c),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const Text(
                'Choose music',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final track in _tracks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    track == 'No Music' ? Icons.music_off_rounded : Icons.music_note_rounded,
                    color: _lime,
                  ),
                  title: Text(track, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, track),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _musicTitle = selected == 'No Music' ? null : selected;
      _status = selected == 'No Music' ? 'Music cleared' : 'Music: $selected';
    });
    widget.onAction('music');
  }

  void _flipCamera() {
    if (_recording) {
      widget.onAction('flip-blocked');
      return;
    }
    setState(() {
      _frontCamera = !_frontCamera;
      _status = _facingLabel;
    });
    widget.onAction('flip');
  }

  void _gallery() {
    if (_recording) {
      widget.onAction('gallery-blocked');
      return;
    }
    setState(() {
      _hasClip = true;
      _saved = false;
      _seconds = 12;
      _status = 'Gallery clip selected (prototype)';
    });
    widget.onAction('gallery');
  }

  void _save() {
    if (!_hasClip) {
      widget.onAction('save-empty');
      return;
    }
    setState(() {
      _saved = true;
      _status = 'Saved to drafts (prototype)';
    });
    widget.onAction('save');
  }

  void _share() {
    if (!_hasClip) {
      widget.onAction('share-empty');
      return;
    }
    widget.onAction('share');
  }

  void _drop() {
    if (_recording) {
      widget.onAction('drop-blocked');
      return;
    }
    if (!_hasClip) {
      widget.onAction('drop-empty');
      return;
    }
    setState(() => _status = 'Preparing DROP upload…');
    widget.onUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 96),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _frontCamera
                        ? const [Color(0xff1a2030), Color(0xff0b0d12), Color(0xff151018)]
                        : const [Color(0xff101820), Color(0xff07080c), Color(0xff12151c)],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _WordCloud(
                    words: ['UPLOAD', 'FILTER', 'MUSIC', '1 MIN', 'NO COPY', 'DROP'],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.72),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _RoundIconButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => widget.onAction('back'),
                        ),
                        const Spacer(),
                        _RoundIconButton(
                          icon: Icons.music_note_rounded,
                          onTap: _pickMusic,
                          active: _musicTitle != null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _Pill(text: _facingLabel),
                    ),
                    if (_recording) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _Pill(
                          text: _recLabel,
                          color: const Color(0xffff4d4d),
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_musicTitle != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _Pill(text: '♪ $_musicTitle', color: _lime, textColor: Colors.black),
                      ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        _Pill(text: 'Up to 1 min'),
                        SizedBox(width: 8),
                        _Pill(text: 'No filter'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SideControl(
                          icon: Icons.photo_library_outlined,
                          label: 'Gallery',
                          onTap: _gallery,
                        ),
                        _RecordButton(recording: _recording, onTap: _toggleRecord),
                        _SideControl(
                          icon: Icons.cameraswitch_rounded,
                          label: 'Flip',
                          onTap: _flipCamera,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SideControl(
                          icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                          label: 'Save',
                          onTap: _save,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _lime,
                                foregroundColor: Colors.black,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: _drop,
                              child: const Text('DROP'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _SideControl(
                          icon: Icons.ios_share_rounded,
                          label: 'Share',
                          onTap: _share,
                        ),
                      ],
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          _status!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordCloud extends StatelessWidget {
  const _WordCloud({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 18,
      children: words
          .map(
            (word) => Text(
              word,
              style: TextStyle(
                color: Colors.white.withOpacity(0.12),
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    this.color,
    this.textColor,
  });

  final String text;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? _lime : Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: active ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}

class _SideControl extends StatelessWidget {
  const _SideControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.black.withOpacity(0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.recording,
    required this.onTap,
  });

  final bool recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: recording ? 34 : 62,
          height: recording ? 34 : 62,
          decoration: BoxDecoration(
            color: const Color(0xffff3b30),
            borderRadius: BorderRadius.circular(recording ? 8 : 999),
          ),
        ),
      ),
    );
  }
}
