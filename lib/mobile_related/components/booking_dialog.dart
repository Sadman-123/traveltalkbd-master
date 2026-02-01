import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:traveltalkbd/services/cloudinary_service.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import '../data/booking_service.dart';
import '../data/travel_models.dart';

class BookingDialog extends StatefulWidget {
  final String itemId;
  final String itemTitle;
  final String itemType;
  final VisaPackage? visaPackage;
  final String? itemImageUrl;

  const BookingDialog({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.itemType,
    this.visaPackage,
    this.itemImageUrl,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _peopleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  XFile? _visaPhoto;
  bool _isUploadingPhoto = false;
  String? _selectedVisaEntryKey;

  @override
  void initState() {
    super.initState();
    if (widget.itemType == 'visa' && widget.visaPackage != null && widget.visaPackage!.hasEntryTypes) {
      final sorted = widget.visaPackage!.sortedEnabledEntryTypes;
      if (sorted.isNotEmpty) {
        _selectedVisaEntryKey = sorted.first.key;
      }
    }
    _prefillFromAuth();
  }

  void _prefillFromAuth() {
    final user = AuthService().currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';
      AuthService().getCurrentUserProfile().then((p) {
        if (mounted && p != null) {
          final phone = p['phone'] as String?;
          if (phone != null && phone.isNotEmpty) {
            _phoneController.text = phone;
          }
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  String? _validatePeople(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter number of people';
    }
    final count = int.tryParse(value);
    if (count == null || count < 1) {
      return 'Please enter a valid number (at least 1)';
    }
    return null;
  }

  Future<void> _pickVisaPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _visaPhoto = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For visa bookings, require visa photo
    if (widget.itemType == 'visa' && _visaPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your visa photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isUploadingPhoto = widget.itemType == 'visa' && _visaPhoto != null;
    });

    try {
      String? visaPhotoUrl;
      
      // Upload visa photo if it's a visa booking
      if (widget.itemType == 'visa' && _visaPhoto != null) {
        try {
          if (kIsWeb) {
            final bytes = await _visaPhoto!.readAsBytes();
            visaPhotoUrl = await CloudinaryService.uploadImageFromBytes(
              bytes,
              _visaPhoto!.name.isNotEmpty 
                  ? _visaPhoto!.name 
                  : 'visa_photo_${DateTime.now().millisecondsSinceEpoch}',
              folder: 'visa_bookings',
            );
          } else {
            final file = File(_visaPhoto!.path);
            visaPhotoUrl = await CloudinaryService.uploadImage(
              file,
              folder: 'visa_bookings',
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading visa photo: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isSubmitting = false;
            _isUploadingPhoto = false;
          });
          return;
        }
      }

      setState(() {
        _isUploadingPhoto = false;
      });

      final userId = AuthService().currentUserId;
      final bookingData = {
        'itemId': widget.itemId,
        'itemTitle': widget.itemTitle,
        'itemType': widget.itemType,
        if (userId != null) 'userId': userId,
        if (widget.itemImageUrl != null && widget.itemImageUrl!.isNotEmpty) 'itemImageUrl': widget.itemImageUrl,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'numberOfPeople': int.parse(_peopleController.text.trim()),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'notes': _notesController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        if (visaPhotoUrl != null) 'visaPhotoUrl': visaPhotoUrl,
        if (_selectedVisaEntryKey != null) 'visaEntryType': _selectedVisaEntryKey,
        if (_selectedVisaEntryKey != null) 'visaEntryTypeLabel': VisaPackage.formatEntryTypeLabel(_selectedVisaEntryKey!),
      };

      // Import and use the booking service
      final bookingService = BookingService();
      await bookingService.submitBooking(bookingData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking submitted successfully! Please wait for confirmation.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _peopleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Book Now',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.itemTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (widget.itemType == 'visa' && widget.visaPackage != null && widget.visaPackage!.hasEntryTypes) ...[
                  const SizedBox(height: 16),
                  _VisaEntrySelector(
                    visaPackage: widget.visaPackage!,
                    selectedKey: _selectedVisaEntryKey,
                    onChanged: _isSubmitting ? null : (v) => setState(() => _selectedVisaEntryKey = v),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please select visa entry type';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateRequired(value, 'name'),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _peopleController,
                  decoration: const InputDecoration(
                    labelText: 'Number of People',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validatePeople,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isSubmitting ? null : () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Select date'
                              : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !_isSubmitting,
                ),
                // Visa Photo Upload Section (only for visa bookings)
                if (widget.itemType == 'visa') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Passport Photo *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isSubmitting ? null : _pickVisaPhoto,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: _visaPhoto == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload visa photo',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: kIsWeb
                                      ? FutureBuilder<Uint8List>(
                                          future: _visaPhoto!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                width: double.infinity,
                                                height: 150,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return const Center(
                                              child: CircularProgressIndicator(),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(_visaPhoto!.path),
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _visaPhoto = null;
                                            });
                                          },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              if (_isUploadingPhoto) ...[
                                const SizedBox(width: 12),
                                const Text(
                                  'Uploading photo...',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          )
                        : const Text(
                            'Submit Booking',
                            style: TextStyle(fontSize: 16),
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
}

/// Decorated visa entry type selector with selectable cards (mobile layout)
class _VisaEntrySelector extends StatelessWidget {
  final VisaPackage visaPackage;
  final String? selectedKey;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;

  const _VisaEntrySelector({
    required this.visaPackage,
    required this.selectedKey,
    required this.onChanged,
    required this.validator,
  });

  static IconData _iconForEntryType(String key) {
    switch (key) {
      case 'singleEntry': return Icons.looks_one_rounded;
      case 'doubleEntry': return Icons.looks_two_rounded;
      case 'multipleEntry': return Icons.all_inclusive_rounded;
      default: return Icons.flight_land_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: selectedKey,
      validator: validator,
      builder: (field) {
        final effectiveValue = field.value ?? selectedKey;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.accent.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Visa Entry Type',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...visaPackage.sortedEnabledEntryTypes.map((e) {
                    final isSelected = effectiveValue == e.key;
                    final label = VisaPackage.formatEntryTypeLabel(e.key);
                    num displayPrice = e.value.price;
                    if (visaPackage.discountEnabled && visaPackage.discountPercent > 0) {
                      displayPrice = (e.value.price * (1 - visaPackage.discountPercent / 100)).clamp(0, double.infinity);
                    } else if (visaPackage.discountEnabled && visaPackage.discountAmount > 0) {
                      displayPrice = (e.value.price - visaPackage.discountAmount).clamp(0, double.infinity);
                    }
                    final price = '${visaPackage.currency} ${displayPrice.toStringAsFixed(0)}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onChanged == null ? null : () {
                            field.didChange(e.key);
                            onChanged!(e.key);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.accent : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForEntryType(e.key),
                                  size: 26,
                                  color: isSelected ? AppColors.accent : Colors.grey[600],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isSelected ? AppColors.primary : Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        price,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? AppColors.accent : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}
