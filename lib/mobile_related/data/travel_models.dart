class TourPackage {
  final String id;
  final String title;
  final String country;
  final String city;
  final String duration;
  final num price;
  final String currency;
  final double rating;
  final String photo; // First photo (for backward compatibility)
  final List<String> photos; // All photos
  final bool available;
  final bool discountEnabled;
  final num discountAmount;
  final num discountPercent;

  TourPackage({
    required this.id,
    required this.title,
    required this.country,
    required this.city,
    required this.duration,
    required this.price,
    required this.currency,
    required this.rating,
    required this.photo,
    required this.photos,
    required this.available,
    this.discountEnabled = false,
    this.discountAmount = 0,
    this.discountPercent = 0,
  });

  num get discountedPrice {
    if (!discountEnabled) return price;
    if (discountPercent > 0) {
      return (price * (1 - discountPercent / 100)).clamp(0, double.infinity);
    }
    return (price - discountAmount).clamp(0, double.infinity);
  }

  factory TourPackage.fromMap(String id, Map<String, dynamic> map) {
    // Handle photo as either String or List<String>
    final photoValue = map['photo'];
    List<String> photosList;
    String firstPhoto;
    
    if (photoValue is List) {
      photosList = List<String>.from(photoValue);
      firstPhoto = photosList.isNotEmpty ? photosList[0] : '';
    } else if (photoValue is String) {
      firstPhoto = photoValue;
      photosList = [firstPhoto];
    } else {
      firstPhoto = '';
      photosList = [];
    }
    
    return TourPackage(
      id: id,
      title: map['title'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      duration: map['duration'] ?? '',
      price: map['price'] ?? 0,
      currency: map['currency'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      photo: firstPhoto,
      photos: photosList,
      available: map['available'] ?? false,
      discountEnabled: map['discountEnabled'] ?? false,
      discountAmount: map['discountAmount'] ?? 0,
      discountPercent: map['discountPercent'] ?? 0,
    );
  }
}

/// Entry type option for visa (single, double, multiple entry)
class VisaEntryTypeOption {
  final bool enabled;
  final num price;

  VisaEntryTypeOption({required this.enabled, required this.price});

  Map<String, dynamic> toMap() => {'enabled': enabled, 'price': price};

  factory VisaEntryTypeOption.fromMap(Map<String, dynamic> map) =>
      VisaEntryTypeOption(
        enabled: map['enabled'] ?? false,
        price: map['price'] ?? 0,
      );
}

class VisaPackage {
  final String id;
  final String title;
  final String country;
  final String visaType;
  final String validity;
  final String processingTime;
  final num price;
  final String currency;
  final String photo; // First photo (for backward compatibility)
  final List<String> photos; // All photos
  final List<String> requiredDocuments;
  final bool available;
  final bool discountEnabled;
  final num discountAmount;
  final num discountPercent;
  /// Entry types: singleEntry, doubleEntry, multipleEntry - each with enabled & price
  final Map<String, VisaEntryTypeOption> entryTypes;

  VisaPackage({
    required this.id,
    required this.title,
    required this.country,
    required this.visaType,
    required this.validity,
    required this.processingTime,
    required this.price,
    required this.currency,
    required this.photo,
    required this.photos,
    required this.requiredDocuments,
    required this.available,
    this.discountEnabled = false,
    this.discountAmount = 0,
    this.discountPercent = 0,
    Map<String, VisaEntryTypeOption>? entryTypes,
  }) : entryTypes = entryTypes ?? {};

  num get discountedPrice {
    if (!discountEnabled) return price;
    if (discountPercent > 0) {
      return (price * (1 - discountPercent / 100)).clamp(0, double.infinity);
    }
    return (price - discountAmount).clamp(0, double.infinity);
  }

  /// Whether this visa uses entry-type pricing (has at least one enabled entry type)
  bool get hasEntryTypes => enabledEntryTypes.isNotEmpty;

  /// Enabled entry types only
  List<MapEntry<String, VisaEntryTypeOption>> get enabledEntryTypes {
    return entryTypes.entries.where((e) => e.value.enabled).toList();
  }

  /// Enabled entry types sorted by price (lowest to highest)
  List<MapEntry<String, VisaEntryTypeOption>> get sortedEnabledEntryTypes {
    final list = enabledEntryTypes.toList();
    list.sort((a, b) => a.value.price.compareTo(b.value.price));
    return list;
  }

  static String formatEntryTypeLabel(String key) {
    switch (key) {
      case 'singleEntry': return 'Single Entry';
      case 'doubleEntry': return 'Double Entry';
      case 'multipleEntry': return 'Multiple Entry';
      default: return key;
    }
  }

  /// Lowest price among enabled entry types (with discount applied), or legacy price if none
  num get displayPrice {
    if (hasEntryTypes) {
      final prices = enabledEntryTypes.map((e) => e.value.price).toList();
      final lowest = prices.reduce((a, b) => a < b ? a : b);
      if (discountEnabled && discountPercent > 0) {
        return (lowest * (1 - discountPercent / 100)).clamp(0, double.infinity);
      }
      if (discountEnabled && discountAmount > 0) {
        return (lowest - discountAmount).clamp(0, double.infinity);
      }
      return lowest;
    }
    return discountEnabled ? discountedPrice : price;
  }

  /// Price text for cards: "From X" if multiple entry types, else single price
  String priceDisplayText(String currency) {
    if (!hasEntryTypes) {
      return '$currency ${discountEnabled ? discountedPrice.toStringAsFixed(0) : price}';
    }
    final count = enabledEntryTypes.length;
    final lowest = displayPrice;
    return count > 1 ? 'From $currency ${lowest.toStringAsFixed(0)}' : '$currency ${lowest.toStringAsFixed(0)}';
  }

  factory VisaPackage.fromMap(String id, Map<String, dynamic> map) {
    // Handle photo as either String or List<String>
    final photoValue = map['photo'];
    List<String> photosList;
    String firstPhoto;

    if (photoValue is List) {
      photosList = List<String>.from(photoValue);
      firstPhoto = photosList.isNotEmpty ? photosList[0] : '';
    } else if (photoValue is String) {
      firstPhoto = photoValue;
      photosList = [firstPhoto];
    } else {
      firstPhoto = '';
      photosList = [];
    }

    // Safe extraction - Firebase returns Map<dynamic, dynamic>, not Map<String, dynamic>
    final entryTypesRaw = map['entryTypes'];
    final Map<String, VisaEntryTypeOption> entryTypesMap = {};
    if (entryTypesRaw != null && entryTypesRaw is Map) {
      final et = Map<String, dynamic>.from(entryTypesRaw);
      for (final e in et.entries) {
        if (e.value is Map) {
          entryTypesMap[e.key] = VisaEntryTypeOption.fromMap(
            Map<String, dynamic>.from(e.value as Map),
          );
        }
      }
    }

    return VisaPackage(
      id: id,
      title: map['title'] ?? '',
      country: map['country'] ?? '',
      visaType: map['visaType'] ?? '',
      validity: map['validity'] ?? '',
      processingTime: map['processingTime'] ?? '',
      price: map['price'] ?? 0,
      currency: map['currency'] ?? '',
      photo: firstPhoto,
      photos: photosList,
      requiredDocuments: List<String>.from(map['requiredDocuments'] ?? const []),
      available: map['available'] ?? false,
      discountEnabled: map['discountEnabled'] ?? false,
      discountAmount: map['discountAmount'] ?? 0,
      discountPercent: map['discountPercent'] ?? 0,
      entryTypes: entryTypesMap,
    );
  }
}

class Destination {
  final String id;
  final String name;
  final String country;
  final String continent;
  final String shortDescription;
  final String bestTimeToVisit;
  final num startingPrice;
  final String currency;
  final String photo; // First photo (for backward compatibility)
  final List<String> photos; // All photos
  final List<String> popularFor;
  final bool available;
  final bool discountEnabled;
  final num discountAmount;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.continent,
    required this.shortDescription,
    required this.bestTimeToVisit,
    required this.startingPrice,
    required this.currency,
    required this.photo,
    required this.photos,
    required this.popularFor,
    required this.available,
    this.discountEnabled = false,
    this.discountAmount = 0,
  });

  num get discountedStartingPrice => discountEnabled ? (startingPrice - discountAmount).clamp(0, double.infinity) : startingPrice;

  factory Destination.fromMap(String id, Map<String, dynamic> map) {
    // Handle photo as either String or List<String>
    final photoValue = map['photo'];
    List<String> photosList;
    String firstPhoto;
    
    if (photoValue is List) {
      photosList = List<String>.from(photoValue);
      firstPhoto = photosList.isNotEmpty ? photosList[0] : '';
    } else if (photoValue is String) {
      firstPhoto = photoValue;
      photosList = [firstPhoto];
    } else {
      firstPhoto = '';
      photosList = [];
    }
    
    return Destination(
      id: id,
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      continent: map['continent'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      bestTimeToVisit: map['bestTimeToVisit'] ?? '',
      startingPrice: map['startingPrice'] ?? 0,
      currency: map['currency'] ?? '',
      photo: firstPhoto,
      photos: photosList,
      popularFor: List<String>.from(map['popularFor'] ?? const []),
      available: map['available'] ?? false,
      discountEnabled: map['discountEnabled'] ?? false,
      discountAmount: map['discountAmount'] ?? 0,
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String designation;
  final String pictureUrl;
  final String quote;
  final String experience; // Years of experience or experience description
  final int rank; // Order in which they were added (1 = highest/lead)

  Employee({
    required this.id,
    required this.name,
    required this.designation,
    required this.pictureUrl,
    required this.quote,
    required this.experience,
    required this.rank,
  });

  factory Employee.fromMap(String id, Map<String, dynamic> map) {
    return Employee(
      id: id,
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      pictureUrl: map['pictureUrl'] ?? '',
      quote: map['quote'] ?? '',
      experience: map['experience'] ?? '',
      rank: map['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'pictureUrl': pictureUrl,
      'quote': quote,
      'experience': experience,
      'rank': rank,
    };
  }
}

class AboutInfo {
  final String companyName;
  final String tagline;
  final String description;
  final String mission;
  final String vision;
  final List<String> whyChooseUs;
  final List<String> services;
  final Map<String, dynamic> contact;
  final Map<String, dynamic> socialLinks;
  final int establishedYear;
  final double rating;
  final List<String> documents; // List of document URLs or names
  final Map<String, Employee> employees; // Map of employee ID to Employee

  AboutInfo({
    required this.companyName,
    required this.tagline,
    required this.description,
    required this.mission,
    required this.vision,
    required this.whyChooseUs,
    required this.services,
    required this.contact,
    required this.socialLinks,
    required this.establishedYear,
    required this.rating,
    required this.documents,
    required this.employees,
  });

  factory AboutInfo.fromMap(Map<String, dynamic> map) {
    // Parse documents
    final documentsList = <String>[];
    if (map['documents'] != null) {
      if (map['documents'] is List) {
        documentsList.addAll(List<String>.from(map['documents']));
      } else if (map['documents'] is Map) {
        // If documents is a map, extract values
        documentsList.addAll((map['documents'] as Map).values.map((e) => e.toString()));
      }
    }

    // Parse employees
    final employeesMap = <String, Employee>{};
    if (map['employees'] != null && map['employees'] is Map) {
      final employeesData = Map<String, dynamic>.from(map['employees']);
      for (final entry in employeesData.entries) {
        employeesMap[entry.key] = Employee.fromMap(entry.key, Map<String, dynamic>.from(entry.value));
      }
    }

    return AboutInfo(
      companyName: map['companyName'] ?? '',
      tagline: map['tagline'] ?? '',
      description: map['description'] ?? '',
      mission: map['mission'] ?? '',
      vision: map['vision'] ?? '',
      whyChooseUs: List<String>.from(map['whyChooseUs'] ?? const []),
      services: List<String>.from(map['services'] ?? const []),
      contact: Map<String, dynamic>.from(map['contact'] ?? const {}),
      socialLinks: Map<String, dynamic>.from(map['socialLinks'] ?? const {}),
      establishedYear: map['establishedYear'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      documents: documentsList,
      employees: employeesMap,
    );
  }
}

class TravelContent {
  final Map<String, TourPackage> tourPackages;
  final Map<String, VisaPackage> visaPackages;
  final Map<String, Destination> destinations;
  final AboutInfo? aboutInfo;

  TravelContent({
    required this.tourPackages,
    required this.visaPackages,
    required this.destinations,
    required this.aboutInfo,
  });
}

class SearchItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String? imageUrl;
  final dynamic payload;

  SearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.imageUrl,
    this.payload,
  });
}
