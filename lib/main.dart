import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = StorageService();
  await storageService.init();

  final aiService = AiService();

  runApp(
    BeanAiApp(
      storageService: storageService,
      aiService: aiService,
    ),
  );
}

class BeanAiApp extends StatelessWidget {
  final StorageService storageService;
  final AiService aiService;

  const BeanAiApp({
    super.key,
    required this.storageService,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        storage: storageService,
        aiService: aiService,
      )..loadData(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          final isDarkMode =
              appState.userProfile?.preferences.darkMode ?? false;

          return MaterialApp.router(
            title: 'Bean.ai',
            debugShowCheckedModeBanner: false,
            theme: BeanTheme.lightTheme,
            darkTheme: BeanTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
