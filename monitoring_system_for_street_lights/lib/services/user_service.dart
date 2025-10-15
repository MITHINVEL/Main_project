import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required User firebaseUser,
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: displayName ?? firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        role: 'user',
        isActive: true,
        preferences: {
          'theme': 'light',
          'notifications': true,
          'language': 'en',
          ...?additionalData,
        },
      );

      await _usersCollection.doc(firebaseUser.uid).set(userModel.toMap());

      print('User profile created successfully for: ${firebaseUser.email}');
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    Map<String, dynamic>? updates,
  }) async {
    try {
      final updateData = {
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
        ...?updates,
      };

      await _usersCollection.doc(uid).update(updateData);
      print('User profile updated successfully for UID: $uid');
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Get user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print('User profile not found for UID: $uid');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get user profile by email
  Future<UserModel?> getUserProfileByEmail(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      } else {
        print('User profile not found for email: $email');
        return null;
      }
    } catch (e) {
      print('Error getting user profile by email: $e');
      return null;
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return await getUserProfile(currentUser.uid);
    }
    return null;
  }

  // Update user preferences
  Future<void> updateUserPreferences({
    required String uid,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'preferences': preferences,
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('User preferences updated successfully');
    } catch (e) {
      print('Error updating user preferences: $e');
      throw e;
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      print('User profile deleted successfully for UID: $uid');
    } catch (e) {
      print('Error deleting user profile: $e');
      throw e;
    }
  }

  // Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user profile existence: $e');
      return false;
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final query = await _usersCollection
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Stream user profile changes
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Stream current user profile
  Stream<UserModel?> streamCurrentUserProfile() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return streamUserProfile(currentUser.uid);
    } else {
      return Stream.value(null);
    }
  }

  // Update user's last login time with Firebase Auth data
  Future<void> updateUserLastLogin(User user) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'User',
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'isEmailVerified': user.emailVerified,
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'email',
        'role': 'user',
        'isActive': true,
      };

      await _usersCollection
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
      print('User login data updated successfully');
    } catch (e) {
      print('Error updating user login data: $e');
      throw Exception('Failed to update user login time: $e');
    }
  }
}
