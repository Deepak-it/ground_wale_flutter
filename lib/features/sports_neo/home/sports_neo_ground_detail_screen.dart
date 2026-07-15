import 'package:flutter/material.dart';

import '../../../core/utils/base64_image.dart';
import 'sports_neo_booking_summary_screen.dart';

class SportsNeoGroundDetailScreen extends StatelessWidget {
  const SportsNeoGroundDetailScreen({
    super.key,
    required this.name,
    required this.location,
    required this.image,
    required this.rating,
    required this.facilities,
    required this.price,
  });

  final String name;
  final String location;
  final String image;
  final double rating;
  final List<String> facilities;
  final String price;

  @override
  Widget build(BuildContext context) {
    final List<String> shownFacilities = facilities.isEmpty
        ? const <String>['Parking', 'Washroom', 'Water', 'Lighting']
        : facilities;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 104,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 240,
              child: buildBase64OrNetworkImage(
                value: image,
                fit: BoxFit.cover,
                fallback: Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                _TopHeader(
                  title: 'Ground Detail',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 344, bottom: 96),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0x0AFFFFFF),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Color(0x0DFFFFFF),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.location_on_outlined,
                                              color: Color(0x99FFFFFF),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                location,
                                                style: const TextStyle(
                                                  color: Color(0x99FFFFFF),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              '2.0M',
                                              style: TextStyle(
                                                color: Color(0x99FFFFFF),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x3DFFFFFF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.star_border_rounded,
                                          color: Color(0xFFEAB308),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating > 0
                                              ? rating.toStringAsFixed(1)
                                              : '4.6',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: shownFacilities.take(4).map((String f) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: const Color(0x14FFFFFF),
                                    ),
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.wb_sunny_outlined,
                                    color: Color(0xFFF59E0B),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Today: Mostly Sunny • 22°–28°C',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          child: Column(
                            children: <Widget>[
                              _PanelCard(
                                title: 'About Us',
                                child: const Text(
                                  'Professional cricket ground with well-maintained turf pitch. '
                                  'Suitable for practice matches and tournaments. Facilities',
                                  style: TextStyle(
                                    color: Color(0xFFDDDDDD),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x1F2563EB),
                                  ),
                                  color: const Color(0x0A2563EB),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    _CircleAction(
                                      icon: Icons.call,
                                      color: const Color(0xFF08B36A),
                                    ),
                                    _divider(),
                                    _CircleAction(
                                      icon: Icons.near_me_rounded,
                                      color: const Color(0xFFDA321F),
                                    ),
                                    _divider(),
                                    _CircleAction(
                                      icon: Icons.chat,
                                      color: const Color(0xFF22C55E),
                                    ),
                                    _divider(),
                                    _CircleAction(
                                      icon: Icons.sports_cricket,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _SectionTitle(title: 'Select Date'),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 78,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: const <Widget>[
                                    _DateChip(label: 'Mon', day: '12'),
                                    SizedBox(width: 12),
                                    _DateChip(
                                      label: 'Tue',
                                      day: '13',
                                      selected: true,
                                    ),
                                    SizedBox(width: 12),
                                    _DateChip(label: 'Wed', day: '14'),
                                    SizedBox(width: 12),
                                    _DateChip(label: 'Thu', day: '15'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _SlotLegend(),
                              const SizedBox(height: 16),
                              _SlotSection(
                                title: 'Morning',
                                slots: const <_SlotItem>[
                                  _SlotItem(
                                    time: '07:30 - 08:30 AM',
                                    weather: 'Cloudy',
                                    temp: '22°C',
                                    status: 'Available',
                                    colorA: Color(0xFF77A2C4),
                                    colorB: Color(0xFF7FC2F9),
                                  ),
                                  _SlotItem(
                                    time: '09:00 - 10:00 AM',
                                    weather: 'Sunny',
                                    temp: '26°C',
                                    status: 'Booked',
                                    colorA: Color(0xFFE5C28F),
                                    colorB: Color(0xFFDE8E19),
                                  ),
                                  _SlotItem(
                                    time: '10:30 - 11:30 AM',
                                    weather: 'Rainy',
                                    temp: '24°C',
                                    status: 'Blocked',
                                    colorA: Color(0xFF629CDD),
                                    colorB: Color(0xFF1F5C9F),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SlotSection(
                                title: 'Afternoon',
                                slots: const <_SlotItem>[
                                  _SlotItem(
                                    time: '12:00 - 01:00 PM',
                                    weather: 'Cloudy',
                                    temp: '22°C',
                                    status: 'Available',
                                    colorA: Color(0xFF77A2C4),
                                    colorB: Color(0xFF7FC2F9),
                                  ),
                                  _SlotItem(
                                    time: '01:30 - 02:30 PM',
                                    weather: 'Sunny',
                                    temp: '26°C',
                                    status: 'Booked',
                                    colorA: Color(0xFFE5C28F),
                                    colorB: Color(0xFFDE8E19),
                                  ),
                                  _SlotItem(
                                    time: '03:00 - 04:00 PM',
                                    weather: 'Rainy',
                                    temp: '24°C',
                                    status: 'Blocked',
                                    colorA: Color(0xFF629CDD),
                                    colorB: Color(0xFF1F5C9F),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SlotSection(
                                title: 'Evening',
                                slots: const <_SlotItem>[
                                  _SlotItem(
                                    time: '04:30 - 05:30 PM',
                                    weather: 'Cloudy',
                                    temp: '22°C',
                                    status: 'Available',
                                    colorA: Color(0xFF77A2C4),
                                    colorB: Color(0xFF7FC2F9),
                                  ),
                                  _SlotItem(
                                    time: '06:00 - 07:00 PM',
                                    weather: 'Moon Night',
                                    temp: '26°C',
                                    status: 'Booked',
                                    colorA: Color(0xFFE5C28F),
                                    colorB: Color(0xFFDE8E19),
                                  ),
                                  _SlotItem(
                                    time: '07:30 - 08:30 PM',
                                    weather: 'Moon Night',
                                    temp: '24°C',
                                    status: 'Blocked',
                                    colorA: Color(0xFF629CDD),
                                    colorB: Color(0xFF1F5C9F),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0x0AFFFFFF),
                border: Border(top: BorderSide(color: Color(0x1F000000))),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '1 slot(s) selected',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '₹2500',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2563EB)),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SportsNeoBookingSummaryScreen(
                              groundName: name,
                              location: location,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 49,
      color: const Color(0x1FFFFFFF),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: <Widget>[
          Row(
            children: <Widget>[
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          _RoundIcon(icon: Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _RoundIcon(icon: Icons.shopping_cart_outlined),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0x26FFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0x0AFFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFDDDDDD),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFDDDDDD),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.day,
    this.selected = false,
  });

  final String label;
  final String day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: selected ? const Color(0xFF2563EB) : Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFDDDDDD),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            day,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFDDDDDD),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const <Widget>[
        _LegendItem(label: 'Available', color: Color(0xFF08B36A)),
        _LegendItem(label: 'Booked', color: Color(0x99DDDDDD)),
        _LegendItem(label: 'Blocked', color: Color(0xFFD73321)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFDDDDDD),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({required this.title, required this.slots});

  final String title;
  final List<_SlotItem> slots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFDDDDDD),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...slots.map(
          (_SlotItem slot) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SlotCard(slot: slot),
          ),
        ),
      ],
    );
  }
}

class _SlotItem {
  const _SlotItem({
    required this.time,
    required this.weather,
    required this.temp,
    required this.status,
    required this.colorA,
    required this.colorB,
  });

  final String time;
  final String weather;
  final String temp;
  final String status;
  final Color colorA;
  final Color colorB;
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot});

  final _SlotItem slot;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = slot.status == 'Available'
        ? const Color(0xFF08B36A)
        : slot.status == 'Booked'
        ? const Color(0xFF6B7280)
        : const Color(0xFFDB3220);

    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: <Color>[slot.colorA, slot.colorB],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  slot.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${slot.weather}  ${slot.temp}',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slot.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
