import 'package:flutter/material.dart';

import 'home_screen.dart';

const _lime = Color(0xffd7ff38);
const _muted = Color(0xff6b7280);

/// 웹 profileModal + profile 탭을 Flutter로 옮긴 화면.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.posts,
    required this.onAction,
    required this.onOpenSettings,
  });

  final List<HomeChallenge> posts;
  final ValueChanged<String> onAction;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'igeonhyi9849',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: () => onAction('notify'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            IconButton(
              onPressed: () => _openMenu(context),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
            IconButton(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profile', style: TextStyle(color: _muted, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: () => onAction('photo'),
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: _lime.withOpacity(0.25),
                      child: const Text('SU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text(
                          'Weekly challenge creator · show up',
                          style: TextStyle(color: _muted, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activity', style: TextStyle(color: _muted, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(label: 'Posts', value: '${posts.length}'),
                  const SizedBox(width: 10),
                  _StatChip(label: 'Interest', value: '5', onTap: () => onAction('interest')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This week', style: TextStyle(color: _muted, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              const Text(
                'K-pop Hook Dance · Vote Fri 6PM',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text('Current rank preview: TOP10 candidate', style: TextStyle(color: _muted, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            return InkWell(
              onTap: () => onAction('post:${post.title}'),
              onLongPress: () => onAction('post-menu:${post.title}'),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff101820), Color(0xff1c2433)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Chip(
                        label: Text('POST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: _lime,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      const Spacer(),
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      Text(post.handle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('View profile photo'),
                onTap: () {
                  Navigator.pop(context);
                  onAction('photo');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Copy profile URL'),
                onTap: () {
                  Navigator.pop(context);
                  onAction('copy-url');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share profile'),
                onTap: () {
                  Navigator.pop(context);
                  onAction('share-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded),
                title: const Text('QR code'),
                onTap: () {
                  Navigator.pop(context);
                  onAction('qr');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xfff6f7f9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe8eaef)),
        ),
        child: Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xffe8eaef)),
  );
}
