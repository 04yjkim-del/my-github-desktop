import 'package:flutter/material.dart';

import 'home_screen.dart';

const _lime = Color(0xffd7ff38);
const _muted = Color(0xff9aa3b2);

/// 웹 index.html 예측(BET) 화면을 Flutter로 옮긴 화면.
class BetScreen extends StatefulWidget {
  const BetScreen({
    super.key,
    required this.candidates,
    required this.onLock,
    required this.onAction,
    this.externalLocked = false,
    this.externalPicks,
  });

  final List<HomeChallenge> candidates;
  final ValueChanged<Map<int, HomeChallenge>> onLock;
  final ValueChanged<String> onAction;
  final bool externalLocked;
  final Map<int, HomeChallenge>? externalPicks;

  @override
  State<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BetScreen> {
  late final picks = <int, HomeChallenge?>{1: null, 2: null, 3: null};
  late bool locked;

  @override
  void initState() {
    super.initState();
    locked = widget.externalLocked;
    _applyExternalPicks(widget.externalPicks);
  }

  @override
  void didUpdateWidget(covariant BetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalLocked != oldWidget.externalLocked) {
      locked = widget.externalLocked;
    }
    if (widget.externalPicks != oldWidget.externalPicks) {
      _applyExternalPicks(widget.externalPicks);
    }
  }

  void _applyExternalPicks(Map<int, HomeChallenge>? externalPicks) {
    if (externalPicks == null) return;
    for (final entry in externalPicks.entries) {
      picks[entry.key] = entry.value;
    }
  }

  bool get _allPicked => picks.values.every((value) => value != null);

  Future<void> _openPickSheet(int rank) async {
    if (locked) {
      widget.onAction('bet-locked');
      return;
    }

    final selected = await showModalBottomSheet<HomeChallenge>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xff12151c),
      builder: (context) {
        final options = List<HomeChallenge>.from(widget.candidates)
          ..sort((a, b) => b.votes.compareTo(a.votes));
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                'Pick $rank${_ordinal(rank)} place',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the exact finishing order for TOP3.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (final candidate in options.take(10))
                Builder(
                  builder: (context) {
                    final duplicate = picks.entries.any(
                      (entry) => entry.key != rank && entry.value?.title == candidate.title,
                    );
                    return ListTile(
                      enabled: !duplicate,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: duplicate ? Colors.white12 : _lime.withOpacity(0.2),
                        foregroundColor: duplicate ? Colors.white38 : _lime,
                        child: Text(
                          candidate.handle.length > 1
                              ? candidate.handle[1].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      title: Text(
                        candidate.title,
                        style: TextStyle(
                          color: duplicate ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        duplicate ? 'Already selected in another slot' : '${candidate.handle} · ${candidate.votes} votes',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      onTap: duplicate ? null : () => Navigator.pop(context, candidate),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() => picks[rank] = selected);
  }

  void _confirm() {
    if (locked) {
      widget.onAction('bet-locked');
      return;
    }
    if (!_allPicked) {
      widget.onAction('bet-incomplete');
      return;
    }

    final result = <int, HomeChallenge>{
      1: picks[1]!,
      2: picks[2]!,
      3: picks[3]!,
    };
    setState(() => locked = true);
    widget.onLock(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff07080c), Color(0xff181b23)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BET',
                style: TextStyle(
                  color: _lime,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Final prediction',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sunday 3–6 PM. Pick 1st–3rd in exact order to enter the draw.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  locked
                      ? 'Prediction locked · cannot be changed'
                      : 'Predictions cannot be changed after submit',
                  style: TextStyle(
                    color: locked ? _lime : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffe8eaef)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOP3 final',
                style: TextStyle(
                  color: Color(0xff6b7280),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              const _PodiumVisual(),
              const SizedBox(height: 14),
              const Text(
                'Pick the exact 1st to 3rd order. 5 winners are drawn from correct predictions.',
                style: TextStyle(color: Color(0xff6b7280), height: 1.35),
              ),
              const SizedBox(height: 16),
              for (final rank in [1, 2, 3]) ...[
                _PickSlot(
                  rank: rank,
                  challenge: picks[rank],
                  locked: locked,
                  onTap: () => _openPickSheet(rank),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: locked
                        ? Colors.black26
                        : _allPicked
                            ? _lime
                            : const Color(0xff101218),
                    foregroundColor: locked
                        ? Colors.white70
                        : _allPicked
                            ? Colors.black
                            : Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: locked ? null : _confirm,
                  child: Text(locked ? 'Prediction confirmed' : 'Confirm prediction'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumVisual extends StatelessWidget {
  const _PodiumVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Expanded(child: _PodiumBlock(place: 2, height: 88, color: Color(0xffd1d5db))),
          SizedBox(width: 8),
          Expanded(child: _PodiumBlock(place: 1, height: 118, color: _lime)),
          SizedBox(width: 8),
          Expanded(child: _PodiumBlock(place: 3, height: 72, color: Color(0xfff59e0b))),
        ],
      ),
    );
  }
}

class _PodiumBlock extends StatelessWidget {
  const _PodiumBlock({
    required this.place,
    required this.height,
    required this.color,
  });

  final int place;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          Icons.workspace_premium_rounded,
          color: place == 1 ? _lime : const Color(0xff9ca3af),
          size: place == 1 ? 28 : 22,
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(place == 1 ? 0.35 : 0.22),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: color.withOpacity(0.7)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _PickSlot extends StatelessWidget {
  const _PickSlot({
    required this.rank,
    required this.challenge,
    required this.locked,
    required this.onTap,
  });

  final int rank;
  final HomeChallenge? challenge;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = challenge != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xfff7ffe0) : const Color(0xfff6f7f9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _lime.withOpacity(0.8) : const Color(0xffe5e7eb),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _lime : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffe5e7eb)),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rank}${_ordinal(rank)}',
                      style: const TextStyle(
                        color: Color(0xff6b7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge?.title ?? 'Not selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: selected ? Colors.black : const Color(0xff9ca3af),
                      ),
                    ),
                    if (challenge != null)
                      Text(
                        challenge!.handle,
                        style: const TextStyle(color: Color(0xff6b7280), fontSize: 12),
                      ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right_rounded,
                color: const Color(0xff9ca3af),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _ordinal(int rank) {
  return switch (rank) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
