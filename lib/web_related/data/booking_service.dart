import 'package:firebase_database/firebase_database.dart';

class BookingService {
  final DatabaseReference _bookingsRef =
      FirebaseDatabase.instance.ref().child('bookings');

  Future<void> submitBooking(Map<String, dynamic> bookingData) async {
    try {
      // Generate a unique key for the booking
      final newBookingRef = _bookingsRef.push();
      await newBookingRef.set(bookingData);
    } catch (e) {
      throw Exception('Failed to submit booking: $e');
    }
  }

  // Optional: Get all bookings (for admin purposes)
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final snapshot = await _bookingsRef.get();
      if (snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final bookings = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final booking = Map<String, dynamic>.from(value as Map);
        booking['bookingId'] = key;
        bookings.add(booking);
      });

      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }
}
