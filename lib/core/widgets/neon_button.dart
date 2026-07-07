import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outline = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: outline ? 0 : 4,
          shadowColor: AppTheme.accent.withValues(alpha: 0.35),
          backgroundColor: outline ? Colors.transparent : AppTheme.accent,
          foregroundColor: outline ? AppTheme.accent : const Color(0xFF1D1D1D),
          side: BorderSide(color: outline ? AppTheme.accent : Colors.transparent),
          disabledBackgroundColor: const Color(0x33FFFFFF),
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: disabled
                ? Colors.white54
                : (outline ? AppTheme.accent : const Color(0xFF1D1D1D)),
          ),
        ),
      ),
    );
  }
}
