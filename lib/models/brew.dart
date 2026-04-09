import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Brew extends Equatable {
  final String id;
  final String beanId;
  final String method;
  final DateTime brewDate;
  final double doseGrams;
  final double waterMl;
  final double waterTempCelsius;
  final int grindSetting;
  final String? grinder;
  final Duration brewTime;
  final Duration? bloomTime;
  final double? yieldMl;
  final double rating;
  final String? notes;
  final List<String> tastingNotes;
  final String? imageUrl;
  final Map<String, double>? flavorScores;
  final Map<String, dynamic>? aiRecipe;
  final Map<String, dynamic>? aiFeedback;

  Brew({
    String? id,
    required this.beanId,
    required this.method,
    DateTime? brewDate,
    required this.doseGrams,
    required this.waterMl,
    this.waterTempCelsius = 93,
    this.grindSetting = 20,
    this.grinder,
    this.brewTime = const Duration(minutes: 3),
    this.bloomTime,
    this.yieldMl,
    this.rating = 0,
    this.notes,
    this.tastingNotes = const [],
    this.imageUrl,
    this.flavorScores,
    this.aiRecipe,
    this.aiFeedback,
  })  : id = id ?? const Uuid().v4(),
        brewDate = brewDate ?? DateTime.now();

  double get ratio => waterMl / doseGrams;

  String get ratioLabel => '1:${ratio.toStringAsFixed(1)}';

  String get brewTimeLabel {
    final minutes = brewTime.inMinutes;
    final seconds = brewTime.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Brew copyWith({
    String? beanId,
    String? method,
    DateTime? brewDate,
    double? doseGrams,
    double? waterMl,
    double? waterTempCelsius,
    int? grindSetting,
    String? grinder,
    Duration? brewTime,
    Duration? bloomTime,
    double? yieldMl,
    double? rating,
    String? notes,
    List<String>? tastingNotes,
    String? imageUrl,
    Map<String, double>? flavorScores,
    Map<String, dynamic>? aiRecipe,
    Map<String, dynamic>? aiFeedback,
  }) {
    return Brew(
      id: id,
      beanId: beanId ?? this.beanId,
      method: method ?? this.method,
      brewDate: brewDate ?? this.brewDate,
      doseGrams: doseGrams ?? this.doseGrams,
      waterMl: waterMl ?? this.waterMl,
      waterTempCelsius: waterTempCelsius ?? this.waterTempCelsius,
      grindSetting: grindSetting ?? this.grindSetting,
      grinder: grinder ?? this.grinder,
      brewTime: brewTime ?? this.brewTime,
      bloomTime: bloomTime ?? this.bloomTime,
      yieldMl: yieldMl ?? this.yieldMl,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      imageUrl: imageUrl ?? this.imageUrl,
      flavorScores: flavorScores ?? this.flavorScores,
      aiRecipe: aiRecipe ?? this.aiRecipe,
      aiFeedback: aiFeedback ?? this.aiFeedback,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'beanId': beanId,
    'method': method,
    'brewDate': brewDate.toIso8601String(),
    'doseGrams': doseGrams,
    'waterMl': waterMl,
    'waterTempCelsius': waterTempCelsius,
    'grindSetting': grindSetting,
    'grinder': grinder,
    'brewTime': brewTime.inSeconds,
    'bloomTime': bloomTime?.inSeconds,
    'yieldMl': yieldMl,
    'rating': rating,
    'notes': notes,
    'tastingNotes': tastingNotes,
    'imageUrl': imageUrl,
    'flavorScores': flavorScores,
    'aiRecipe': aiRecipe,
    'aiFeedback': aiFeedback,
  };

  factory Brew.fromJson(Map<String, dynamic> json) => Brew(
    id: json['id'] as String,
    beanId: json['beanId'] as String,
    method: json['method'] as String,
    brewDate: DateTime.parse(json['brewDate'] as String),
    doseGrams: (json['doseGrams'] as num).toDouble(),
    waterMl: (json['waterMl'] as num).toDouble(),
    waterTempCelsius: (json['waterTempCelsius'] as num?)?.toDouble() ?? 93,
    grindSetting: json['grindSetting'] as int? ?? 20,
    grinder: json['grinder'] as String?,
    brewTime: Duration(seconds: json['brewTime'] as int? ?? 180),
    bloomTime: json['bloomTime'] != null
        ? Duration(seconds: json['bloomTime'] as int)
        : null,
    yieldMl: (json['yieldMl'] as num?)?.toDouble(),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String?,
    tastingNotes: (json['tastingNotes'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    imageUrl: json['imageUrl'] as String?,
    flavorScores: (json['flavorScores'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    aiRecipe: json['aiRecipe'] as Map<String, dynamic>?,
    aiFeedback: json['aiFeedback'] as Map<String, dynamic>?,
  );

  @override
  List<Object?> get props => [id];
}
