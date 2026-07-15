import 'package:flutter/material.dart';

import '../../../core/utils/base64_image.dart';
import 'sports_neo_ground_detail_screen.dart';

class SportsNeoNearbyGroundsScreen extends StatelessWidget {
  const SportsNeoNearbyGroundsScreen({
    super.key,
    required this.grounds,
    required this.fallbackLocation,
  });

  final List<Map<String, dynamic>> grounds;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final List<_NearbyGroundItem> items = grounds
        .map((Map<String, dynamic> raw) {
          return _NearbyGroundItem.fromMap(
            raw,
            fallbackLocation: fallbackLocation,
          );
        })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _NearbyGroundsHeader(
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: <Widget>[
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search Ground or location',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nearby Ground',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0x0AFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x1F242424)),
                      ),
                      child: const Text(
                        'No grounds available right now',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ...items.map(
                      (_NearbyGroundItem item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _NearbyGroundListCard(item: item),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyGroundsHeader extends StatelessWidget {
  const _NearbyGroundsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          children: <Widget>[
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your Nearby Grounds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyGroundListCard extends StatelessWidget {
  const _NearbyGroundListCard({required this.item});

  final _NearbyGroundItem item;

  @override
  Widget build(BuildContext context) {
    final Widget imageFallback = Container(
      color: const Color(0xFF3B4253),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white54, size: 28),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F242424)),
        color: const Color(0x0AFFFFFF),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: buildBase64OrNetworkImage(
                    value: item.image,
                    fit: BoxFit.cover,
                    fallback: imageFallback,
                  ),
                ),
                if (item.rating > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.star_border_rounded,
                            size: 14,
                            color: Color(0xFFEAB308),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0x99FFFFFF),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: item.facilities.map((String feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: Text(
                        feature,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.price,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SportsNeoGroundDetailScreen(
                              name: item.name,
                              location: item.location,
                              image: item.image,
                              rating: item.rating,
                              facilities: item.facilities,
                              price: item.price,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'View Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyGroundItem {
  const _NearbyGroundItem({
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

  factory _NearbyGroundItem.fromMap(
    Map<String, dynamic> map, {
    required String fallbackLocation,
  }) {
    final String name =
        _stringFromAny(map, <String>['name', 'groundName', 'title']) ?? 'Ground';
    final String location =
        _stringFromAny(map, <String>['location', 'address', 'city']) ??
        fallbackLocation;
    final String image = _groundImageFromAny(map) ?? '';
    final double rating =
        _doubleFromAny(map, <String>['rating', 'groundRating']) ?? 0;

    final List<String> facilities = _facilitiesFromAny(map);
    final String? priceText = _priceText(map);

    return _NearbyGroundItem(
      name: name,
      location: location,
      image: image,
      rating: rating,
      facilities: facilities.isEmpty
          ? const <String>['No facility details']
          : facilities,
      price: priceText ?? 'N/A',
    );
  }

  static String? _priceText(Map<String, dynamic> item) {
    final double? hourly = _doubleFromAny(item, <String>[
      'hourlyPrice',
      'pricePerHour',
      'hourlyRate',
      'price',
    ]);
    if (hourly == null) {
      return null;
    }
    return 'Rs ${hourly.toStringAsFixed(hourly % 1 == 0 ? 0 : 2)}/hr';
  }

  static List<String> _facilitiesFromAny(Map<String, dynamic> item) {
    final dynamic raw = item['facilities'];
    if (raw is List) {
      return raw
          .map((dynamic value) => value.toString().trim())
          .where((String text) => text.isNotEmpty)
          .take(4)
          .toList();
    }
    final String? one = _stringFromAny(item, <String>['detail', 'feature']);
    if (one != null && one.isNotEmpty) {
      return <String>[one];
    }
    return <String>[];
  }

  static String? _groundImageFromAny(Map<String, dynamic> item) {
    final dynamic groundImages = item['groundImages'];
    if (groundImages is List && groundImages.isNotEmpty) {
      final dynamic first = groundImages.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map) {
        final String url = first['url']?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          return url;
        }
      }
    }

    final String image = item['image']?.toString().trim() ?? '';
    if (image.isNotEmpty) {
      return image;
    }

    final String imageUrl = item['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final dynamic photos = item['photos'];
    if (photos is List && photos.isNotEmpty) {
      final dynamic first = photos.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map) {
        return first['url']?.toString();
      }
    }

    return null;
  }

  static String? _stringFromAny(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = map[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static double? _doubleFromAny(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
        final double? parsed = double.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
