import 'package:flutter/material.dart';

class ModuleBottomNavItem {
  const ModuleBottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class ModuleBottomNav extends StatelessWidget {
  const ModuleBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    required this.borderColor,
    this.height = 80,
    this.horizontalPadding = 24,
    this.bottomPadding = 16,
    this.autoItemWidth = false,
    this.itemWidth = 92,
  });

  final List<ModuleBottomNavItem> items;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final Color borderColor;
  final double height;
  final double horizontalPadding;
  final double bottomPadding;
  final bool autoItemWidth;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        bottomPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double computedWidth = items.isEmpty
              ? itemWidth
              : constraints.maxWidth / items.length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(items.length, (int index) {
              final ModuleBottomNavItem item = items[index];
              final bool active = index == currentIndex;
              final Color color = active ? activeColor : inactiveColor;

              return InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: autoItemWidth ? computedWidth : itemWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(item.icon, color: color, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
