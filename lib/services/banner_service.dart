import 'package:firebase_database/firebase_database.dart';

class Banner {
  final String id;
  final String type; // 'image' or 'text'
  final String? imageUrl;
  final String? heading;
  final String? subtext;
  final String createdAt;

  Banner({
    required this.id,
    required this.type,
    this.imageUrl,
    this.heading,
    this.subtext,
    required this.createdAt,
  });

  factory Banner.fromMap(String id, Map<String, dynamic> map) {
    return Banner(
      id: id,
      type: map['type'] ?? 'image',
      imageUrl: map['imageUrl'],
      heading: map['heading'],
      subtext: map['subtext'],
      createdAt: map['createdAt'] ?? '',
    );
  }
}

class BannerService {
  static Future<List<Banner>> getBanners() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('banners').get();
      if (!snapshot.exists) {
        return [];
      }

      final raw = snapshot.value;
      if (raw is! Map) {
        return [];
      }

      final banners = <Banner>[];
      raw.forEach((key, value) {
        if (value is Map) {
          try {
            banners.add(Banner.fromMap(
              key.toString(),
              Map<String, dynamic>.from(
                value.map((k, v) => MapEntry(k.toString(), v)),
              ),
            ));
          } catch (e) {
            // Skip invalid banner entries
          }
        }
      });

      return banners;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> shouldShowPromotions() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('settings').child('showPromotions').get();
      if (!snapshot.exists) return true;
      final value = snapshot.value;
      if (value is bool) return value;
      return true; // Default to showing promotions
    } catch (e) {
      return true; // Default to showing promotions
    }
  }
}
