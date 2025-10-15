import 'package:cloud_firestore/cloud_firestore.dart';

class StreetLightDemoData {
  static Future<void> createDemoData() async {
    final firestore = FirebaseFirestore.instance;

    // Demo street lights data
    final demoLights = [
      {
        'name': 'Anna Nagar Main Street Light 1',
        'location': 'Anna Nagar, Chennai, Tamil Nadu',
        'type': 'LED',
        'brightness': 85,
        'status': 'Active',
        'autoSchedule': true,
        'notes': 'Main junction light - high priority',
        'createdAt': Timestamp.now(),
        'latitude': 13.0850,
        'longitude': 80.2101,
      },
      {
        'name': 'T. Nagar Bus Stop Light',
        'location': 'T. Nagar, Chennai, Tamil Nadu',
        'type': 'LED',
        'brightness': 90,
        'status': 'Active',
        'autoSchedule': true,
        'notes': 'Bus stop area lighting',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 2)),
        ),
        'latitude': 13.0418,
        'longitude': 80.2341,
      },
      {
        'name': 'Marina Beach Pathway Light 3',
        'location': 'Marina Beach, Chennai, Tamil Nadu',
        'type': 'Solar LED',
        'brightness': 75,
        'status': 'Maintenance',
        'autoSchedule': false,
        'notes': 'Needs battery replacement',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 5)),
        ),
        'latitude': 13.0475,
        'longitude': 80.2824,
      },
      {
        'name': 'Velachery IT Park Light',
        'location': 'Velachery, Chennai, Tamil Nadu',
        'type': 'LED',
        'brightness': 95,
        'status': 'Active',
        'autoSchedule': true,
        'notes': 'Recently installed high-efficiency light',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 1)),
        ),
        'latitude': 12.9756,
        'longitude': 80.2207,
      },
      {
        'name': 'Adyar River Bridge Light',
        'location': 'Adyar, Chennai, Tamil Nadu',
        'type': 'Halogen',
        'brightness': 60,
        'status': 'Inactive',
        'autoSchedule': false,
        'notes': 'Power supply issue - needs repair',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 7)),
        ),
        'latitude': 13.0067,
        'longitude': 80.2206,
      },
      {
        'name': 'Egmore Railway Station Light',
        'location': 'Egmore, Chennai, Tamil Nadu',
        'type': 'LED',
        'brightness': 100,
        'status': 'Active',
        'autoSchedule': true,
        'notes': 'Critical infrastructure lighting',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: 3)),
        ),
        'latitude': 13.0732,
        'longitude': 80.2609,
      },
    ];

    try {
      // Add demo data to Firestore
      for (final light in demoLights) {
        await firestore.collection('street_lights').add(light);
      }
      print('Demo street lights data created successfully!');
    } catch (e) {
      print('Error creating demo data: $e');
    }
  }

  static Future<void> clearDemoData() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final querySnapshot = await firestore.collection('street_lights').get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('Demo street lights data cleared successfully!');
    } catch (e) {
      print('Error clearing demo data: $e');
    }
  }
}
