import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';

/// Full-screen scanner UI with a placeholder preview (real camera requires device).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _flashOn = false;

  Future<void> _openResultWithPath(String path) async {
    if (!mounted) return;
    context.push('/scan/result?imagePath=${Uri.encodeComponent(path)}');
  }

  Future<void> _capture() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    await _openResultWithPath(file.path);
  }

  Future<void> _pickGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    await _openResultWithPath(file.path);
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_flashOn ? 'Flash on (preview)' : 'Flash off'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeanTheme.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder "camera" preview
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BeanTheme.darkRoast,
                  BeanTheme.espresso,
                  BeanTheme.darkBg,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.photo_camera_outlined,
                size: 120,
                color: BeanTheme.crema.withOpacity(0.25),
              ),
            ),
          ),
          // Dark vignette overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.05,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/library');
                          }
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: BeanTheme.crema,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.35),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _flashOn ? BeanTheme.honey : BeanTheme.crema,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BeanTheme.caramel.withOpacity(0.35)),
                    ),
                    child: Text(
                      'Point camera at coffee bag',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BeanTheme.crema,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        child: IconButton.filledTonal(
                          onPressed: _pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: BeanTheme.darkCard,
                            foregroundColor: BeanTheme.crema,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: _capture,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: BeanTheme.crema, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: BeanTheme.caramel,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 36,
                                    color: BeanTheme.espresso,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 56),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
