class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String role;
  final bool isActive;
  final String? provider;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.role = 'user',
    this.isActive = true,
    this.provider,
    this.preferences,
  });

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'role': role,
      'isActive': isActive,
      'provider': provider,
      'preferences': preferences ?? {},
    };
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] ?? 0),
      role: map['role'] ?? 'user',
      isActive: map['isActive'] ?? true,
      provider: map['provider'],
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? role,
    bool? isActive,
    String? provider,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      provider: provider ?? this.provider,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// Street Light Model
class StreetLightModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status; // on, off, faulty, maintenance
  final int brightness; // 0-100
  final DateTime lastUpdated;
  final String? area;
  final String? ward;
  final double? powerConsumption;
  final bool isScheduled;
  final Map<String, dynamic>? schedule;

  StreetLightModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.brightness = 100,
    required this.lastUpdated,
    this.area,
    this.ward,
    this.powerConsumption,
    this.isScheduled = false,
    this.schedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'brightness': brightness,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'area': area,
      'ward': ward,
      'powerConsumption': powerConsumption,
      'isScheduled': isScheduled,
      'schedule': schedule ?? {},
    };
  }

  factory StreetLightModel.fromMap(Map<String, dynamic> map) {
    return StreetLightModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'off',
      brightness: (map['brightness'] ?? 100).toInt(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      area: map['area'],
      ward: map['ward'],
      powerConsumption: map['powerConsumption']?.toDouble(),
      isScheduled: map['isScheduled'] ?? false,
      schedule: Map<String, dynamic>.from(map['schedule'] ?? {}),
    );
  }

  StreetLightModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? status,
    int? brightness,
    DateTime? lastUpdated,
    String? area,
    String? ward,
    double? powerConsumption,
    bool? isScheduled,
    Map<String, dynamic>? schedule,
  }) {
    return StreetLightModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      brightness: brightness ?? this.brightness,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      area: area ?? this.area,
      ward: ward ?? this.ward,
      powerConsumption: powerConsumption ?? this.powerConsumption,
      isScheduled: isScheduled ?? this.isScheduled,
      schedule: schedule ?? this.schedule,
    );
  }
}
