import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final SubscriptionTier tier;
  final DateTime? subscriptionExpiresAt;
  final UserEquipment equipment;
  final UserPreferences preferences;
  final UserStats stats;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    this.tier = SubscriptionTier.free,
    this.subscriptionExpiresAt,
    this.equipment = const UserEquipment(),
    this.preferences = const UserPreferences(),
    this.stats = const UserStats(),
  });

  bool get isPremium => tier != SubscriptionTier.free;

  bool get isSubscriptionActive {
    if (tier == SubscriptionTier.lifetime) return true;
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    SubscriptionTier? tier,
    DateTime? subscriptionExpiresAt,
    UserEquipment? equipment,
    UserPreferences? preferences,
    UserStats? stats,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      tier: tier ?? this.tier,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      equipment: equipment ?? this.equipment,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'tier': tier.name,
    'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
    'equipment': equipment.toJson(),
    'preferences': preferences.toJson(),
    'stats': stats.toJson(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['displayName'] as String?,
    email: json['email'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    tier: SubscriptionTier.values.byName(json['tier'] as String? ?? 'free'),
    subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
        ? DateTime.parse(json['subscriptionExpiresAt'] as String)
        : null,
    equipment: json['equipment'] != null
        ? UserEquipment.fromJson(json['equipment'] as Map<String, dynamic>)
        : const UserEquipment(),
    preferences: json['preferences'] != null
        ? UserPreferences.fromJson(
            json['preferences'] as Map<String, dynamic>)
        : const UserPreferences(),
    stats: json['stats'] != null
        ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
        : const UserStats(),
  );

  @override
  List<Object?> get props => [id];
}

enum SubscriptionTier { free, monthly, yearly, lifetime }

class UserEquipment extends Equatable {
  final String? primaryBrewer;
  final String? grinder;
  final String? kettle;
  final String? scale;
  final String? waterFilter;
  final List<String> allBrewers;
  final Map<String, dynamic>? waterProfile;

  const UserEquipment({
    this.primaryBrewer,
    this.grinder,
    this.kettle,
    this.scale,
    this.waterFilter,
    this.allBrewers = const [],
    this.waterProfile,
  });

  UserEquipment copyWith({
    String? primaryBrewer,
    String? grinder,
    String? kettle,
    String? scale,
    String? waterFilter,
    List<String>? allBrewers,
    Map<String, dynamic>? waterProfile,
  }) {
    return UserEquipment(
      primaryBrewer: primaryBrewer ?? this.primaryBrewer,
      grinder: grinder ?? this.grinder,
      kettle: kettle ?? this.kettle,
      scale: scale ?? this.scale,
      waterFilter: waterFilter ?? this.waterFilter,
      allBrewers: allBrewers ?? this.allBrewers,
      waterProfile: waterProfile ?? this.waterProfile,
    );
  }

  Map<String, dynamic> toJson() => {
    'primaryBrewer': primaryBrewer,
    'grinder': grinder,
    'kettle': kettle,
    'scale': scale,
    'waterFilter': waterFilter,
    'allBrewers': allBrewers,
    'waterProfile': waterProfile,
  };

  factory UserEquipment.fromJson(Map<String, dynamic> json) => UserEquipment(
    primaryBrewer: json['primaryBrewer'] as String?,
    grinder: json['grinder'] as String?,
    kettle: json['kettle'] as String?,
    scale: json['scale'] as String?,
    waterFilter: json['waterFilter'] as String?,
    allBrewers: (json['allBrewers'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    waterProfile: json['waterProfile'] as Map<String, dynamic>?,
  );

  @override
  List<Object?> get props => [primaryBrewer, grinder, kettle, scale];
}

class UserPreferences extends Equatable {
  final List<String> favoriteOrigins;
  final List<String> favoriteProcesses;
  final List<String> flavorPreferences;
  final String preferredRoastLevel;
  final String preferredBrewMethod;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool communityOptIn;

  const UserPreferences({
    this.favoriteOrigins = const [],
    this.favoriteProcesses = const [],
    this.flavorPreferences = const [],
    this.preferredRoastLevel = 'Medium',
    this.preferredBrewMethod = 'Pour Over (V60)',
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.communityOptIn = true,
  });

  UserPreferences copyWith({
    List<String>? favoriteOrigins,
    List<String>? favoriteProcesses,
    List<String>? flavorPreferences,
    String? preferredRoastLevel,
    String? preferredBrewMethod,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? communityOptIn,
  }) {
    return UserPreferences(
      favoriteOrigins: favoriteOrigins ?? this.favoriteOrigins,
      favoriteProcesses: favoriteProcesses ?? this.favoriteProcesses,
      flavorPreferences: flavorPreferences ?? this.flavorPreferences,
      preferredRoastLevel: preferredRoastLevel ?? this.preferredRoastLevel,
      preferredBrewMethod: preferredBrewMethod ?? this.preferredBrewMethod,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      communityOptIn: communityOptIn ?? this.communityOptIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'favoriteOrigins': favoriteOrigins,
    'favoriteProcesses': favoriteProcesses,
    'flavorPreferences': flavorPreferences,
    'preferredRoastLevel': preferredRoastLevel,
    'preferredBrewMethod': preferredBrewMethod,
    'darkMode': darkMode,
    'notificationsEnabled': notificationsEnabled,
    'communityOptIn': communityOptIn,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        favoriteOrigins: (json['favoriteOrigins'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? [],
        favoriteProcesses: (json['favoriteProcesses'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? [],
        flavorPreferences: (json['flavorPreferences'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? [],
        preferredRoastLevel: json['preferredRoastLevel'] as String? ?? 'Medium',
        preferredBrewMethod:
            json['preferredBrewMethod'] as String? ?? 'Pour Over (V60)',
        darkMode: json['darkMode'] as bool? ?? false,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        communityOptIn: json['communityOptIn'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
    preferredRoastLevel,
    preferredBrewMethod,
    darkMode,
  ];
}

class UserStats extends Equatable {
  final int totalBeans;
  final int totalBrews;
  final int totalTastingNotes;
  final int scanCount;
  final int currentStreak;
  final int longestStreak;
  final double averageRating;
  final Map<String, int> originBreakdown;
  final Map<String, int> methodBreakdown;

  const UserStats({
    this.totalBeans = 0,
    this.totalBrews = 0,
    this.totalTastingNotes = 0,
    this.scanCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.averageRating = 0,
    this.originBreakdown = const {},
    this.methodBreakdown = const {},
  });

  Map<String, dynamic> toJson() => {
    'totalBeans': totalBeans,
    'totalBrews': totalBrews,
    'totalTastingNotes': totalTastingNotes,
    'scanCount': scanCount,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'averageRating': averageRating,
    'originBreakdown': originBreakdown,
    'methodBreakdown': methodBreakdown,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalBeans: json['totalBeans'] as int? ?? 0,
    totalBrews: json['totalBrews'] as int? ?? 0,
    totalTastingNotes: json['totalTastingNotes'] as int? ?? 0,
    scanCount: json['scanCount'] as int? ?? 0,
    currentStreak: json['currentStreak'] as int? ?? 0,
    longestStreak: json['longestStreak'] as int? ?? 0,
    averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    originBreakdown: (json['originBreakdown'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as int)) ?? {},
    methodBreakdown: (json['methodBreakdown'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as int)) ?? {},
  );

  @override
  List<Object?> get props => [totalBeans, totalBrews, totalTastingNotes];
}
