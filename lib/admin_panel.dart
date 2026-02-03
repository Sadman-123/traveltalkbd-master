import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:traveltalkbd/app_splash_gate.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/services/cloudinary_service.dart';
import 'package:traveltalkbd/services/home_settings_service.dart';
import 'package:traveltalkbd/screens/admin/admin_chat_tab.dart';
import 'package:http/http.dart' as http;

// Conditional import for download functionality
// Use web_download on web, mobile_download on mobile
import 'utils/web_download.dart' if (dart.library.io) 'utils/mobile_download.dart' as download_util;

// Platform-agnostic image data class
class _PickedImage {
  final File? file;
  final Uint8List? bytes;
  final String? name;

  _PickedImage({this.file, this.bytes, this.name});

  bool get isWeb => kIsWeb;
}

/// Helper model used inside the visa package dialog for editing documents
class _AdminVisaDocument {
  final TextEditingController titleController;
  final TextEditingController subtitlesController;

  _AdminVisaDocument({
    String title = '',
    List<String>? subtitles,
  })  : titleController = TextEditingController(text: title),
        subtitlesController = TextEditingController(
          text: (subtitles ?? const []).join(', '),
        );

  factory _AdminVisaDocument.fromMap(Map<String, dynamic> map) {
    final rawSubs = map['subtitles'];
    final subtitles = rawSubs is List
        ? List<String>.from(rawSubs.where((e) => e is String))
        : const <String>[];
    return _AdminVisaDocument(
      title: (map['title'] ?? '') as String,
      subtitles: subtitles,
    );
  }

  Map<String, dynamic> toMap() {
    final rawSubtitles = subtitlesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return {
      'title': titleController.text.trim(),
      'subtitles': rawSubtitles,
    };
  }

  bool get isEmpty => titleController.text.trim().isEmpty;
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late final Future<void> _preloadFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    // Preload the whole database snapshot once so the splash stays
    // until Firebase data is ready.
    _preloadFuture = FirebaseDatabase.instance.ref().get().then((_) {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSplashGate(
      loadFuture: _preloadFuture,
      child: Scaffold(
      appBar: AppBar(
         flexibleSpace: Container(
    decoration:  BoxDecoration(
     gradient: Traveltalktheme.primaryGradient
    ),
  ),
        centerTitle: false,
        title: SvgPicture.asset('assets/logo.svg',height: 100,width: 150,color: Colors.white,),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await AuthService().signOut();
                Get.offAllNamed('/');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.location_on), text: 'Destinations'),
            Tab(icon: Icon(Icons.flight), text: 'Tour Packages'),
            Tab(icon: Icon(Icons.article), text: 'Visa Packages'),
            Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
            Tab(icon: Icon(Icons.campaign), text: 'Banners/Promotions'),
            Tab(icon: Icon(Icons.info), text: 'About Us'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeTab(dbRef: _dbRef),
          DestinationsTab(dbRef: _dbRef),
          TourPackagesTab(dbRef: _dbRef),
          VisaPackagesTab(dbRef: _dbRef),
          BookingsTab(dbRef: _dbRef),
          BannersTab(dbRef: _dbRef),
          AboutUsTab(dbRef: _dbRef),
          const AdminChatTab(),
        ],
      ),
      ),
    );
  }
}

