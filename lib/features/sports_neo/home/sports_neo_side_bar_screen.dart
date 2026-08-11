import 'package:flutter/material.dart';
import 'package:ground_wale/core/utils/base64_image.dart';
import 'package:ground_wale/features/sports_neo/home/sports_neo_dashboard_screen.dart';


// import the helper if it's defined elsewhere
// import 'image_helper.dart';

class SportsNeoSidebar extends StatelessWidget {
  const SportsNeoSidebar({
    super.key,
    required this.menuItems,
    required this.profileName,
    required this.profilePhone,
    required this.profileImage,
    required this.matchesCount,
    required this.teamsCount,
    required this.bookingsCount,
    required this.onMenuTap,
    required this.onLogout,
  });


  final List<String> menuItems;
  final String profileName;
  final String profilePhone;
  final String? profileImage;

  final int matchesCount;
  final int teamsCount;
  final int bookingsCount;

  final ValueChanged<String> onMenuTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 290,
      backgroundColor: const Color(0xFF000B2A),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF001651),
                    Color(0xFF091E67),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0x40FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        width: 46,
                        height: 46,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                        child: buildBase64OrNetworkImage(
                          value: profileImage,
                          fit: BoxFit.cover,
                          fallback: const Icon(
                            Icons.person_outline,
                            size: 22,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      profileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      profilePhone,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Divider(
                    color: Color(0x2EFFFFFF),
                    height: 1,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DrawerStat(
                          number: '$matchesCount',
                          label: 'Matches',
                        ),
                      ),
                      Expanded(
                        child: DrawerStat(
                          number: '$teamsCount',
                          label: 'Teams',
                        ),
                      ),
                      Expanded(
                        child: DrawerStat(
                          number: '$bookingsCount',
                          label: 'Bookings',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return SidebarMenuTile(
                    label: menuItems[index],
                    onTap: () {
                      Navigator.pop(context);
                      onMenuTap(menuItems[index]);
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF11A07),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onLogout,
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerStat extends StatelessWidget {
  const DrawerStat({
    super.key,
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SidebarMenuTile extends StatelessWidget {
  const SidebarMenuTile({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xD9FFFFFF),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xD9FFFFFF),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}