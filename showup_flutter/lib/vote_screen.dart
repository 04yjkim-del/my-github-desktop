import 'package:flutter/material.dart';

import 'home_screen.dart';

const _lime = Color(0xffd7ff38);
const _ink = Color(0xff101218);
const _muted = Color(0xff6b7280);

enum VotePhase { general, top10, finalRound, closed }

/// 웹 index.html 투표 화면을 Flutter로 옮긴 화면.
class VoteScreen extends StatefulWidget {
  const VoteScreen({
    super.key,
    required this.candidates,
    required this.ranking,
    required this.onVote,
    required this.onAction,
    this.externalPhase,
    this.votedCandidateTitle,
  });

  final List<HomeChallenge> candidates;
  final List<HomeChallenge> ranking;
  final ValueChanged<HomeChallenge> onVote;
  final ValueChanged<String> onAction;
  final VotePhase? externalPhase;
  final String? votedCandidateTitle;

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final _searchController = TextEditingController();
  late VotePhase _phase;
  String? _votedTitle;

  @override
  void initState() {
    super.initState();
    _phase = widget.externalPhase ?? VotePhase.general;
    _votedTitle = widget.votedCandidateTitle;
  }

  @override
  void didUpdateWidget(covariant VoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalPhase != null && widget.externalPhase != oldWidget.externalPhase) {
      _phase = widget.externalPhase!;
    }
    if (widget.votedCandidateTitle != oldWidget.votedCandidateTitle) {
      _votedTitle = widget.votedCandidateTitle;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _phaseTitle => switch (_phase) {
        VotePhase.general => 'General vote',
        VotePhase.top10 => 'TOP10 vote',
        VotePhase.finalRound => 'Final vote',
        VotePhase.closed => 'Voting closed',
      };

  String get _phaseText => switch (_phase) {
        VotePhase.general => 'Fri 6PM - Sat 6PM',
        VotePhase.top10 => 'Sat 6PM - Sun 3PM',
        VotePhase.finalRound => 'Sun 3PM - Sun 6PM',
        VotePhase.closed => 'Results after Sun 6PM',
      };

  List<HomeChallenge> get _visibleCandidates {
    final query = _searchController.text.trim().toLowerCase();
    var list = List<HomeChallenge>.from(widget.candidates)
      ..sort((a, b) => b.votes.compareTo(a.votes));

    if (_phase == VotePhase.top10) {
      list = list.take(5).toList();
    } else if (_phase == VotePhase.finalRound) {
      list = list.take(3).toList();
    } else if (_phase == VotePhase.closed) {
      list = list.take(3).toList();
    }

    if (query.isEmpty) return list;
    return list
        .where(
          (c) =>
              c.title.toLowerCase().contains(query) ||
              c.handle.toLowerCase().contains(query),
        )
        .toList();
  }

  void _castVote(HomeChallenge candidate) {
    if (_phase == VotePhase.closed) {
      widget.onAction('vote-closed');
      return;
    }
    if (_votedTitle != null && _votedTitle != candidate.title) {
      widget.onAction('vote-already');
      return;
    }
    setState(() {
      _votedTitle = _votedTitle == candidate.title ? null : candidate.title;
    });
    if (_votedTitle == null) {
      widget.onAction('vote-cancel');
    } else {
      widget.onVote(candidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _visibleCandidates;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffe5e7eb)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: _muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search profiles',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => widget.onAction('notify'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xffe5e7eb)),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _VoteWeekCard(),
        const SizedBox(height: 14),
        LiveRankingCard(items: widget.ranking.take(3).toList()),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                'Vote',
                style: TextStyle(
                  color: _lime,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _phaseTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(_phaseText, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              _VoteStageRow(
                phase: _phase,
                onSelect: (phase) => setState(() => _phase = phase),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('검색 결과가 없습니다.', style: TextStyle(color: _muted)),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 420;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: candidates.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: wide ? 2 : 1,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: wide ? 1.55 : 2.35,
                ),
                itemBuilder: (context, index) {
                  final candidate = candidates[index];
                  final selected = _votedTitle == candidate.title;
                  return _CandidateCard(
                    rank: index + 1,
                    candidate: candidate,
                    selected: selected,
                    closed: _phase == VotePhase.closed,
                    onVote: () => _castVote(candidate),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _VoteWeekCard extends StatelessWidget {
  const _VoteWeekCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe8eaef)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS WEEK',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Weekly challenge',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _PrizeTile(rank: '1st', amount: '\$1,000', highlight: true)),
              SizedBox(width: 8),
              Expanded(child: _PrizeTile(rank: '2nd', amount: '\$500')),
              SizedBox(width: 8),
              Expanded(child: _PrizeTile(rank: '3rd', amount: '\$300')),
            ],
          ),
          const SizedBox(height: 14),
          const _ScheduleRow(label: 'Vote', time: 'Fri 6PM'),
          const _ScheduleRow(label: 'TOP10', time: 'Sat 6PM'),
          const _ScheduleRow(label: 'Final', time: 'Sun 3PM'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfff4f7ec),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prediction reward',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  '5 winners drawn from correct predictions · gift cards',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'TOP candidates are selected by votes. Views, likes, and comments affect ranking only.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PrizeTile extends StatelessWidget {
  const _PrizeTile({
    required this.rank,
    required this.amount,
    this.highlight = false,
  });

  final String rank;
  final String amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xfff7ffe0) : const Color(0xfff6f7f9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? _lime.withOpacity(0.7) : const Color(0xffe8eaef),
        ),
      ),
      child: Column(
        children: [
          Text(rank, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          ),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

class _VoteStageRow extends StatelessWidget {
  const _VoteStageRow({
    required this.phase,
    required this.onSelect,
  });

  final VotePhase phase;
  final ValueChanged<VotePhase> onSelect;

  @override
  Widget build(BuildContext context) {
    const stages = [
      (VotePhase.general, 'General', 'Fri 6PM'),
      (VotePhase.top10, 'TOP10', 'Sat 6PM'),
      (VotePhase.finalRound, 'Final', 'Sun 3PM'),
      (VotePhase.closed, 'Close', 'Sun 6PM'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final stage in stages)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSelect(stage.$1),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: phase == stage.$1 ? _lime : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: phase == stage.$1 ? _lime : Colors.white24,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.$2,
                        style: TextStyle(
                          color: phase == stage.$1 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stage.$3,
                        style: TextStyle(
                          color: phase == stage.$1 ? Colors.black87 : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.rank,
    required this.candidate,
    required this.selected,
    required this.closed,
    required this.onVote,
  });

  final int rank;
  final HomeChallenge candidate;
  final bool selected;
  final bool closed;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? _lime : const Color(0xffe8eaef),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: rank == 1 ? _lime : const Color(0xffeef0f3),
            foregroundColor: Colors.black,
            child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  candidate.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${candidate.handle} · ${candidate.votes} votes',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: selected
                  ? _lime
                  : closed
                      ? Colors.black26
                      : _ink,
              foregroundColor: selected ? Colors.black : Colors.white,
              disabledBackgroundColor: Colors.black26,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: closed && !selected ? null : onVote,
            child: Text(
              closed
                  ? 'Closed'
                  : selected
                      ? 'Voted'
                      : 'Vote',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