// ==================== HOME TAB ====================
class HomeTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const HomeTab({super.key, required this.dbRef});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<String> _slogans = [];
  String _backgroundImage = '';
  bool _isLoading = true;
  final TextEditingController _backgroundImageController = TextEditingController();
  final List<TextEditingController> _sloganControllers = [];
  final selectedImage = ValueNotifier<_PickedImage?>(null);
  final isUploading = ValueNotifier<bool>(false);
  StreamSubscription<DatabaseEvent>? _homeSettingsSub;

  @override
  void initState() {
    super.initState();
    _loadHomeSettings();
    // Listen for real-time updates
    _homeSettingsSub = widget.dbRef.child('home_settings').onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        _loadHomeSettings();
      }
    });
  }

  @override
  void dispose() {
    _homeSettingsSub?.cancel();
    _backgroundImageController.dispose();
    for (var controller in _sloganControllers) {
      controller.dispose();
    }
    selectedImage.dispose();
    isUploading.dispose();
    super.dispose();
  }

  Future<void> _loadHomeSettings() async {
    try {
      final slogans = await HomeSettingsService.getSlogans();
      final backgroundImage = await HomeSettingsService.getBackgroundImage();
      
      if (mounted) {
        setState(() {
          _slogans = slogans;
          _backgroundImage = backgroundImage;
          _backgroundImageController.text = backgroundImage;
          _isLoading = false;
          
          // Dispose old controllers
          for (var controller in _sloganControllers) {
            controller.dispose();
          }
          _sloganControllers.clear();
          
          // Create new controllers for slogans
          for (var slogan in _slogans) {
            _sloganControllers.add(TextEditingController(text: slogan));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading home settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSlogans() async {
    try {
      final slogans = _sloganControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      if (slogans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one slogan')),
        );
        return;
      }
      await HomeSettingsService.saveSlogans(slogans);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slogans saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving slogans: $e')),
        );
      }
    }
  }

  Future<void> _saveBackgroundImage() async {
    try {
      String imageUrl = _backgroundImageController.text.trim();
      
      // If an image was picked, upload it first
      if (selectedImage.value != null) {
        isUploading.value = true;
        try {
          if (kIsWeb && selectedImage.value!.bytes != null) {
            imageUrl = await CloudinaryService.uploadImageFromBytes(
              selectedImage.value!.bytes!,
              selectedImage.value!.name ?? 'home_bg_${DateTime.now().millisecondsSinceEpoch}',
              folder: 'home',
            );
          } else if (selectedImage.value!.file != null) {
            imageUrl = await CloudinaryService.uploadImage(
              selectedImage.value!.file!,
              folder: 'home',
            );
          }
          
          if (imageUrl.isEmpty) {
            throw Exception('Failed to upload image');
          }
          
          selectedImage.value = null;
        } finally {
          isUploading.value = false;
        }
      }
      
      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a background image URL or upload an image')),
        );
        return;
      }
      
      await HomeSettingsService.saveBackgroundImage(imageUrl);
      if (mounted) {
        setState(() {
          _backgroundImage = imageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background image saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving background image: $e')),
        );
      }
    }
  }

  void _addSlogan() {
    setState(() {
      _sloganControllers.add(TextEditingController());
    });
  }

  void _removeSlogan(int index) {
    if (index < _sloganControllers.length) {
      _sloganControllers[index].dispose();
      setState(() {
        _sloganControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Background Image Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background Image',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Preview
                  if (_backgroundImage.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _backgroundImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, size: 48),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  // Image Upload or URL Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _backgroundImageController,
                          decoration: const InputDecoration(
                            labelText: 'Background Image URL',
                            hintText: 'Enter image URL or upload image',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<_PickedImage?>(
                        valueListenable: selectedImage,
                        builder: (context, image, _) {
                          return Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  _PickedImage? picked;
                                  if (kIsWeb) {
                                    final result = await picker.pickImage(source: ImageSource.gallery);
                                    if (result != null) {
                                      final bytes = await result.readAsBytes();
                                      picked = _PickedImage(bytes: bytes, name: result.name);
                                    }
                                  } else {
                                    final result = await picker.pickImage(source: ImageSource.gallery);
                                    if (result != null) {
                                      picked = _PickedImage(file: File(result.path));
                                    }
                                  }
                                  if (picked != null) {
                                    selectedImage.value = picked;
                                  }
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload'),
                              ),
                              if (image != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: kIsWeb && image.bytes != null
                                            ? Image.memory(image.bytes!, fit: BoxFit.cover)
                                            : image.file != null
                                                ? Image.file(image.file!, fit: BoxFit.cover)
                                                : const Icon(Icons.image),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () => selectedImage.value = null,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: isUploading,
                    builder: (context, uploading, _) {
                      return ElevatedButton(
                        onPressed: uploading ? null : _saveBackgroundImage,
                        child: uploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Background Image'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Slogans Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Slogans',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addSlogan,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Slogan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_sloganControllers.isEmpty)
                    const Text('No slogans added yet. Click "Add Slogan" to add one.')
                  else
                    ..._sloganControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Slogan ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSlogan(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveSlogans,
                    child: const Text('Save Slogans'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DESTINATIONS TAB ====================
class DestinationsTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const DestinationsTab({super.key, required this.dbRef});

  @override
  State<DestinationsTab> createState() => _DestinationsTabState();
}

class _DestinationsTabState extends State<DestinationsTab> {
  Map<String, dynamic> _destinations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    try {
      final snapshot = await widget.dbRef.child('destinations').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final raw = snapshot.value;
          if (raw is Map) {
            _destinations = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading destinations: $e')),
        );
      }
    }
  }

  Future<void> _deleteDestination(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Destination'),
        content: const Text('Are you sure you want to delete this destination?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.dbRef.child('destinations').child(id).remove();
        _loadDestinations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destination deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting destination: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Destinations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showDestinationDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Destination'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _destinations.isEmpty
              ? const Center(child: Text('No destinations found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _destinations.length,
                  itemBuilder: (context, index) {
                    final entry = _destinations.entries.elementAt(index);
                    final dest = Map<String, dynamic>.from(
                      entry.value is Map
                          ? (entry.value as Map).map((k, v) => MapEntry(k.toString(), v))
                          : {},
                    );
                    return _DestinationCard(
                      id: entry.key,
                      destination: dest,
                      onEdit: () => _showDestinationDialog(id: entry.key, data: dest),
                      onDelete: () => _deleteDestination(entry.key),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDestinationDialog({String? id, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final countryController = TextEditingController(text: data?['country'] ?? '');
    final continentController = TextEditingController(text: data?['continent'] ?? '');
    final currencyController = TextEditingController(text: data?['currency'] ?? 'BDT');
    final shortDescController = TextEditingController(text: data?['shortDescription'] ?? '');
    final bestTimeController = TextEditingController(text: data?['bestTimeToVisit'] ?? '');
    final startingPriceController = TextEditingController(text: data?['startingPrice']?.toString() ?? '');
    final availableController = ValueNotifier<bool>(data?['available'] ?? true);
    final discountEnabledController = ValueNotifier<bool>(data?['discountEnabled'] ?? false);
    final discountAmountController = TextEditingController(text: data?['discountAmount']?.toString() ?? '0');
    final popularForController = TextEditingController(
      text: (data?['popularFor'] as List?)?.join(', ') ?? '',
    );
    
    // Handle images - can be single URL string or list of URLs
    List<String> imageUrls = [];
    if (data?['photo'] != null) {
      if (data!['photo'] is List) {
        imageUrls = List<String>.from(data['photo']);
      } else if (data['photo'] is String) {
        imageUrls = [data['photo']];
      }
    }
    
    final selectedImages = ValueNotifier<List<_PickedImage>>([]);
    final existingImageUrls = ValueNotifier<List<String>>(imageUrls);
    final isUploading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          id == null ? 'Add Destination' : 'Edit Destination',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(labelText: 'Country *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: continentController,
                    decoration: const InputDecoration(labelText: 'Continent *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Images *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<_PickedImage>>(
                    valueListenable: selectedImages,
                    builder: (context, pickedImages, _) {
                      return ValueListenableBuilder<List<String>>(
                        valueListenable: existingImageUrls,
                        builder: (context, urls, _) {
                          final totalImages = pickedImages.length + urls.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  try {
                                    final List<XFile> pickedFiles = await picker.pickMultiImage();
                                    if (pickedFiles.isNotEmpty) {
                                    final List<_PickedImage> images = [];
                                    for (final xFile in pickedFiles) {
                                      if (kIsWeb) {
                                        final bytes = await xFile.readAsBytes();
                                        // Ensure filename has extension
                                        String fileName = xFile.name;
                                        if (!fileName.contains('.')) {
                                          // Try to detect from mime type or default to jpg
                                          fileName = '${xFile.name}.jpg';
                                        }
                                        images.add(_PickedImage(
                                          bytes: bytes,
                                          name: fileName,
                                        ));
                                      } else {
                                        images.add(_PickedImage(
                                          file: File(xFile.path),
                                          name: xFile.name.isNotEmpty ? xFile.name : xFile.path.split('/').last,
                                        ));
                                      }
                                    }
                                      selectedImages.value = images;
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error picking images: $e')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Pick Images'),
                              ),
                              if (totalImages > 0) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Show existing URLs
                                    ...urls.map((url) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () {
                                              existingImageUrls.value = urls.where((u) => u != url).toList();
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                    // Show selected files
                                    ...pickedImages.map((pickedImage) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: kIsWeb && pickedImage.bytes != null
                                                ? Image.memory(
                                                    pickedImage.bytes!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : pickedImage.file != null
                                                    ? Image.file(
                                                        pickedImage.file!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () {
                                              selectedImages.value = pickedImages.where((img) => img != pickedImage).toList();
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: shortDescController,
                    decoration: const InputDecoration(labelText: 'Short Description *'),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: bestTimeController,
                    decoration: const InputDecoration(labelText: 'Best Time to Visit'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: startingPriceController,
                    decoration: const InputDecoration(labelText: 'Starting Price *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: popularForController,
                    decoration: const InputDecoration(
                      labelText: 'Popular For (comma separated)',
                      hintText: 'Beach, Shopping, Food',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: discountEnabledController,
                    builder: (context, discountEnabled, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Discount'),
                          subtitle: const Text('Enable discount for this destination'),
                          value: discountEnabled,
                          onChanged: (v) {
                            discountEnabledController.value = v;
                            setDialogState(() {});
                          },
                        ),
                        if (discountEnabled)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: TextFormField(
                              controller: discountAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Discount Amount',
                                hintText: 'Amount to subtract from price',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: availableController,
                    builder: (context, available, _) => SwitchListTile(
                      title: const Text('Available'),
                      value: available,
                      onChanged: (v) {
                        availableController.value = v;
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: isUploading,
                        builder: (context, uploading, _) {
                          return ElevatedButton(
                            onPressed: uploading ? null : () async {
                              if (formKey.currentState!.validate()) {
                                final selectedFiles = selectedImages.value;
                                final existingUrls = existingImageUrls.value;
                                
                                if (selectedFiles.isEmpty && existingUrls.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select at least one image')),
                                  );
                                  return;
                                }

                                isUploading.value = true;
                                
                                try {
                                  // Upload new images to Cloudinary
                                  List<String> uploadedUrls = [];
                                  if (selectedFiles.isNotEmpty) {
                                    for (final pickedImage in selectedFiles) {
                                      String url;
                                      if (kIsWeb && pickedImage.bytes != null) {
                                        url = await CloudinaryService.uploadImageFromBytes(
                                          pickedImage.bytes!,
                                          pickedImage.name ?? 'image_${DateTime.now().millisecondsSinceEpoch}',
                                          folder: 'destinations',
                                        );
                                      } else if (pickedImage.file != null) {
                                        url = await CloudinaryService.uploadImage(
                                          pickedImage.file!,
                                          folder: 'destinations',
                                        );
                                      } else {
                                        continue;
                                      }
                                      uploadedUrls.add(url);
                                    }
                                  }
                                  
                                  // Combine existing URLs with newly uploaded URLs
                                  final allImageUrls = [...existingUrls, ...uploadedUrls];
                                  
                                  final popularFor = popularForController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();

                                  final destinationData = {
                                    'name': nameController.text,
                                    'country': countryController.text,
                                    'continent': continentController.text,
                                    'currency': currencyController.text,
                                    'photo': allImageUrls.length == 1 ? allImageUrls.first : allImageUrls,
                                    'shortDescription': shortDescController.text,
                                    'bestTimeToVisit': bestTimeController.text,
                                    'startingPrice': int.tryParse(startingPriceController.text) ?? 0,
                                    'popularFor': popularFor,
                                    'available': availableController.value,
                                    'discountEnabled': discountEnabledController.value,
                                    'discountAmount': num.tryParse(discountAmountController.text) ?? 0,
                                  };

                                  if (id == null) {
                                    // Generate new ID
                                    final newId = 'dest_${DateTime.now().millisecondsSinceEpoch}';
                                    await widget.dbRef.child('destinations').child(newId).set(destinationData);
                                  } else {
                                    await widget.dbRef.child('destinations').child(id).update(destinationData);
                                  }
                                  Navigator.pop(context);
                                  _loadDestinations();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(id == null ? 'Destination added!' : 'Destination updated!')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final errorMessage = e.toString();
                                    print('Upload error details: $errorMessage'); // Debug print
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $errorMessage'),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } finally {
                                  isUploading.value = false;
                                }
                              }
                            },
                            child: uploading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DestinationCard({
    required this.id,
    required this.destination,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildImageWidget(dynamic photo, {double? width, double? height}) {
    String? imageUrl;
    if (photo is List && photo.isNotEmpty) {
      imageUrl = photo.first.toString();
    } else if (photo is String) {
      imageUrl = photo;
    }
    
    return Image.network(
      imageUrl ?? '',
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(
                destination['photo'],
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination['name'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(destination['available'] == true ? 'Available' : 'Unavailable'),
                        backgroundColor: destination['available'] == true ? Colors.green[100] : Colors.red[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${destination['country']}, ${destination['continent']}'),
                  const SizedBox(height: 4),
                  Text(
                    destination['shortDescription'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${destination['currency']} ${destination['startingPrice']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: onEdit,
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDelete,
                        color: Colors.red,
                      ),
                    ],
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

// ==================== TOUR PACKAGES TAB ====================
class TourPackagesTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const TourPackagesTab({super.key, required this.dbRef});

  @override
  State<TourPackagesTab> createState() => _TourPackagesTabState();
}

class _TourPackagesTabState extends State<TourPackagesTab> {
  Map<String, dynamic> _tours = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      final snapshot = await widget.dbRef.child('tour_packages').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final raw = snapshot.value;
          if (raw is Map) {
            _tours = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tours: $e')),
        );
      }
    }
  }

  Future<void> _deleteTour(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tour Package'),
        content: const Text('Are you sure you want to delete this tour package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.dbRef.child('tour_packages').child(id).remove();
        _loadTours();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tour package deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting tour: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tour Packages',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showTourDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Tour Package'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tours.isEmpty
              ? const Center(child: Text('No tour packages found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tours.length,
                  itemBuilder: (context, index) {
                    final entry = _tours.entries.elementAt(index);
                    final tour = Map<String, dynamic>.from(
                      entry.value is Map
                          ? (entry.value as Map).map((k, v) => MapEntry(k.toString(), v))
                          : {},
                    );
                    return _TourCard(
                      id: entry.key,
                      tour: tour,
                      onEdit: () => _showTourDialog(id: entry.key, data: tour),
                      onDelete: () => _deleteTour(entry.key),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTourDialog({String? id, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final cityController = TextEditingController(text: data?['city'] ?? '');
    final countryController = TextEditingController(text: data?['country'] ?? '');
    final currencyController = TextEditingController(text: data?['currency'] ?? 'BDT');
    final durationController = TextEditingController(text: data?['duration'] ?? '');
    final priceController = TextEditingController(text: data?['price']?.toString() ?? '');
    final ratingController = TextEditingController(text: data?['rating']?.toString() ?? '4.5');
    final availableController = ValueNotifier<bool>(data?['available'] ?? true);
    final discountEnabledController = ValueNotifier<bool>(data?['discountEnabled'] ?? false);
    final discountPercentController = TextEditingController(text: data?['discountPercent']?.toString() ?? data?['discountAmount']?.toString() ?? '0');
    
    // Handle images - can be single URL string or list of URLs
    List<String> imageUrls = [];
    if (data?['photo'] != null) {
      if (data!['photo'] is List) {
        imageUrls = List<String>.from(data['photo']);
      } else if (data['photo'] is String) {
        imageUrls = [data['photo']];
      }
    }
    
    final selectedImages = ValueNotifier<List<_PickedImage>>([]);
    final existingImageUrls = ValueNotifier<List<String>>(imageUrls);
    final isUploading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          id == null ? 'Add Tour Package' : 'Edit Tour Package',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(labelText: 'Country *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration (e.g., 5 Days / 4 Nights) *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Images *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<_PickedImage>>(
                    valueListenable: selectedImages,
                    builder: (context, pickedImages, _) {
                      return ValueListenableBuilder<List<String>>(
                        valueListenable: existingImageUrls,
                        builder: (context, urls, _) {
                          final totalImages = pickedImages.length + urls.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  try {
                                    final List<XFile> pickedFiles = await picker.pickMultiImage();
                                    if (pickedFiles.isNotEmpty) {
                                    final List<_PickedImage> images = [];
                                    for (final xFile in pickedFiles) {
                                      if (kIsWeb) {
                                        final bytes = await xFile.readAsBytes();
                                        // Ensure filename has extension
                                        String fileName = xFile.name;
                                        if (!fileName.contains('.')) {
                                          // Try to detect from mime type or default to jpg
                                          fileName = '${xFile.name}.jpg';
                                        }
                                        images.add(_PickedImage(
                                          bytes: bytes,
                                          name: fileName,
                                        ));
                                      } else {
                                        images.add(_PickedImage(
                                          file: File(xFile.path),
                                          name: xFile.name.isNotEmpty ? xFile.name : xFile.path.split('/').last,
                                        ));
                                      }
                                    }
                                      selectedImages.value = images;
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error picking images: $e')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Pick Images'),
                              ),
                              if (totalImages > 0) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Show existing URLs
                                    ...urls.map((url) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () {
                                              existingImageUrls.value = urls.where((u) => u != url).toList();
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                    // Show selected files
                                    ...pickedImages.map((pickedImage) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: kIsWeb && pickedImage.bytes != null
                                                ? Image.memory(
                                                    pickedImage.bytes!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : pickedImage.file != null
                                                    ? Image.file(
                                                        pickedImage.file!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () {
                                              selectedImages.value = pickedImages.where((img) => img != pickedImage).toList();
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: discountEnabledController,
                    builder: (context, discountEnabled, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Discount'),
                          subtitle: const Text('Enable discount for this tour package'),
                          value: discountEnabled,
                          onChanged: (v) {
                            discountEnabledController.value = v;
                            setDialogState(() {});
                          },
                        ),
                        if (discountEnabled)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: TextFormField(
                              controller: discountPercentController,
                              decoration: const InputDecoration(
                                labelText: 'Discount (%)',
                                hintText: 'e.g. 10 for 10% off',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: ratingController,
                    decoration: const InputDecoration(labelText: 'Rating (0-5)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: availableController,
                    builder: (context, available, _) => SwitchListTile(
                      title: const Text('Available'),
                      value: available,
                      onChanged: (v) {
                        availableController.value = v;
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: isUploading,
                        builder: (context, uploading, _) {
                          return ElevatedButton(
                            onPressed: uploading ? null : () async {
                              if (formKey.currentState!.validate()) {
                                final selectedFiles = selectedImages.value;
                                final existingUrls = existingImageUrls.value;
                                
                                if (selectedFiles.isEmpty && existingUrls.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select at least one image')),
                                  );
                                  return;
                                }

                                isUploading.value = true;
                                
                                try {
                                  // Upload new images to Cloudinary
                                  List<String> uploadedUrls = [];
                                  if (selectedFiles.isNotEmpty) {
                                    for (final pickedImage in selectedFiles) {
                                      String url;
                                      if (kIsWeb && pickedImage.bytes != null) {
                                        url = await CloudinaryService.uploadImageFromBytes(
                                          pickedImage.bytes!,
                                          pickedImage.name ?? 'image_${DateTime.now().millisecondsSinceEpoch}',
                                          folder: 'tour_packages',
                                        );
                                      } else if (pickedImage.file != null) {
                                        url = await CloudinaryService.uploadImage(
                                          pickedImage.file!,
                                          folder: 'tour_packages',
                                        );
                                      } else {
                                        continue;
                                      }
                                      uploadedUrls.add(url);
                                    }
                                  }
                                  
                                  // Combine existing URLs with newly uploaded URLs
                                  final allImageUrls = [...existingUrls, ...uploadedUrls];
                                  
                                  final tourData = {
                                    'title': titleController.text,
                                    'city': cityController.text,
                                    'country': countryController.text,
                                    'currency': currencyController.text,
                                    'duration': durationController.text,
                                    'photo': allImageUrls.length == 1 ? allImageUrls.first : allImageUrls,
                                    'price': int.tryParse(priceController.text) ?? 0,
                                    'rating': double.tryParse(ratingController.text) ?? 4.5,
                                    'available': availableController.value,
                                    'discountEnabled': discountEnabledController.value,
                                    'discountPercent': num.tryParse(discountPercentController.text) ?? 0,
                                    'type': 'tour',
                                  };

                                  if (id == null) {
                                    final newId = 'tour_${DateTime.now().millisecondsSinceEpoch}';
                                    await widget.dbRef.child('tour_packages').child(newId).set(tourData);
                                  } else {
                                    await widget.dbRef.child('tour_packages').child(id).update(tourData);
                                  }
                                  Navigator.pop(context);
                                  _loadTours();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(id == null ? 'Tour package added!' : 'Tour package updated!')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final errorMessage = e.toString();
                                    print('Upload error details: $errorMessage'); // Debug print
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $errorMessage'),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } finally {
                                  isUploading.value = false;
                                }
                              }
                            },
                            child: uploading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> tour;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TourCard({
    required this.id,
    required this.tour,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildImageWidget(dynamic photo, {double? width, double? height}) {
    String? imageUrl;
    if (photo is List && photo.isNotEmpty) {
      imageUrl = photo.first.toString();
    } else if (photo is String) {
      imageUrl = photo;
    }
    
    return Image.network(
      imageUrl ?? '',
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(
                tour['photo'],
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tour['title'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(tour['available'] == true ? 'Available' : 'Unavailable'),
                        backgroundColor: tour['available'] == true ? Colors.green[100] : Colors.red[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${tour['city']}, ${tour['country']}'),
                  const SizedBox(height: 4),
                  Text('Duration: ${tour['duration'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${tour['currency']} ${tour['price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text('${tour['rating'] ?? 'N/A'}'),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: onEdit,
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDelete,
                        color: Colors.red,
                      ),
                    ],
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

// ==================== VISA PACKAGES TAB ====================
class VisaPackagesTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const VisaPackagesTab({super.key, required this.dbRef});

  @override
  State<VisaPackagesTab> createState() => _VisaPackagesTabState();
}

class _VisaPackagesTabState extends State<VisaPackagesTab> {
  Map<String, dynamic> _visas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisas();
  }

  Future<void> _loadVisas() async {
    try {
      final snapshot = await widget.dbRef.child('visa_packages').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final raw = snapshot.value;
          if (raw is Map) {
            _visas = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading visas: $e')),
        );
      }
    }
  }

  Future<void> _deleteVisa(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visa Package'),
        content: const Text('Are you sure you want to delete this visa package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.dbRef.child('visa_packages').child(id).remove();
        _loadVisas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visa package deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting visa: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Visa Packages',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showVisaDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Visa Package'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _visas.isEmpty
              ? const Center(child: Text('No visa packages found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visas.length,
                  itemBuilder: (context, index) {
                    final entry = _visas.entries.elementAt(index);
                    final visa = Map<String, dynamic>.from(
                      entry.value is Map
                          ? (entry.value as Map).map((k, v) => MapEntry(k.toString(), v))
                          : {},
                    );
                    return _VisaCard(
                      id: entry.key,
                      visa: visa,
                      onEdit: () => _showVisaDialog(id: entry.key, data: visa),
                      onDelete: () => _deleteVisa(entry.key),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEntryTypeRow(
    String placeholder,
    ValueNotifier<bool> enabledNotifier,
    TextEditingController priceController,
    void Function(void Function()) setDialogState,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: enabledNotifier,
      builder: (context, enabled, _) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Switch(
              value: enabled,
              onChanged: (v) {
                enabledNotifier.value = v;
                setDialogState(() {});
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: priceController,
                decoration: InputDecoration(
                  hintText: placeholder,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                enabled: enabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisaDialog({String? id, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final countryController = TextEditingController(text: data?['country'] ?? '');
    final currencyController = TextEditingController(text: data?['currency'] ?? 'BDT');
    final visaTypeController = TextEditingController(text: data?['visaType'] ?? '');
    final validityController = TextEditingController(text: data?['validity'] ?? '');
    final processingTimeController = TextEditingController(text: data?['processingTime'] ?? '');
    final availableController = ValueNotifier<bool>(data?['available'] ?? true);
    final discountEnabledController = ValueNotifier<bool>(data?['discountEnabled'] ?? false);
    final discountPercentController = TextEditingController(text: data?['discountPercent']?.toString() ?? data?['discountAmount']?.toString() ?? '0');

    // Structured documents: general + per-category
    final List<_AdminVisaDocument> generalDocuments = [];
    final Map<String, List<_AdminVisaDocument>> categoryDocuments = {
      'businessPerson': <_AdminVisaDocument>[],
      'student': <_AdminVisaDocument>[],
      'jobHolder': <_AdminVisaDocument>[],
      'other': <_AdminVisaDocument>[],
    };

    // Load structured general documents if present
    final generalRaw = data?['generalDocuments'];
    if (generalRaw is List) {
      for (final item in generalRaw) {
        if (item is Map) {
          generalDocuments.add(
            _AdminVisaDocument.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // Load structured category documents if present
    final categoryRaw = data?['categoryDocuments'];
    if (categoryRaw is Map) {
      final cats = Map<String, dynamic>.from(categoryRaw);
      for (final entry in cats.entries) {
        final key = entry.key;
        if (entry.value is List && categoryDocuments.containsKey(key)) {
          final list = <_AdminVisaDocument>[];
          for (final item in (entry.value as List)) {
            if (item is Map) {
              list.add(
                _AdminVisaDocument.fromMap(Map<String, dynamic>.from(item)),
              );
            }
          }
          if (list.isNotEmpty) {
            categoryDocuments[key] = list;
          }
        }
      }
    }

    // Backwards compatibility: if no structured general docs yet, seed from legacy requiredDocuments
    if (generalDocuments.isEmpty) {
      final legacyDocs = data?['requiredDocuments'];
      if (legacyDocs is List) {
        for (final item in legacyDocs) {
          if (item is String && item.trim().isNotEmpty) {
            generalDocuments.add(
              _AdminVisaDocument(title: item.trim()),
            );
          }
        }
      }
    }

    // Entry types: single, double, multiple - safe extraction (Firebase returns Map<dynamic, dynamic>)
    final entryTypesRaw = data?['entryTypes'];
    final Map<String, dynamic>? et = entryTypesRaw != null && entryTypesRaw is Map
        ? Map<String, dynamic>.from(entryTypesRaw)
        : null;
    final singleEntry = et != null && et['singleEntry'] is Map
        ? Map<String, dynamic>.from(et['singleEntry'] as Map)
        : null;
    final doubleEntry = et != null && et['doubleEntry'] is Map
        ? Map<String, dynamic>.from(et['doubleEntry'] as Map)
        : null;
    final multipleEntry = et != null && et['multipleEntry'] is Map
        ? Map<String, dynamic>.from(et['multipleEntry'] as Map)
        : null;
    final singleEntryEnabled = ValueNotifier<bool>(singleEntry?['enabled'] ?? false);
    final singleEntryPrice = TextEditingController(text: singleEntry?['price']?.toString() ?? '');
    final doubleEntryEnabled = ValueNotifier<bool>(doubleEntry?['enabled'] ?? false);
    final doubleEntryPrice = TextEditingController(text: doubleEntry?['price']?.toString() ?? '');
    final multipleEntryEnabled = ValueNotifier<bool>(multipleEntry?['enabled'] ?? false);
    final multipleEntryPrice = TextEditingController(text: multipleEntry?['price']?.toString() ?? '');

    // Handle images - can be single URL string or list of URLs
    List<String> imageUrls = [];
    if (data?['photo'] != null) {
      if (data!['photo'] is List) {
        imageUrls = List<String>.from(data['photo']);
      } else if (data['photo'] is String) {
        imageUrls = [data['photo']];
      }
    }
    
    final selectedImages = ValueNotifier<List<_PickedImage>>([]);
    final existingImageUrls = ValueNotifier<List<String>>(imageUrls);
    final isUploading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          id == null ? 'Add Visa Package' : 'Edit Visa Package',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(labelText: 'Country *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Images *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<_PickedImage>>(
                    valueListenable: selectedImages,
                    builder: (context, pickedImages, _) {
                      return ValueListenableBuilder<List<String>>(
                        valueListenable: existingImageUrls,
                        builder: (context, urls, _) {
                          final totalImages = pickedImages.length + urls.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  try {
                                    final List<XFile> pickedFiles = await picker.pickMultiImage();
                                    if (pickedFiles.isNotEmpty) {
                                    final List<_PickedImage> images = [];
                                    for (final xFile in pickedFiles) {
                                      if (kIsWeb) {
                                        final bytes = await xFile.readAsBytes();
                                        // Ensure filename has extension
                                        String fileName = xFile.name;
                                        if (!fileName.contains('.')) {
                                          // Try to detect from mime type or default to jpg
                                          fileName = '${xFile.name}.jpg';
                                        }
                                        images.add(_PickedImage(
                                          bytes: bytes,
                                          name: fileName,
                                        ));
                                      } else {
                                        images.add(_PickedImage(
                                          file: File(xFile.path),
                                          name: xFile.name.isNotEmpty ? xFile.name : xFile.path.split('/').last,
                                        ));
                                      }
                                    }
                                      selectedImages.value = images;
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error picking images: $e')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Pick Images'),
                              ),
                              if (totalImages > 0) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Show existing URLs
                                    ...urls.map((url) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () {
                                              existingImageUrls.value = urls.where((u) => u != url).toList();
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                    // Show selected files
                                    ...pickedImages.map((pickedImage) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: kIsWeb && pickedImage.bytes != null
                                                ? Image.memory(
                                                    pickedImage.bytes!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : pickedImage.file != null
                                                    ? Image.file(
                                                        pickedImage.file!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () {
                                              selectedImages.value = pickedImages.where((img) => img != pickedImage).toList();
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<bool>(
                    valueListenable: singleEntryEnabled,
                    builder: (context, _, __) => ValueListenableBuilder<bool>(
                      valueListenable: doubleEntryEnabled,
                      builder: (context, __, ___) => ValueListenableBuilder<bool>(
                        valueListenable: multipleEntryEnabled,
                        builder: (context, ___, ____) => Column(
                          children: [
                            _buildEntryTypeRow(
                              'Single entry price',
                              singleEntryEnabled,
                              singleEntryPrice,
                              setDialogState,
                            ),
                            _buildEntryTypeRow(
                              'Double entry price',
                              doubleEntryEnabled,
                              doubleEntryPrice,
                              setDialogState,
                            ),
                            _buildEntryTypeRow(
                              'Multiple entry price',
                              multipleEntryEnabled,
                              multipleEntryPrice,
                              setDialogState,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: discountEnabledController,
                    builder: (context, discountEnabled, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Discount'),
                          subtitle: const Text('Enable discount for this visa package'),
                          value: discountEnabled,
                          onChanged: (v) {
                            discountEnabledController.value = v;
                            setDialogState(() {});
                          },
                        ),
                        if (discountEnabled)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: TextFormField(
                              controller: discountPercentController,
                              decoration: const InputDecoration(
                                labelText: 'Discount (%)',
                                hintText: 'e.g. 10 for 10% off',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: visaTypeController,
                    decoration: const InputDecoration(labelText: 'Visa Type (e.g., Tourist)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: validityController,
                    decoration: const InputDecoration(labelText: 'Validity (e.g., 30 Days)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: processingTimeController,
                    decoration: const InputDecoration(labelText: 'Processing Time'),
                  ),
                  const SizedBox(height: 16),
                  // General Documents section
                  const Text(
                    'General Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (generalDocuments.isEmpty)
                    const Text(
                      'No general documents added yet',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...generalDocuments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Document ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      setDialogState(() {
                                        generalDocuments.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              TextFormField(
                                controller: doc.titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: doc.subtitlesController,
                                decoration: const InputDecoration(
                                  labelText: 'Subtitles (comma separated)',
                                  hintText: 'e.g. At least 6 months validity, Old passport copies',
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          generalDocuments.add(_AdminVisaDocument());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add general document'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Documents by visa category
                  const Text(
                    'Documents by visa category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      const categoryLabels = <String, String>{
                        'businessPerson': 'Business person',
                        'student': 'Student',
                        'jobHolder': 'Job holder',
                        'other': 'Other documents',
                      };
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categoryLabels.entries.map((cat) {
                          final key = cat.key;
                          final label = cat.value;
                          final docs = categoryDocuments[key]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (docs.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                                  child: Text(
                                    'No documents added yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ...docs.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final doc = entry.value;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Requirement ${idx + 1}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                onPressed: () {
                                                  setDialogState(() {
                                                    docs.removeAt(idx);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          TextFormField(
                                            controller: doc.titleController,
                                            decoration: const InputDecoration(
                                              labelText: 'Title',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: doc.subtitlesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Subtitles (comma separated)',
                                              hintText: 'e.g. Bank statement, Salary certificate',
                                            ),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      docs.add(_AdminVisaDocument());
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: Text('Add $label document'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: availableController,
                    builder: (context, available, _) => SwitchListTile(
                      title: const Text('Available'),
                      value: available,
                      onChanged: (v) {
                        availableController.value = v;
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: isUploading,
                        builder: (context, uploading, _) {
                          return ElevatedButton(
                            onPressed: uploading ? null : () async {
                              if (formKey.currentState!.validate()) {
                                final selectedFiles = selectedImages.value;
                                final existingUrls = existingImageUrls.value;
                                
                                if (selectedFiles.isEmpty && existingUrls.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select at least one image')),
                                  );
                                  return;
                                }

                                isUploading.value = true;
                                
                                try {
                                  // Upload new images to Cloudinary
                                  List<String> uploadedUrls = [];
                                  if (selectedFiles.isNotEmpty) {
                                    for (final pickedImage in selectedFiles) {
                                      String url;
                                      if (kIsWeb && pickedImage.bytes != null) {
                                        url = await CloudinaryService.uploadImageFromBytes(
                                          pickedImage.bytes!,
                                          pickedImage.name ?? 'image_${DateTime.now().millisecondsSinceEpoch}',
                                          folder: 'visa_packages',
                                        );
                                      } else if (pickedImage.file != null) {
                                        url = await CloudinaryService.uploadImage(
                                          pickedImage.file!,
                                          folder: 'visa_packages',
                                        );
                                      } else {
                                        continue;
                                      }
                                      uploadedUrls.add(url);
                                    }
                                  }
                                  
                                  // Combine existing URLs with newly uploaded URLs
                                  final allImageUrls = [...existingUrls, ...uploadedUrls];

                                  // Build structured documents payloads
                                  final List<Map<String, dynamic>> generalDocsPayload = [];
                                  for (final doc in generalDocuments) {
                                    final map = doc.toMap();
                                    final title = (map['title'] as String).trim();
                                    if (title.isNotEmpty) {
                                      generalDocsPayload.add(map);
                                    }
                                  }

                                  final Map<String, List<Map<String, dynamic>>> categoryDocsPayload = {};
                                  for (final entry in categoryDocuments.entries) {
                                    final docs = <Map<String, dynamic>>[];
                                    for (final doc in entry.value) {
                                      final map = doc.toMap();
                                      final title = (map['title'] as String).trim();
                                      if (title.isNotEmpty) {
                                        docs.add(map);
                                      }
                                    }
                                    if (docs.isNotEmpty) {
                                      categoryDocsPayload[entry.key] = docs;
                                    }
                                  }

                                  // Legacy flat requiredDocuments for backward compatibility
                                  final List<String> flattenedRequiredDocs = [];

                                  void addFromDocMaps(List<Map<String, dynamic>> docs) {
                                    for (final doc in docs) {
                                      final title = (doc['title'] as String).trim();
                                      if (title.isEmpty) continue;
                                      final subtitlesRaw = doc['subtitles'];
                                      final subtitles = subtitlesRaw is List
                                          ? List<String>.from(
                                              subtitlesRaw.where((e) => e is String),
                                            )
                                          : const <String>[];
                                      if (subtitles.isEmpty) {
                                        flattenedRequiredDocs.add(title);
                                      } else {
                                        flattenedRequiredDocs.add('$title: ${subtitles.join(', ')}');
                                      }
                                    }
                                  }

                                  addFromDocMaps(generalDocsPayload);
                                  for (final docs in categoryDocsPayload.values) {
                                    addFromDocMaps(docs);
                                  }

                                  final entryTypes = <String, Map<String, dynamic>>{
                                    'singleEntry': {
                                      'enabled': singleEntryEnabled.value,
                                      'price': num.tryParse(singleEntryPrice.text) ?? 0,
                                    },
                                    'doubleEntry': {
                                      'enabled': doubleEntryEnabled.value,
                                      'price': num.tryParse(doubleEntryPrice.text) ?? 0,
                                    },
                                    'multipleEntry': {
                                      'enabled': multipleEntryEnabled.value,
                                      'price': num.tryParse(multipleEntryPrice.text) ?? 0,
                                    },
                                  };

                                  // Require at least one entry type enabled with price
                                  final enabledPrices = <num>[];
                                  if (singleEntryEnabled.value) enabledPrices.add(num.tryParse(singleEntryPrice.text) ?? 0);
                                  if (doubleEntryEnabled.value) enabledPrices.add(num.tryParse(doubleEntryPrice.text) ?? 0);
                                  if (multipleEntryEnabled.value) enabledPrices.add(num.tryParse(multipleEntryPrice.text) ?? 0);
                                  if (enabledPrices.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Enable at least one entry type with a price')),
                                    );
                                    return;
                                  }
                                  final basePrice = enabledPrices.reduce((a, b) => a < b ? a : b);

                                  final visaData = {
                                    'title': titleController.text,
                                    'country': countryController.text,
                                    'currency': currencyController.text,
                                    'photo': allImageUrls.length == 1 ? allImageUrls.first : allImageUrls,
                                    'price': basePrice.toInt(),
                                    'visaType': visaTypeController.text,
                                    'validity': validityController.text,
                                    'processingTime': processingTimeController.text,
                                    'requiredDocuments': flattenedRequiredDocs,
                                    'generalDocuments': generalDocsPayload,
                                    'categoryDocuments': categoryDocsPayload,
                                    'available': availableController.value,
                                    'discountEnabled': discountEnabledController.value,
                                    'discountPercent': num.tryParse(discountPercentController.text) ?? 0,
                                    'entryTypes': entryTypes,
                                    'type': 'visa',
                                  };

                                  if (id == null) {
                                    final newId = 'visa_${DateTime.now().millisecondsSinceEpoch}';
                                    await widget.dbRef.child('visa_packages').child(newId).set(visaData);
                                  } else {
                                    await widget.dbRef.child('visa_packages').child(id).update(visaData);
                                  }
                                  Navigator.pop(context);
                                  _loadVisas();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(id == null ? 'Visa package added!' : 'Visa package updated!')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final errorMessage = e.toString();
                                    print('Upload error details: $errorMessage'); // Debug print
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $errorMessage'),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } finally {
                                  isUploading.value = false;
                                }
                              }
                            },
                            child: uploading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisaCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> visa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VisaCard({
    required this.id,
    required this.visa,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatEntryTypeLabel(String key) {
    switch (key) {
      case 'singleEntry': return 'Single';
      case 'doubleEntry': return 'Double';
      case 'multipleEntry': return 'Multiple';
      default: return key;
    }
  }

  String _formatEntryTypePrices(Map<String, dynamic> visa) {
    final entryTypes = visa['entryTypes'];
    if (entryTypes == null || entryTypes is! Map) {
      return '${visa['currency'] ?? ''} ${visa['price'] ?? 0}';
    }
    final et = Map<String, dynamic>.from(entryTypes);
    final parts = <String>[];
    for (final key in ['singleEntry', 'doubleEntry', 'multipleEntry']) {
      final opt = et[key];
      if (opt is Map) {
        final m = Map<String, dynamic>.from(opt);
        if (m['enabled'] == true) {
          final price = m['price'] ?? 0;
          parts.add('${_formatEntryTypeLabel(key)} ${visa['currency'] ?? ''} $price');
        }
      }
    }
    return parts.isEmpty ? '${visa['currency'] ?? ''} ${visa['price'] ?? 0}' : parts.join(' • ');
  }

  Widget _buildImageWidget(dynamic photo, {double? width, double? height}) {
    String? imageUrl;
    if (photo is List && photo.isNotEmpty) {
      imageUrl = photo.first.toString();
    } else if (photo is String) {
      imageUrl = photo;
    }
    
    return Image.network(
      imageUrl ?? '',
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(
                visa['photo'],
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visa['title'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(visa['available'] == true ? 'Available' : 'Unavailable'),
                        backgroundColor: visa['available'] == true ? Colors.green[100] : Colors.red[100],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${visa['country']} - ${visa['visaType'] ?? 'N/A'}'),
                  const SizedBox(height: 4),
                  if (visa['validity'] != null) Text('Validity: ${visa['validity']}'),
                  if (visa['processingTime'] != null) Text('Processing: ${visa['processingTime']}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatEntryTypePrices(visa),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: onEdit,
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDelete,
                        color: Colors.red,
                      ),
                    ],
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

// ==================== BOOKINGS TAB ====================
class BookingsTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const BookingsTab({super.key, required this.dbRef});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  Map<String, dynamic> _bookings = {};
  bool _isLoading = true;
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<DatabaseEvent>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    // Listen for real-time updates
    _bookingsSub = widget.dbRef.child('bookings').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        setState(() {
          final raw = event.snapshot.value;
          if (raw is Map) {
            _bookings = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
        });
      } else {
        setState(() {
          _bookings = {};
        });
      }
    });
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      final snapshot = await widget.dbRef.child('bookings').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final raw = snapshot.value;
          if (raw is Map) {
            _bookings = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(String id, String status) async {
    try {
      await widget.dbRef.child('bookings').child(id).update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  List<MapEntry<String, dynamic>> get _filteredBookings {
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    var filtered = _bookings.entries.where((entry) {
      final value = entry.value;
      if (value is Map) {
        final booking = Map<String, dynamic>.from(
          value.map((k, v) => MapEntry(k.toString(), v)),
        );
        
        // Filter by status
        if (_filterStatus != 'all' && booking['status'] != _filterStatus) {
          return false;
        }
        
        // Filter by search query
        if (searchQuery.isNotEmpty) {
          final name = (booking['name'] ?? '').toString().toLowerCase();
          final email = (booking['email'] ?? '').toString().toLowerCase();
          final phone = (booking['phone'] ?? '').toString().toLowerCase();
          final itemTitle = (booking['itemTitle'] ?? '').toString().toLowerCase();
          final itemType = (booking['itemType'] ?? '').toString().toLowerCase();
          final notes = (booking['notes'] ?? '').toString().toLowerCase();
          
          return name.contains(searchQuery) ||
                 email.contains(searchQuery) ||
                 phone.contains(searchQuery) ||
                 itemTitle.contains(searchQuery) ||
                 itemType.contains(searchQuery) ||
                 notes.contains(searchQuery);
        }
        
        return true;
      }
      return false;
    }).toList();
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bookings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search bookings by name, email, phone, item title...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      return value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Filter by status: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filterStatus == 'all',
                    onSelected: (_) => setState(() => _filterStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Pending'),
                    selected: _filterStatus == 'pending',
                    onSelected: (_) => setState(() => _filterStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Confirmed'),
                    selected: _filterStatus == 'confirmed',
                    onSelected: (_) => setState(() => _filterStatus = 'confirmed'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Cancelled'),
                    selected: _filterStatus == 'cancelled',
                    onSelected: (_) => setState(() => _filterStatus = 'cancelled'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredBookings.isEmpty
              ? const Center(child: Text('No bookings found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredBookings.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredBookings[index];
                    final booking = Map<String, dynamic>.from(
                      entry.value is Map
                          ? (entry.value as Map).map((k, v) => MapEntry(k.toString(), v))
                          : {},
                    );
                    return _BookingCard(
                      id: entry.key,
                      booking: booking,
                      onStatusUpdate: (status) => _updateBookingStatus(entry.key, status),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Helper function to show passport image dialog
void _showPassportImageDialog(BuildContext context, String imageUrl, String personName) {
  showDialog(
    context: context,
    builder: (context) => _PassportImageDialog(
      imageUrl: imageUrl,
      personName: personName,
    ),
  );
}

class _PassportImageDialog extends StatefulWidget {
  final String imageUrl;
  final String personName;

  const _PassportImageDialog({
    required this.imageUrl,
    required this.personName,
  });

  @override
  State<_PassportImageDialog> createState() => _PassportImageDialogState();
}

class _PassportImageDialogState extends State<_PassportImageDialog> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final fileName = '${_sanitizeFileName(widget.personName)}_passport.png';
      final response = await http.get(Uri.parse(widget.imageUrl));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        if (kIsWeb) {
          // Web download using the download utility
          download_util.downloadFile(bytes, fileName);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image download started!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Mobile - save to temporary directory
          final tempDir = Directory.systemTemp;
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image saved to: ${file.path}\nYou can share or move it from there.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to download image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _sanitizeFileName(String name) {
    // Remove special characters and replace spaces with underscores
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Passport Photo - ${widget.personName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Image
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              SizedBox(height: 8),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Download Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadImage,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isDownloading ? 'Downloading...' : 'Download Image'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
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

class _BookingCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> booking;
  final Function(String) onStatusUpdate;

  const _BookingCard({
    required this.id,
    required this.booking,
    required this.onStatusUpdate,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final date = booking['date'] ?? 'N/A';
    final itemTitle = booking['itemTitle'] ?? 'N/A';
    final itemType = booking['itemType'] ?? 'N/A';
    final name = booking['name'] ?? 'N/A';
    final email = booking['email'] ?? 'N/A';
    final phone = booking['phone'] ?? 'N/A';
    final numberOfPeople = booking['numberOfPeople'] ?? 0;
    final notes = booking['notes'] ?? '';
    final timestamp = booking['timestamp'] ?? '';
    // Check for both passportPhotoUrl and visaPhotoUrl
    final passportPhotoUrl = booking['passportPhotoUrl'] ?? booking['visaPhotoUrl'];
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon based on item type
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getItemTypeColor(itemType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getItemTypeIcon(itemType),
                      color: _getItemTypeColor(itemType),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              itemType.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (itemType.toLowerCase() == 'visa' && (booking['visaEntryTypeLabel'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (booking['visaEntryTypeLabel'] ?? '').toString(),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Customer Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _ModernInfoRow(
                      icon: Icons.person,
                      label: 'Customer',
                      value: name,
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _ModernInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: email,
                      iconColor: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _ModernInfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: phone,
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _ModernInfoRow(
                      icon: Icons.people,
                      label: 'People',
                      value: numberOfPeople.toString(),
                      iconColor: Colors.purple,
                    ),
                  ],
                ),
              ),
              // Notes Section
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Passport Photo Section
              if (passportPhotoUrl != null && (passportPhotoUrl as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Passport Photo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showPassportImageDialog(context, passportPhotoUrl, name),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Image.network(
                                  passportPhotoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red.shade300,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                                // Overlay on hover/click
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Timestamp
              if (timestamp.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Booked on ${_formatTimestamp(timestamp)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
              // Action Buttons
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  if (status != 'confirmed')
                    _ActionButton(
                      label: 'Confirm',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onPressed: () => onStatusUpdate('confirmed'),
                    ),
                  if (status != 'cancelled')
                    _ActionButton(
                      label: 'Cancel',
                      icon: Icons.cancel,
                      color: Colors.red,
                      onPressed: () => onStatusUpdate('cancelled'),
                    ),
                  if (status != 'pending')
                    _ActionButton(
                      label: 'Set Pending',
                      icon: Icons.pending,
                      color: Colors.orange,
                      onPressed: () => onStatusUpdate('pending'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getItemTypeIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'visa':
        return Icons.article;
      case 'tour':
        return Icons.flight;
      case 'destination':
        return Icons.location_on;
      default:
        return Icons.info;
    }
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'visa':
        return Colors.purple;
      case 'tour':
        return Colors.blue;
      case 'destination':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return timestamp;
    }
  }
}

class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _ModernInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    );
  }
}

// ==================== BANNERS/PROMOTIONS TAB ====================
class BannersTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const BannersTab({super.key, required this.dbRef});

  @override
  State<BannersTab> createState() => _BannersTabState();
}

class _BannersTabState extends State<BannersTab> {
  Map<String, dynamic> _banners = {};
  bool _isLoading = true;
  bool _showPromotions = true;
  StreamSubscription<DatabaseEvent>? _bannersSub;
  StreamSubscription<DatabaseEvent>? _showPromotionsSub;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _loadShowPromotionsSetting();
    // Listen for real-time updates
    _bannersSub = widget.dbRef.child('banners').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        setState(() {
          final raw = event.snapshot.value;
          if (raw is Map) {
            _banners = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
        });
      } else {
        setState(() {
          _banners = {};
        });
      }
    });
    // Listen for show promotions setting
    _showPromotionsSub = widget.dbRef.child('settings').child('showPromotions').onValue.listen((event) {
      if (!mounted) return;
      setState(() {
        final value = event.snapshot.value;
        _showPromotions = value is bool ? value : true;
      });
    });
  }

  @override
  void dispose() {
    _bannersSub?.cancel();
    _showPromotionsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final snapshot = await widget.dbRef.child('banners').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final raw = snapshot.value;
          if (raw is Map) {
            _banners = Map<String, dynamic>.from(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading banners: $e')),
        );
      }
    }
  }

  Future<void> _loadShowPromotionsSetting() async {
    try {
      final snapshot = await widget.dbRef.child('settings').child('showPromotions').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final value = snapshot.value;
          _showPromotions = value is bool ? value : true;
        });
      }
    } catch (e) {
      // Use default value
    }
  }

  Future<void> _updateShowPromotions(bool value) async {
    try {
      await widget.dbRef.child('settings').child('showPromotions').set(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promotions ${value ? 'enabled' : 'disabled'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating setting: $e')),
        );
      }
    }
  }

  Future<void> _deleteBanner(String id) async {
    try {
      await widget.dbRef.child('banners').child(id).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting banner: $e')),
        );
      }
    }
  }

  void _showBannerDialog({String? id, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final typeController = ValueNotifier<String>(data?['type'] ?? 'image');
    final headingController = TextEditingController(text: data?['heading'] ?? '');
    final subtextController = TextEditingController(text: data?['subtext'] ?? '');
    final imageUrlController = TextEditingController(text: data?['imageUrl'] ?? '');
    final selectedImage = ValueNotifier<_PickedImage?>(null);
    final isUploading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          id == null ? 'Add Banner' : 'Edit Banner',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Banner Type *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<String>(
                            valueListenable: typeController,
                            builder: (context, type, _) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Image'),
                                      value: 'image',
                                      groupValue: type,
                                      onChanged: (value) {
                                        typeController.value = value!;
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Text'),
                                      value: 'text',
                                      groupValue: type,
                                      onChanged: (value) {
                                        typeController.value = value!;
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<String>(
                            valueListenable: typeController,
                            builder: (context, type, _) {
                              if (type == 'image') {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Banner Image *',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<_PickedImage?>(
                                      valueListenable: selectedImage,
                                      builder: (context, pickedImage, _) {
                                        return ValueListenableBuilder<bool>(
                                          valueListenable: isUploading,
                                          builder: (context, uploading, _) {
                                            return Column(
                                              children: [
                                                if (pickedImage != null || imageUrlController.text.isNotEmpty)
                                                  Container(
                                                    height: 200,
                                                    margin: const EdgeInsets.only(bottom: 16),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: pickedImage != null
                                                          ? (kIsWeb
                                                              ? Image.memory(
                                                                  pickedImage.bytes!,
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : Image.file(
                                                                  pickedImage.file!,
                                                                  fit: BoxFit.cover,
                                                                ))
                                                          : Image.network(
                                                              imageUrlController.text,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return const Center(
                                                                  child: Icon(Icons.error, size: 50),
                                                                );
                                                              },
                                                            ),
                                                    ),
                                                  ),
                                                ElevatedButton.icon(
                                                  onPressed: uploading
                                                      ? null
                                                      : () async {
                                                          final ImagePicker picker = ImagePicker();
                                                          try {
                                                            final XFile? pickedFile = await picker.pickImage(
                                                              source: ImageSource.gallery,
                                                            );
                                                            if (pickedFile != null) {
                                                              if (kIsWeb) {
                                                                final bytes = await pickedFile.readAsBytes();
                                                                selectedImage.value = _PickedImage(
                                                                  bytes: bytes,
                                                                  name: pickedFile.name,
                                                                );
                                                              } else {
                                                                selectedImage.value = _PickedImage(
                                                                  file: File(pickedFile.path),
                                                                );
                                                              }
                                                              setDialogState(() {});
                                                            }
                                                          } catch (e) {
                                                            if (mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Error picking image: $e')),
                                                              );
                                                            }
                                                          }
                                                        },
                                                  icon: const Icon(Icons.image),
                                                  label: const Text('Pick Image'),
                                                ),
                                                if (imageUrlController.text.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: TextField(
                                                      controller: imageUrlController,
                                                      decoration: const InputDecoration(
                                                        labelText: 'Or enter image URL',
                                                        border: OutlineInputBorder(),
                                                      ),
                                                      onChanged: (_) => setDialogState(() {}),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: headingController,
                                      decoration: const InputDecoration(
                                        labelText: 'Heading Text *',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: subtextController,
                                      decoration: const InputDecoration(
                                        labelText: 'Subtext *',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          ValueListenableBuilder<bool>(
                            valueListenable: isUploading,
                            builder: (context, uploading, _) {
                              return ElevatedButton(
                                onPressed: uploading
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) return;

                                        final type = typeController.value;
                                        if (type == 'image' &&
                                            selectedImage.value == null &&
                                            imageUrlController.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please select an image or enter image URL'),
                                            ),
                                          );
                                          return;
                                        }

                                        isUploading.value = true;
                                        setDialogState(() {});

                                        try {
                                          String? imageUrl = imageUrlController.text.isNotEmpty
                                              ? imageUrlController.text
                                              : null;

                                          if (type == 'image' && selectedImage.value != null) {
                                            if (kIsWeb) {
                                              imageUrl = await CloudinaryService.uploadImageFromBytes(
                                                selectedImage.value!.bytes!,
                                                selectedImage.value!.name ?? 'banner.jpg',
                                                folder: 'banners',
                                              );
                                            } else {
                                              imageUrl = await CloudinaryService.uploadImage(
                                                selectedImage.value!.file!,
                                                folder: 'banners',
                                              );
                                            }
                                          }

                                          final bannerData = {
                                            'type': type,
                                            if (type == 'image') 'imageUrl': imageUrl,
                                            if (type == 'text') ...{
                                              'heading': headingController.text,
                                              'subtext': subtextController.text,
                                            },
                                            'createdAt': DateTime.now().toIso8601String(),
                                          };

                                          if (id == null) {
                                            await widget.dbRef.child('banners').push().set(bannerData);
                                          } else {
                                            await widget.dbRef.child('banners').child(id).update(bannerData);
                                          }

                                          if (mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(id == null ? 'Banner added' : 'Banner updated'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error saving banner: $e')),
                                            );
                                          }
                                        } finally {
                                          isUploading.value = false;
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: uploading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(id == null ? 'Add Banner' : 'Update Banner'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Banners/Promotions',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Text('Show Promotions: '),
                      Switch(
                        value: _showPromotions,
                        onChanged: _updateShowPromotions,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showBannerDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Banner'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _banners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No banners yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add New Banner" to create one',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final entry = _banners.entries.elementAt(index);
                    final id = entry.key;
                    final banner = Map<String, dynamic>.from(
                      entry.value is Map
                          ? (entry.value as Map).map((k, v) => MapEntry(k.toString(), v))
                          : {},
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: banner['type'] == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  banner['imageUrl'] ?? '',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.text_fields, size: 40),
                              ),
                        title: Text(
                          banner['type'] == 'image'
                              ? 'Image Banner'
                              : banner['heading'] ?? 'Text Banner',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${banner['type']}'),
                            if (banner['type'] == 'text')
                              Text('Subtext: ${banner['subtext'] ?? ''}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showBannerDialog(id: id, data: banner),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Banner'),
                                    content: const Text('Are you sure you want to delete this banner?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteBanner(id);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== ABOUT US TAB ====================
class AboutUsTab extends StatefulWidget {
  final DatabaseReference dbRef;
  const AboutUsTab({super.key, required this.dbRef});

  @override
  State<AboutUsTab> createState() => _AboutUsTabState();
}

class _AboutUsTabState extends State<AboutUsTab> {
  Map<String, dynamic>? _aboutUs;
  Map<String, dynamic> _employees = {};
  bool _isLoading = true;
  StreamSubscription<DatabaseEvent>? _aboutUsSub;

  @override
  void initState() {
    super.initState();
    _loadAboutUs();
    // Listen for real-time updates
    _aboutUsSub = widget.dbRef.child('about_us').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        setState(() {
          final raw = event.snapshot.value;
          if (raw is Map) {
            _aboutUs = Map<String, dynamic>.from(raw);
            if (_aboutUs!['employees'] != null && _aboutUs!['employees'] is Map) {
              _employees = Map<String, dynamic>.from(_aboutUs!['employees']);
            } else {
              _employees = {};
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _aboutUsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAboutUs() async {
    try {
      final snapshot = await widget.dbRef.child('about_us').get();
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          final raw = snapshot.value;
          if (raw is Map) {
            _aboutUs = Map<String, dynamic>.from(raw);
            if (_aboutUs!['employees'] != null && _aboutUs!['employees'] is Map) {
              _employees = Map<String, dynamic>.from(_aboutUs!['employees']);
            } else {
              _employees = {};
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading about us: $e')),
        );
      }
    }
  }

  void _showEditAboutUsDialog() {
    final formKey = GlobalKey<FormState>();
    final companyNameController = TextEditingController(text: _aboutUs?['companyName'] ?? '');
    final taglineController = TextEditingController(text: _aboutUs?['tagline'] ?? '');
    final descriptionController = TextEditingController(text: _aboutUs?['description'] ?? '');
    final missionController = TextEditingController(text: _aboutUs?['mission'] ?? '');
    final visionController = TextEditingController(text: _aboutUs?['vision'] ?? '');
    final ratingController = TextEditingController(text: (_aboutUs?['rating'] ?? 0).toString());
    final establishedYearController = TextEditingController(text: (_aboutUs?['establishedYear'] ?? 0).toString());
    
    // Contact fields
    final phoneController = TextEditingController(text: _aboutUs?['contact']?['phone'] ?? '');
    final emailController = TextEditingController(text: _aboutUs?['contact']?['email'] ?? '');
    final addressController = TextEditingController(text: _aboutUs?['contact']?['address'] ?? '');
    
    // Social links
    final facebookController = TextEditingController(text: _aboutUs?['socialLinks']?['facebook'] ?? '');
    final instagramController = TextEditingController(text: _aboutUs?['socialLinks']?['instagram'] ?? '');
    final whatsappController = TextEditingController(text: _aboutUs?['socialLinks']?['whatsapp'] ?? '');
    final youtubeController = TextEditingController(text: _aboutUs?['socialLinks']?['youtube'] ?? '');
    
    // Lists
    final whyChooseUsController = TextEditingController(text: (_aboutUs?['whyChooseUs'] as List?)?.join(', ') ?? '');
    // Services: "Title | Subtitle" per item, comma-separated (e.g. "Hotel | We can share hotel etc., Visa | Visa processing")
    final rawServices = _aboutUs?['services'];
    String servicesText = '';
    if (rawServices != null && rawServices is List) {
      servicesText = rawServices.map((item) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final title = m['title']?.toString() ?? '';
          final subtitle = m['subtitle']?.toString() ?? '';
          return subtitle.isNotEmpty ? '$title | $subtitle' : title;
        } else if (item is String) {
          return item;
        }
        return '';
      }).where((s) => s.isNotEmpty).join(', ');
    }
    final servicesController = TextEditingController(text: servicesText);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit About Us',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: companyNameController,
                            decoration: const InputDecoration(labelText: 'Company Name *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: taglineController,
                            decoration: const InputDecoration(labelText: 'Tagline *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(labelText: 'Description *'),
                            maxLines: 4,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: missionController,
                            decoration: const InputDecoration(labelText: 'Mission *'),
                            maxLines: 3,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: visionController,
                            decoration: const InputDecoration(labelText: 'Vision *'),
                            maxLines: 3,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ratingController,
                                  decoration: const InputDecoration(labelText: 'Rating'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: establishedYearController,
                                  decoration: const InputDecoration(labelText: 'Established Year'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(labelText: 'Phone'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: addressController,
                            decoration: const InputDecoration(labelText: 'Address'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const Text('Social Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: facebookController,
                            decoration: const InputDecoration(labelText: 'Facebook URL'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: instagramController,
                            decoration: const InputDecoration(labelText: 'Instagram URL'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: whatsappController,
                            decoration: const InputDecoration(labelText: 'WhatsApp URL'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: youtubeController,
                            decoration: const InputDecoration(labelText: 'YouTube URL'),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const Text('Why Choose Us (comma-separated)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: whyChooseUsController,
                            decoration: const InputDecoration(hintText: 'Item 1, Item 2, Item 3...'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text('Services (comma-separated, use | for subtitle)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Format: Title | Subtitle (e.g. Hotel | We can share hotel etc., Visa | Visa processing)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: servicesController,
                            decoration: const InputDecoration(hintText: 'Hotel | We can share hotel etc., Visa | Visa processing...'),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  final whyChooseUs = whyChooseUsController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                  // Parse services: "Title | Subtitle" or just "Title"
                                  final services = <Map<String, String>>[];
                                  for (final part in servicesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
                                    final pipeIdx = part.indexOf('|');
                                    if (pipeIdx >= 0) {
                                      services.add({
                                        'title': part.substring(0, pipeIdx).trim(),
                                        'subtitle': part.substring(pipeIdx + 1).trim(),
                                      });
                                    } else {
                                      services.add({'title': part, 'subtitle': ''});
                                    }
                                  }

                                  final aboutUsData = {
                                    'companyName': companyNameController.text,
                                    'tagline': taglineController.text,
                                    'description': descriptionController.text,
                                    'mission': missionController.text,
                                    'vision': visionController.text,
                                    'rating': double.tryParse(ratingController.text) ?? 0.0,
                                    'establishedYear': int.tryParse(establishedYearController.text) ?? 0,
                                    'contact': {
                                      'phone': phoneController.text,
                                      'email': emailController.text,
                                      'address': addressController.text,
                                    },
                                    'socialLinks': {
                                      'facebook': facebookController.text,
                                      'instagram': instagramController.text,
                                      'whatsapp': whatsappController.text,
                                      'youtube': youtubeController.text,
                                    },
                                    'whyChooseUs': whyChooseUs,
                                    'services': services,
                                    if (_aboutUs != null && _aboutUs!['documents'] != null) 'documents': _aboutUs!['documents'],
                                    if (_aboutUs != null && _aboutUs!['employees'] != null) 'employees': _aboutUs!['employees'],
                                  };

                                  await widget.dbRef.child('about_us').set(aboutUsData);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('About Us updated successfully')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDocumentDialog() {
    final formKey = GlobalKey<FormState>();
    final documentUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width > 500 ? 500 : MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: documentUrlController,
                  decoration: const InputDecoration(labelText: 'Document URL or Name *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final documents = List<String>.from(_aboutUs?['documents'] ?? []);
                            documents.add(documentUrlController.text);
                            await widget.dbRef.child('about_us').child('documents').set(documents);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Document added')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDocument(int index) async {
    try {
      final documents = List<String>.from(_aboutUs?['documents'] ?? []);
      documents.removeAt(index);
      await widget.dbRef.child('about_us').child('documents').set(documents);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddEmployeeDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final designationController = TextEditingController();
    final quoteController = TextEditingController();
    final experienceController = TextEditingController();
    final selectedImage = ValueNotifier<_PickedImage?>(null);
    final isUploading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Add Employee',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Name *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: designationController,
                            decoration: const InputDecoration(labelText: 'Designation *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: quoteController,
                            decoration: const InputDecoration(labelText: 'Quote *'),
                            maxLines: 3,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: experienceController,
                            decoration: const InputDecoration(labelText: 'Experience (e.g., "5+ years" or "10 years in travel industry")'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          const Text('Employee Photo *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<_PickedImage?>(
                            valueListenable: selectedImage,
                            builder: (context, image, _) {
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      _PickedImage? picked;
                                      if (kIsWeb) {
                                        final result = await picker.pickImage(source: ImageSource.gallery);
                                        if (result != null) {
                                          final bytes = await result.readAsBytes();
                                          picked = _PickedImage(bytes: bytes, name: result.name);
                                        }
                                      } else {
                                        final result = await picker.pickImage(source: ImageSource.gallery);
                                        if (result != null) {
                                          picked = _PickedImage(file: File(result.path));
                                        }
                                      }
                                      if (picked != null) {
                                        selectedImage.value = picked;
                                      }
                                    },
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: image != null
                                          ? (kIsWeb && image.bytes != null
                                              ? Image.memory(image.bytes!, fit: BoxFit.cover)
                                              : image.file != null
                                                  ? Image.file(image.file!, fit: BoxFit.cover)
                                                  : const Icon(Icons.person, size: 80))
                                          : const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_photo_alternate, size: 50),
                                                SizedBox(height: 8),
                                                Text('Tap to add photo'),
                                              ],
                                            ),
                                    ),
                                  ),
                                  if (image != null)
                                    TextButton(
                                      onPressed: () => selectedImage.value = null,
                                      child: const Text('Remove Photo'),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          ValueListenableBuilder<bool>(
                            valueListenable: isUploading,
                            builder: (context, uploading, _) {
                              return ElevatedButton(
                                onPressed: uploading
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          if (selectedImage.value == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please select a photo')),
                                            );
                                            return;
                                          }
                                          setDialogState(() {
                                            isUploading.value = true;
                                          });
                                          try {
                                            String? imageUrl;
                                            if (kIsWeb && selectedImage.value!.bytes != null) {
                                              imageUrl = await CloudinaryService.uploadImageFromBytes(
                                                selectedImage.value!.bytes!,
                                                selectedImage.value!.name ?? 'employee_${DateTime.now().millisecondsSinceEpoch}',
                                                folder: 'employees',
                                              );
                                            } else if (selectedImage.value!.file != null) {
                                              imageUrl = await CloudinaryService.uploadImage(
                                                selectedImage.value!.file!,
                                                folder: 'employees',
                                              );
                                            }

                                            if (imageUrl == null || imageUrl.isEmpty) {
                                              throw Exception('Failed to upload image');
                                            }

                                            // Calculate rank (next highest rank)
                                            final currentEmployees = _employees.values.toList();
                                            final maxRank = currentEmployees.isEmpty
                                                ? 0
                                                : (currentEmployees.map((e) => (e['rank'] as int?) ?? 0).reduce((a, b) => a > b ? a : b));
                                            final newRank = maxRank + 1;

                                            final employeeData = {
                                              'name': nameController.text,
                                              'designation': designationController.text,
                                              'pictureUrl': imageUrl,
                                              'quote': quoteController.text,
                                              'experience': experienceController.text,
                                              'rank': newRank,
                                            };

                                            await widget.dbRef.child('about_us').child('employees').push().set(employeeData);
                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Employee added successfully')),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e')),
                                              );
                                            }
                                          } finally {
                                            setDialogState(() {
                                              isUploading.value = false;
                                            });
                                          }
                                        }
                                      },
                                child: uploading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Add Employee'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditEmployeeDialog(String id) {
    final employee = _employees[id];
    if (employee == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee['name']?.toString() ?? '');
    final designationController = TextEditingController(text: employee['designation']?.toString() ?? '');
    final quoteController = TextEditingController(text: employee['quote']?.toString() ?? '');
    final experienceController = TextEditingController(text: employee['experience']?.toString() ?? '');
    final selectedImage = ValueNotifier<_PickedImage?>(null);
    final isUploading = ValueNotifier<bool>(false);
    final existingPictureUrl = employee['pictureUrl']?.toString();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit Employee',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Name *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: designationController,
                            decoration: const InputDecoration(labelText: 'Designation *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: quoteController,
                            decoration: const InputDecoration(labelText: 'Quote *'),
                            maxLines: 3,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: experienceController,
                            decoration: const InputDecoration(labelText: 'Experience (e.g., "5+ years" or "10 years in travel industry")'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          const Text('Employee Photo (optional - leave as is or change)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<_PickedImage?>(
                            valueListenable: selectedImage,
                            builder: (context, image, _) {
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      _PickedImage? picked;
                                      if (kIsWeb) {
                                        final result = await picker.pickImage(source: ImageSource.gallery);
                                        if (result != null) {
                                          final bytes = await result.readAsBytes();
                                          picked = _PickedImage(bytes: bytes, name: result.name);
                                        }
                                      } else {
                                        final result = await picker.pickImage(source: ImageSource.gallery);
                                        if (result != null) {
                                          picked = _PickedImage(file: File(result.path));
                                        }
                                      }
                                      if (picked != null) {
                                        selectedImage.value = picked;
                                      }
                                    },
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: image != null
                                          ? (kIsWeb && image.bytes != null
                                              ? Image.memory(image.bytes!, fit: BoxFit.cover)
                                              : image.file != null
                                                  ? Image.file(image.file!, fit: BoxFit.cover)
                                                  : const Icon(Icons.person, size: 80))
                                          : (existingPictureUrl != null && existingPictureUrl.isNotEmpty
                                              ? Image.network(
                                                  existingPictureUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80),
                                                )
                                              : const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.add_photo_alternate, size: 50),
                                                    SizedBox(height: 8),
                                                    Text('Tap to add photo'),
                                                  ],
                                                )),
                                    ),
                                  ),
                                  if (image != null)
                                    TextButton(
                                      onPressed: () => selectedImage.value = null,
                                      child: const Text('Remove New Photo'),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          ValueListenableBuilder<bool>(
                            valueListenable: isUploading,
                            builder: (context, uploading, _) {
                              return ElevatedButton(
                                onPressed: uploading
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          setDialogState(() {
                                            isUploading.value = true;
                                          });
                                          try {
                                            String? imageUrl = existingPictureUrl;
                                            if (selectedImage.value != null) {
                                              if (kIsWeb && selectedImage.value!.bytes != null) {
                                                imageUrl = await CloudinaryService.uploadImageFromBytes(
                                                  selectedImage.value!.bytes!,
                                                  selectedImage.value!.name ?? 'employee_${DateTime.now().millisecondsSinceEpoch}',
                                                  folder: 'employees',
                                                );
                                              } else if (selectedImage.value!.file != null) {
                                                imageUrl = await CloudinaryService.uploadImage(
                                                  selectedImage.value!.file!,
                                                  folder: 'employees',
                                                );
                                              }
                                              if (imageUrl == null || imageUrl.isEmpty) {
                                                throw Exception('Failed to upload image');
                                              }
                                            }

                                            final employeeData = {
                                              'name': nameController.text,
                                              'designation': designationController.text,
                                              'pictureUrl': imageUrl ?? '',
                                              'quote': quoteController.text,
                                              'experience': experienceController.text,
                                              'rank': employee['rank'] ?? 0,
                                            };

                                            await widget.dbRef.child('about_us').child('employees').child(id).set(employeeData);
                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Employee updated successfully')),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e')),
                                              );
                                            }
                                          } finally {
                                            setDialogState(() {
                                              isUploading.value = false;
                                            });
                                          }
                                        }
                                      },
                                child: uploading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Save Changes'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEmployee(String id) async {
    try {
      await widget.dbRef.child('about_us').child('employees').child(id).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reorderEmployees(int oldIndex, int newIndex) async {
    final employeesList = _employees.entries.toList()
      ..sort((a, b) {
        final rankA = (a.value['rank'] as int?) ?? 0;
        final rankB = (b.value['rank'] as int?) ?? 0;
        return rankA.compareTo(rankB);
      });

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = employeesList.removeAt(oldIndex);
    employeesList.insert(newIndex, item);

    try {
      await Future.wait(
        employeesList.asMap().entries.map((e) {
          final rank = e.key;
          final entry = e.value;
          return widget.dbRef
              .child('about_us')
              .child('employees')
              .child(entry.key)
              .child('rank')
              .set(rank);
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee order updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final documents = List<String>.from(_aboutUs?['documents'] ?? []);
    final employeesList = _employees.entries.toList()
      ..sort((a, b) {
        final rankA = (a.value['rank'] as int?) ?? 0;
        final rankB = (b.value['rank'] as int?) ?? 0;
        return rankA.compareTo(rankB);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edit About Us Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About Us Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_aboutUs?['companyName'] ?? 'Not set'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showEditAboutUsDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit About Us'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Documents Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showAddDocumentDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Document'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (documents.isEmpty)
                    const Text('No documents added yet')
                  else
                    ...documents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      return ListTile(
                        leading: const Icon(Icons.description),
                        title: Text(doc),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Document'),
                                content: const Text('Are you sure you want to delete this document?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteDocument(index);
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Employees Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Employees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showAddEmployeeDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Employee'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (employeesList.isEmpty)
                    const Text('No employees added yet')
                  else
                    ReorderableListView(
                      buildDefaultDragHandles: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reorderEmployees,
                      children: employeesList.asMap().entries.map((e) {
                        final index = e.key;
                        final entry = e.value;
                        final employee = entry.value;
                        return Card(
                          key: ValueKey(entry.key),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Tooltip(
                                    message: 'Drag to reorder',
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12, top: 4),
                                      child: Icon(Icons.drag_handle, color: Colors.grey[600], size: 28),
                                    ),
                                  ),
                                ),
                                // Photo on left
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: employee['pictureUrl'] != null && employee['pictureUrl'].toString().isNotEmpty
                                        ? Image.network(
                                            employee['pictureUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50),
                                          )
                                        : const Icon(Icons.person, size: 50),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Details on right
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        employee['designation'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (employee['experience'] != null && employee['experience'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              employee['experience'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Text(
                                          '"${employee['quote'] ?? ''}"',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rank: ${employee['rank'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit and Delete buttons
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditEmployeeDialog(entry.key),
                                  tooltip: 'Edit Employee',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Employee'),
                                        content: const Text('Are you sure you want to delete this employee?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteEmployee(entry.key);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
