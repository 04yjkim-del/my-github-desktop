import 'package:flutter/material.dart';

const _lime = Color(0xffd7ff38);
const _muted = Color(0xff6b7280);

/// 웹 settingsOverlay 를 Flutter로 옮긴 화면.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  static const _items = [
    ('edit-profile', 'Edit profile', Icons.person_outline),
    ('password', 'Change password', Icons.lock_outline),
    ('phone', 'Phone verification', Icons.phone_android_outlined),
    ('privacy', 'Privacy settings', Icons.shield_outlined),
    ('notifications', 'Notification settings', Icons.notifications_none_rounded),
    ('blocked', 'Blocked accounts', Icons.block_outlined),
    ('help', 'Help center', Icons.help_outline_rounded),
    ('terms', 'Terms and policies', Icons.article_outlined),
    ('prize-claim', 'Prize claim (demo)', Icons.card_giftcard_outlined),
    ('logout', 'Log out', Icons.logout_rounded),
    ('withdraw', 'Delete account', Icons.delete_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef0f3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Settings and activity', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe8eaef)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _lime,
                  child: Text('SU', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      SizedBox(height: 2),
                      Text('@showup_name', style: TextStyle(color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe8eaef)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  ListTile(
                    leading: Icon(
                      _items[i].$3,
                      color: _items[i].$1 == 'withdraw' ? Colors.red : Colors.black87,
                    ),
                    title: Text(
                      _items[i].$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _items[i].$1 == 'withdraw' ? Colors.red : Colors.black,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
                    onTap: () => onAction(_items[i].$1),
                  ),
                  if (i < _items.length - 1) const Divider(height: 1, indent: 56),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prize claims may require phone verification, birth confirmation, and guardian consent for users under 18.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}
