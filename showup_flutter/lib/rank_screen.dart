import 'package:flutter/material.dart';

import 'home_screen.dart';

const _lime = Color(0xffd7ff38);
const _muted = Color(0xff6b7280);

/// 웹 index.html 랭킹 화면을 Flutter로 옮긴 화면.
class RankScreen extends StatefulWidget {
  const RankScreen({
    super.key,
    required this.entries,
    required this.onAction,
  });

  final List<HomeChallenge> entries;
  final ValueChanged<String> onAction;

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  final _searchController = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_RankEntry> get _rows {
    final base = widget.entries.isEmpty
        ? <HomeChallenge>[]
        : List<HomeChallenge>.generate(
            100,
            (index) => widget.entries[index % widget.entries.length],
          );

    // 같은 챌린지를 반복해도 순위가 보이도록 점수에 미세 차이를 둡니다.
    final rows = <_RankEntry>[
      for (var i = 0; i < base.length; i++)
        _RankEntry(
          rank: i + 1,
          challenge: base[i],
          score: base[i].score - i * 37,
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    for (var i = 0; i < rows.length; i++) {
      rows[i] = rows[i].copyWith(rank: i + 1);
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? rows
        : rows
            .where(
              (row) =>
                  row.challenge.title.toLowerCase().contains(query) ||
                  row.challenge.handle.toLowerCase().contains(query),
            )
            .toList();

    if (_expanded || query.isNotEmpty) {
      return filtered.take(100).toList();
    }
    return filtered.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final showingAll = _expanded || _searchController.text.trim().isNotEmpty;

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
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RANK',
                          style: TextStyle(
                            color: _lime,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Live ranking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onAction('settings'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'TOP10 is shown by default. Tap More to view up to TOP100.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 14),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white54, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: _lime,
                        decoration: const InputDecoration(
                          hintText: 'Search ranking',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffe8eaef)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Creator TOP100',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                showingAll ? 'Showing up to TOP100' : 'Showing TOP10',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('검색 결과가 없습니다.', style: TextStyle(color: _muted)),
                  ),
                )
              else
                for (final row in rows) _RankTile(entry: row),
              const SizedBox(height: 8),
              if (_searchController.text.trim().isEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff101218),
                      side: const BorderSide(color: Color(0xffd1d5db)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? 'Show less' : 'More',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff101820), Color(0xff1c2433)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prediction winners',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Announced after Sunday 6PM',
                style: TextStyle(
                  color: _lime,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Five correct entrants will be drawn for gift cards.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => widget.onAction('winners'),
                  child: const Text('Check announcement'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankEntry {
  const _RankEntry({
    required this.rank,
    required this.challenge,
    required this.score,
  });

  final int rank;
  final HomeChallenge challenge;
  final int score;

  _RankEntry copyWith({int? rank, HomeChallenge? challenge, int? score}) {
    return _RankEntry(
      rank: rank ?? this.rank,
      challenge: challenge ?? this.challenge,
      score: score ?? this.score,
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.entry});

  final _RankEntry entry;

  @override
  Widget build(BuildContext context) {
    final top = entry.rank <= 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: top ? const Color(0xfff7ffe0) : const Color(0xfff6f7f9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: top ? _lime.withOpacity(0.55) : const Color(0xffe8eaef),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: top ? _lime : Colors.white,
              foregroundColor: Colors.black,
              child: Text(
                '${entry.rank}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.challenge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    entry.challenge.handle,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${_formatScore(entry.score)} pts',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatScore(int value) {
  if (value >= 1000000) {
    final n = value / 1000000;
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final n = value / 1000;
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}K';
  }
  return '$value';
}
