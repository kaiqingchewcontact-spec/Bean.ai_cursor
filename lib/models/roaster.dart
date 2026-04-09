import 'package:equatable/equatable.dart';

class Roaster extends Equatable {
  final String id;
  final String name;
  final String? location;
  final String? website;
  final String? description;
  final String? logoUrl;
  final String? imageUrl;
  final double rating;
  final int beanCount;
  final List<String> specialties;
  final bool isPartner;
  final String? promoCode;
  final Map<String, dynamic>? subscriptionInfo;

  const Roaster({
    required this.id,
    required this.name,
    this.location,
    this.website,
    this.description,
    this.logoUrl,
    this.imageUrl,
    this.rating = 0,
    this.beanCount = 0,
    this.specialties = const [],
    this.isPartner = false,
    this.promoCode,
    this.subscriptionInfo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'website': website,
    'description': description,
    'logoUrl': logoUrl,
    'imageUrl': imageUrl,
    'rating': rating,
    'beanCount': beanCount,
    'specialties': specialties,
    'isPartner': isPartner,
    'promoCode': promoCode,
    'subscriptionInfo': subscriptionInfo,
  };

  factory Roaster.fromJson(Map<String, dynamic> json) => Roaster(
    id: json['id'] as String,
    name: json['name'] as String,
    location: json['location'] as String?,
    website: json['website'] as String?,
    description: json['description'] as String?,
    logoUrl: json['logoUrl'] as String?,
    imageUrl: json['imageUrl'] as String?,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    beanCount: json['beanCount'] as int? ?? 0,
    specialties: (json['specialties'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    isPartner: json['isPartner'] as bool? ?? false,
    promoCode: json['promoCode'] as String?,
    subscriptionInfo: json['subscriptionInfo'] as Map<String, dynamic>?,
  );

  @override
  List<Object?> get props => [id];
}

class Subscription extends Equatable {
  final String id;
  final String roasterId;
  final String roasterName;
  final String planName;
  final double pricePerMonth;
  final DateTime nextDelivery;
  final DateTime? lastDelivery;
  final bool isActive;
  final double? valueRating;

  const Subscription({
    required this.id,
    required this.roasterId,
    required this.roasterName,
    required this.planName,
    required this.pricePerMonth,
    required this.nextDelivery,
    this.lastDelivery,
    this.isActive = true,
    this.valueRating,
  });

  int get daysUntilNext => nextDelivery.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'roasterId': roasterId,
    'roasterName': roasterName,
    'planName': planName,
    'pricePerMonth': pricePerMonth,
    'nextDelivery': nextDelivery.toIso8601String(),
    'lastDelivery': lastDelivery?.toIso8601String(),
    'isActive': isActive,
    'valueRating': valueRating,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    roasterId: json['roasterId'] as String,
    roasterName: json['roasterName'] as String,
    planName: json['planName'] as String,
    pricePerMonth: (json['pricePerMonth'] as num).toDouble(),
    nextDelivery: DateTime.parse(json['nextDelivery'] as String),
    lastDelivery: json['lastDelivery'] != null
        ? DateTime.parse(json['lastDelivery'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
    valueRating: (json['valueRating'] as num?)?.toDouble(),
  );

  @override
  List<Object?> get props => [id];
}
