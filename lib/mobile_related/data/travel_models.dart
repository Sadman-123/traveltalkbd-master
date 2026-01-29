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
  });

  num get discountedPrice => discountEnabled ? (price - discountAmount).clamp(0, double.infinity) : price;

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
    );
  }
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
  });

  num get discountedPrice => discountEnabled ? (price - discountAmount).clamp(0, double.infinity) : price;

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
