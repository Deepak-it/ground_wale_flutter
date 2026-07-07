import 'package:flutter/material.dart';

class TurfPageScaffold extends StatelessWidget {
  const TurfPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (showBackButton)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 14),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class TurfCard extends StatelessWidget {
  const TurfCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.backgroundColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),
      child: child,
    );
  }
}

class TurfMenuTile extends StatelessWidget {
  const TurfMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFFDDF730),
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TurfCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}
