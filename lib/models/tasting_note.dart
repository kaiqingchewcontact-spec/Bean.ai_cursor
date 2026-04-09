import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class TastingNote extends Equatable {
  final String id;
  final String? brewId;
  final String? beanId;
  final DateTime createdAt;
  final double overallScore;
  final double aroma;
  final double acidity;
  final double sweetness;
  final double body;
  final double balance;
  final double aftertaste;
  final double cleanliness;
  final List<String> descriptors;
  final String? notes;
  final String? imageUrl;
  final Map<String, dynamic>? aiSummary;

  TastingNote({
    String? id,
    this.brewId,
    this.beanId,
    DateTime? createdAt,
    this.overallScore = 0,
    this.aroma = 0,
    this.acidity = 0,
    this.sweetness = 0,
    this.body = 0,
    this.balance = 0,
    this.aftertaste = 0,
    this.cleanliness = 0,
    this.descriptors = const [],
    this.notes,
    this.imageUrl,
    this.aiSummary,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, double> get radarData => {
    'Aroma': aroma,
    'Acidity': acidity,
    'Sweetness': sweetness,
    'Body': body,
    'Balance': balance,
    'Aftertaste': aftertaste,
    'Clean': cleanliness,
  };

  TastingNote copyWith({
    String? brewId,
    String? beanId,
    double? overallScore,
    double? aroma,
    double? acidity,
    double? sweetness,
    double? body,
    double? balance,
    double? aftertaste,
    double? cleanliness,
    List<String>? descriptors,
    String? notes,
    String? imageUrl,
    Map<String, dynamic>? aiSummary,
  }) {
    return TastingNote(
      id: id,
      brewId: brewId ?? this.brewId,
      beanId: beanId ?? this.beanId,
      createdAt: createdAt,
      overallScore: overallScore ?? this.overallScore,
      aroma: aroma ?? this.aroma,
      acidity: acidity ?? this.acidity,
      sweetness: sweetness ?? this.sweetness,
      body: body ?? this.body,
      balance: balance ?? this.balance,
      aftertaste: aftertaste ?? this.aftertaste,
      cleanliness: cleanliness ?? this.cleanliness,
      descriptors: descriptors ?? this.descriptors,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brewId': brewId,
    'beanId': beanId,
    'createdAt': createdAt.toIso8601String(),
    'overallScore': overallScore,
    'aroma': aroma,
    'acidity': acidity,
    'sweetness': sweetness,
    'body': body,
    'balance': balance,
    'aftertaste': aftertaste,
    'cleanliness': cleanliness,
    'descriptors': descriptors,
    'notes': notes,
    'imageUrl': imageUrl,
    'aiSummary': aiSummary,
  };

  factory TastingNote.fromJson(Map<String, dynamic> json) => TastingNote(
    id: json['id'] as String,
    brewId: json['brewId'] as String?,
    beanId: json['beanId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
    aroma: (json['aroma'] as num?)?.toDouble() ?? 0,
    acidity: (json['acidity'] as num?)?.toDouble() ?? 0,
    sweetness: (json['sweetness'] as num?)?.toDouble() ?? 0,
    body: (json['body'] as num?)?.toDouble() ?? 0,
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    aftertaste: (json['aftertaste'] as num?)?.toDouble() ?? 0,
    cleanliness: (json['cleanliness'] as num?)?.toDouble() ?? 0,
    descriptors: (json['descriptors'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    notes: json['notes'] as String?,
    imageUrl: json['imageUrl'] as String?,
    aiSummary: json['aiSummary'] as Map<String, dynamic>?,
  );

  @override
  List<Object?> get props => [id];
}
