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
  });

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
  });

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
  });

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
    );
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
  });

  factory AboutInfo.fromMap(Map<String, dynamic> map) {
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
