import 'package:cloud_firestore/cloud_firestore.dart';

class TripFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tripsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('trips');
  }

  Future<String> saveTrip({
    required String userId,
    required String vehicleId,
    required String vehicleName,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    required double distanceKm,
    required double averageSpeedKmh,
    required double maxSpeedKmh,
    required int driverScore,
    required int harshEvents,
    required int overspeedEvents,
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final doc = await _tripsCollection(userId).add({
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'durationSeconds': durationSeconds,
      'distanceKm': distanceKm,
      'averageSpeedKmh': averageSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'driverScore': driverScore,
      'harshEvents': harshEvents,
      'overspeedEvents': overspeedEvents,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'createdAt': Timestamp.now(),
    });

    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTrips(String userId) {
    return _tripsCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots();
  }

  Future<void> deleteTrip({
    required String userId,
    required String tripId,
  }) async {
    await _tripsCollection(userId).doc(tripId).delete();
  }
}