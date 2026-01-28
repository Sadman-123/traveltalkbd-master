import 'package:firebase_database/firebase_database.dart';

class HomeSettingsService {
  static Future<List<String>> getSlogans() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('home_settings').child('slogans').get();
      if (!snapshot.exists) {
        // Return default slogans if none exist
        return [
          "Discover Your Next Adventure",
          "Travel Beyond Imagination",
          "Create Memories That Last Forever",
          "Your Journey Starts Here",
          "Explore the World with Us",
        ];
      }

      final raw = snapshot.value;
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      
      // Return default slogans if data format is invalid
      return [
        "Discover Your Next Adventure",
        "Travel Beyond Imagination",
        "Create Memories That Last Forever",
        "Your Journey Starts Here",
        "Explore the World with Us",
      ];
    } catch (e) {
      // Return default slogans on error
      return [
        "Discover Your Next Adventure",
        "Travel Beyond Imagination",
        "Create Memories That Last Forever",
        "Your Journey Starts Here",
        "Explore the World with Us",
      ];
    }
  }

  static Future<String> getBackgroundImage() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('home_settings').child('backgroundImage').get();
      if (!snapshot.exists) {
        // Return default background image URL
        return 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800';
      }

      final value = snapshot.value;
      if (value is String && value.isNotEmpty) {
        return value;
      }
      
      // Return default background image URL if invalid
      return 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800';
    } catch (e) {
      // Return default background image URL on error
      return 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800';
    }
  }

  static Future<void> saveSlogans(List<String> slogans) async {
    try {
      await FirebaseDatabase.instance.ref().child('home_settings').child('slogans').set(slogans);
    } catch (e) {
      throw Exception('Failed to save slogans: $e');
    }
  }

  static Future<void> saveBackgroundImage(String imageUrl) async {
    try {
      await FirebaseDatabase.instance.ref().child('home_settings').child('backgroundImage').set(imageUrl);
    } catch (e) {
      throw Exception('Failed to save background image: $e');
    }
  }
}
