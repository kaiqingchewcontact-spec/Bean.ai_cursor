import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Bean extends Equatable {
  final String id;
  final String name;
  final String roaster;
  final String origin;
  final String? region;
  final String? farm;
  final String? varietal;
  final String process;
  final String roastLevel;
  final DateTime? roastDate;
  final DateTime addedDate;
  final double? price;
  final double? weightGrams;
  final List<String> tastingNotes;
  final String? description;
  final String? imageUrl;
  final String? barcode;
  final double? elevation;
  final double rating;
  final int brewCount;
  final bool isFavorite;
  final bool isArchived;
  final Map<String, dynamic>? aiAnalysis;

  Bean({
    String? id,
    required this.name,
    required this.roaster,
    required this.origin,
    this.region,
    this.farm,
    this.varietal,
    this.process = 'Washed',
    this.roastLevel = 'Medium',
    this.roastDate,
    DateTime? addedDate,
    this.price,
    this.weightGrams,
    this.tastingNotes = const [],
    this.description,
    this.imageUrl,
    this.barcode,
    this.elevation,
    this.rating = 0,
    this.brewCount = 0,
    this.isFavorite = false,
    this.isArchived = false,
    this.aiAnalysis,
  })  : id = id ?? const Uuid().v4(),
        addedDate = addedDate ?? DateTime.now();

  int get daysFromRoast {
    if (roastDate == null) return -1;
    return DateTime.now().difference(roastDate!).inDays;
  }

  String get freshnessLabel {
    final days = daysFromRoast;
    if (days < 0) return 'Unknown';
    if (days <= 3) return 'Resting';
    if (days <= 14) return 'Peak';
    if (days <= 21) return 'Fresh';
    if (days <= 30) return 'Aging';
    return 'Past Peak';
  }

  FreshnessLevel get freshnessLevel {
    final days = daysFromRoast;
    if (days < 0) return FreshnessLevel.unknown;
    if (days <= 3) return FreshnessLevel.resting;
    if (days <= 14) return FreshnessLevel.peak;
    if (days <= 21) return FreshnessLevel.fresh;
    if (days <= 30) return FreshnessLevel.aging;
    return FreshnessLevel.stale;
  }

  double? get costPerCup {
    if (price == null || weightGrams == null || weightGrams == 0) return null;
    const avgGramsPerCup = 18.0;
    return (price! / weightGrams!) * avgGramsPerCup;
  }

  Bean copyWith({
    String? name,
    String? roaster,
    String? origin,
    String? region,
    String? farm,
    String? varietal,
    String? process,
    String? roastLevel,
    DateTime? roastDate,
    double? price,
    double? weightGrams,
    List<String>? tastingNotes,
    String? description,
    String? imageUrl,
    String? barcode,
    double? elevation,
    double? rating,
    int? brewCount,
    bool? isFavorite,
    bool? isArchived,
    Map<String, dynamic>? aiAnalysis,
  }) {
    return Bean(
      id: id,
      name: name ?? this.name,
      roaster: roaster ?? this.roaster,
      origin: origin ?? this.origin,
      region: region ?? this.region,
      farm: farm ?? this.farm,
      varietal: varietal ?? this.varietal,
      process: process ?? this.process,
      roastLevel: roastLevel ?? this.roastLevel,
      roastDate: roastDate ?? this.roastDate,
      addedDate: addedDate,
      price: price ?? this.price,
      weightGrams: weightGrams ?? this.weightGrams,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      elevation: elevation ?? this.elevation,
      rating: rating ?? this.rating,
      brewCount: brewCount ?? this.brewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roaster': roaster,
    'origin': origin,
    'region': region,
    'farm': farm,
    'varietal': varietal,
    'process': process,
    'roastLevel': roastLevel,
    'roastDate': roastDate?.toIso8601String(),
    'addedDate': addedDate.toIso8601String(),
    'price': price,
    'weightGrams': weightGrams,
    'tastingNotes': tastingNotes,
    'description': description,
    'imageUrl': imageUrl,
    'barcode': barcode,
    'elevation': elevation,
    'rating': rating,
    'brewCount': brewCount,
    'isFavorite': isFavorite,
    'isArchived': isArchived,
    'aiAnalysis': aiAnalysis,
  };

  factory Bean.fromJson(Map<String, dynamic> json) => Bean(
    id: json['id'] as String,
    name: json['name'] as String,
    roaster: json['roaster'] as String,
    origin: json['origin'] as String,
    region: json['region'] as String?,
    farm: json['farm'] as String?,
    varietal: json['varietal'] as String?,
    process: json['process'] as String? ?? 'Washed',
    roastLevel: json['roastLevel'] as String? ?? 'Medium',
    roastDate: json['roastDate'] != null
        ? DateTime.parse(json['roastDate'] as String)
        : null,
    addedDate: DateTime.parse(json['addedDate'] as String),
    price: (json['price'] as num?)?.toDouble(),
    weightGrams: (json['weightGrams'] as num?)?.toDouble(),
    tastingNotes: (json['tastingNotes'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    barcode: json['barcode'] as String?,
    elevation: (json['elevation'] as num?)?.toDouble(),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    brewCount: json['brewCount'] as int? ?? 0,
    isFavorite: json['isFavorite'] as bool? ?? false,
    isArchived: json['isArchived'] as bool? ?? false,
    aiAnalysis: json['aiAnalysis'] as Map<String, dynamic>?,
  );

  @override
  List<Object?> get props => [id];
}

enum FreshnessLevel {
  resting,
  peak,
  fresh,
  aging,
  stale,
  unknown,
}
