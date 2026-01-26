import 'package:firebase_database/firebase_database.dart';
import 'travel_models.dart';

class TravelDataService {
  static Future<TravelContent>? _cachedContent;

  static Future<TravelContent> getContent() {
    _cachedContent ??= _fetchContent();
    return _cachedContent!;
  }

  static void clearCache() {
    _cachedContent = null;
  }

  static Future<TravelContent> _fetchContent() async {
    final snapshot = await FirebaseDatabase.instance.ref().get();
    final raw = snapshot.value as Map<dynamic, dynamic>?;
    if (raw == null) {
      return TravelContent(
        tourPackages: {},
        visaPackages: {},
        destinations: {},
        aboutInfo: null,
      );
    }

    final tourPackages = <String, TourPackage>{};
    final visaPackages = <String, VisaPackage>{};
    final destinations = <String, Destination>{};

    final toursMap = Map<String, dynamic>.from(raw['tour_packages'] ?? {});
    for (final entry in toursMap.entries) {
      tourPackages[entry.key] =
          TourPackage.fromMap(entry.key, Map<String, dynamic>.from(entry.value));
    }

    final visasMap = Map<String, dynamic>.from(raw['visa_packages'] ?? {});
    for (final entry in visasMap.entries) {
      visaPackages[entry.key] =
          VisaPackage.fromMap(entry.key, Map<String, dynamic>.from(entry.value));
    }

    final destMap = Map<String, dynamic>.from(raw['destinations'] ?? {});
    for (final entry in destMap.entries) {
      destinations[entry.key] =
          Destination.fromMap(entry.key, Map<String, dynamic>.from(entry.value));
    }

    AboutInfo? aboutInfo;
    if (raw['about_us'] != null) {
      aboutInfo = AboutInfo.fromMap(
        Map<String, dynamic>.from(raw['about_us']),
      );
    }

    return TravelContent(
      tourPackages: tourPackages,
      visaPackages: visaPackages,
      destinations: destinations,
      aboutInfo: aboutInfo,
    );
  }

  static List<SearchItem> buildSearchItems(TravelContent content) {
    final items = <SearchItem>[];

    for (final pkg in content.tourPackages.values) {
      items.add(
        SearchItem(
          id: pkg.id,
          title: pkg.title,
          subtitle: '${pkg.city}, ${pkg.country}',
          type: 'tour',
          imageUrl: pkg.photo,
          payload: pkg,
        ),
      );
    }

    for (final visa in content.visaPackages.values) {
      items.add(
        SearchItem(
          id: visa.id,
          title: visa.title,
          subtitle: visa.country,
          type: 'visa',
          imageUrl: visa.photo,
          payload: visa,
        ),
      );
    }

    for (final dest in content.destinations.values) {
      items.add(
        SearchItem(
          id: dest.id,
          title: dest.name,
          subtitle: dest.country,
          type: 'destination',
          imageUrl: dest.photo,
          payload: dest,
        ),
      );
    }

    return items;
  }
}
