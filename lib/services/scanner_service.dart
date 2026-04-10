import 'package:image_picker/image_picker.dart';

import '../models/bean.dart';
import 'ai_service.dart';

class ScannerService {
  final AiService _aiService;
  final ImagePicker _picker = ImagePicker();

  ScannerService({required AiService aiService}) : _aiService = aiService;

  Future<ScanResult> scanFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) {
      return ScanResult(success: false, error: 'Camera cancelled');
    }

    return _processImage(image.path);
  }

  Future<ScanResult> scanFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) {
      return ScanResult(success: false, error: 'Gallery cancelled');
    }

    return _processImage(image.path);
  }

  Future<ScanResult> _processImage(String imagePath) async {
    try {
      final analysis = await _aiService.analyzeBeanImage(imagePath);

      final bean = Bean(
        name: analysis['name'] as String? ?? 'Unknown Bean',
        roaster: analysis['roaster'] as String? ?? 'Unknown Roaster',
        origin: analysis['origin'] as String? ?? 'Unknown',
        region: analysis['region'] as String?,
        varietal: analysis['varietal'] as String?,
        process: analysis['process'] as String? ?? 'Washed',
        roastLevel: analysis['roastLevel'] as String? ?? 'Medium',
        tastingNotes: (analysis['tastingNotes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? [],
        description: analysis['description'] as String?,
        elevation: (analysis['elevation'] as num?)?.toDouble(),
        imageUrl: imagePath,
        aiAnalysis: analysis,
      );

      final confidence = (analysis['confidence'] as num?)?.toDouble() ?? 0.5;

      return ScanResult(
        success: true,
        bean: bean,
        confidence: confidence,
        imagePath: imagePath,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        error: 'Failed to analyze image: $e',
        imagePath: imagePath,
      );
    }
  }
}

class ScanResult {
  final bool success;
  final Bean? bean;
  final double confidence;
  final String? error;
  final String? imagePath;

  ScanResult({
    required this.success,
    this.bean,
    this.confidence = 0,
    this.error,
    this.imagePath,
  });

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.5;

  String get confidenceLabel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }
}
