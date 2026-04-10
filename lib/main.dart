import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/app_state.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';

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
    ChangeNotifierProvider(
      create: (_) => AppState(
        storage: storageService,
        aiService: aiService,
      )..loadData(),
      child: const _BeanAiRoot(),
    ),
  );
}

class _BeanAiRoot extends StatefulWidget {
  const _BeanAiRoot();

  @override
  State<_BeanAiRoot> createState() => _BeanAiRootState();
}

class _BeanAiRootState extends State<_BeanAiRoot> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _router ??= createRouter(appState);

    final isDarkMode =
        appState.userProfile?.preferences.darkMode ?? false;

    return MaterialApp.router(
      title: 'Bean.ai',
      debugShowCheckedModeBanner: false,
      theme: BeanTheme.lightTheme,
      darkTheme: BeanTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router!,
    );
  }
}
