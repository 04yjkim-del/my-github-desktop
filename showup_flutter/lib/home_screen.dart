import 'package:flutter/material.dart';

const _lime = Color(0xffd7ff38);
const _ink = Color(0xff101218);
const _muted = Color(0xff6b7280);

/// 웹 index.html 홈 화면(HOT 카드 · 주간 챌린지 · TOP3)을 Flutter로 옮긴 화면.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.challenge,
    required this.ranking,
    required this.onNext,
    required this.onAction,
  });

  final HomeChallenge challenge;
  final List<HomeChallenge> ranking;
  final VoidCallback onNext;
  final ValueChanged<String> onAction;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchFilter = 'all';
  bool _liked = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.title != widget.challenge.title) {
      _liked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
      children: [
        _HomeHeader(
          searchController: _searchController,
          searchFilter: _searchFilter,
          onFilterChanged: (value) => setState(() => _searchFilter = value),
          onSearch: () {
            final q = _searchController.text.trim();
            widget.onAction(q.isEmpty ? 'search-empty' : 'search:$q');
          },
          onNotify: () => widget.onAction('notify'),
        ),
        const SizedBox(height: 14),
        HotHeroCard(
          challenge: widget.challenge,
          liked: _liked,
          onOpen: widget.onNext,
          onLike: () {
            setState(() => _liked = !_liked);
            widget.onAction(_liked ? 'like' : 'unlike');
          },
          onComment: () => widget.onAction('comment'),
          onReport: () => widget.onAction('report'),
          onShare: () => widget.onAction('share'),
        ),
        const SizedBox(height: 14),
        const WeekChallengeCard(),
        const SizedBox(height: 14),
        LiveRankingCard(items: widget.ranking.take(3).toList()),
      ],
    );
  }
}

class HomeChallenge {
  const HomeChallenge({
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.searchController,
    required this.searchFilter,
    required this.onFilterChanged,
    required this.onSearch,
    required this.onNotify,
  });

  final TextEditingController searchController;
  final String searchFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSearch;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SHOW UP Weekly',
          style: TextStyle(
            color: _muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "Today's hot challenge",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.only(left: 12, right: 6),
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
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => onSearch(),
                        decoration: const InputDecoration(
                          hintText: 'Search profiles',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: searchFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'username', child: Text('Username')),
                          DropdownMenuItem(value: 'name', child: Text('Display name')),
                        ],
                        onChanged: (value) {
                          if (value != null) onFilterChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onNotify,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xffe5e7eb)),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class HotHeroCard extends StatelessWidget {
  const HotHeroCard({
    super.key,
    required this.challenge,
    required this.liked,
    required this.onOpen,
    required this.onLike,
    required this.onComment,
    required this.onReport,
    required this.onShare,
  });

  final HomeChallenge challenge;
  final bool liked;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onReport;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff07080c), Color(0xff1a2030), Color(0xff101820)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: _WordCloud(
                      words: ['TREND', 'HYPE', 'MOVE', 'VOTE', 'FAME', 'UP'],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _lime,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 110,
                child: Column(
                  children: [
                    _FeedAction(
                      icon: liked ? Icons.emoji_events : Icons.emoji_events_outlined,
                      label: 'Like',
                      active: liked,
                      onTap: onLike,
                    ),
                    _FeedAction(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      onTap: onComment,
                    ),
                    _FeedAction(
                      icon: Icons.priority_high_rounded,
                      label: 'Report',
                      onTap: onReport,
                    ),
                    _FeedAction(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      onTap: onShare,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 88,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${challenge.handle} · views ${_formatCount(challenge.views)} · Like ${_formatCount(challenge.likes)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      onPressed: onOpen,
                      child: const Text('Next feed'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          IconButton(
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.35),
              foregroundColor: active ? _lime : Colors.white,
            ),
            icon: Icon(icon),
          ),
          Text(
            label,
            style: TextStyle(
              color: active ? _lime : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class WeekChallengeCard extends StatelessWidget {
  const WeekChallengeCard({super.key});

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
          Row(
            children: const [
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
          const _ScheduleRow(label: 'Final', time: 'Sun 6PM'),
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
                  '3 winners drawn from correct predictions · \$50 gift cards',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
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
        border: Border.all(color: highlight ? _lime.withOpacity(0.7) : const Color(0xffe8eaef)),
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

class LiveRankingCard extends StatelessWidget {
  const LiveRankingCard({super.key, required this.items});

  final List<HomeChallenge> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe8eaef)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live ranking TOP3',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: i == 0 ? _lime : const Color(0xffeef0f3),
                foregroundColor: Colors.black,
                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(items[i].handle),
              trailing: Text(
                '${_formatCount(items[i].score)} pts',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
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
                color: Colors.white.withOpacity(0.14),
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
          .toList(),
    );
  }
}

String _formatCount(int value) {
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
