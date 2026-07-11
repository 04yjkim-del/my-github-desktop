import 'package:flutter/material.dart';

import 'home_screen.dart';

const _lime = Color(0xffd7ff38);

/// 웹 reelsOverlay / commentModal / notification UI 프로토타입.
class ReelsViewer extends StatelessWidget {
  const ReelsViewer({
    super.key,
    required this.challenge,
    required this.onClose,
    required this.onAction,
  });

  final HomeChallenge challenge;
  final VoidCallback onClose;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xff101820),
                    const Color(0xff07080c),
                    _lime.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 88, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Chip(
                        label: Text('HOT REELS', style: TextStyle(fontWeight: FontWeight.w900)),
                        backgroundColor: _lime,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${challenge.handle} · views ${_formatCount(challenge.views)} · Like ${_formatCount(challenge.likes)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                _Action(icon: Icons.emoji_events_outlined, label: 'Like', onTap: () => onAction('like')),
                _Action(icon: Icons.chat_bubble_outline, label: 'Comment', onTap: () => onAction('comment')),
                _Action(icon: Icons.priority_high_rounded, label: 'Report', onTap: () => onAction('report')),
                _Action(icon: Icons.ios_share_rounded, label: 'Share', onTap: () => onAction('share')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsSheet extends StatelessWidget {
  const CommentsSheet({
    super.key,
    required this.challenge,
    required this.onCommentMenu,
  });

  final HomeChallenge challenge;
  final ValueChanged<String> onCommentMenu;

  static const _samples = [
    ('@showup.me', 'Sample comment'),
    ('@move.ground', 'Strong form today'),
    ('@show.runner', 'Looks like TOP10'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Text('Comment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${challenge.title} · ${challenge.handle}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            for (final sample in _samples)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sample.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(sample.$2),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => onCommentMenu(sample.$1),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a comment…',
                filled: true,
                fillColor: const Color(0xfff3f4f6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key, this.onClaimPrize});

  final VoidCallback? onClaimPrize;

  static const _items = [
    ('Vote opens Friday 6PM', 'Weekly challenge reminder'),
    ('Your DROP passed AI review', 'K-pop Hook Dance'),
    ('Prediction window opens Sunday 3PM', 'Final TOP3 draw'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfff7ffe0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _lime.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prize notice', style: TextStyle(fontWeight: FontWeight.w800, color: _lime)),
                  const SizedBox(height: 4),
                  const Text('Congratulations on 1st place', style: TextStyle(fontWeight: FontWeight.w900)),
                  const Text('Prize claim is open. Winners only.', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                      onClaimPrize?.call();
                    },
                    child: const Text('Claim prize'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final item in _items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: _lime,
                  foregroundColor: Colors.black,
                  child: Icon(Icons.notifications_active_outlined, size: 18),
                ),
                title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(item.$2),
              ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          IconButton(
            onPressed: onTap,
            style: IconButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white),
            icon: Icon(icon),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000) {
    final n = value / 1000;
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}K';
  }
  return '$value';
}
