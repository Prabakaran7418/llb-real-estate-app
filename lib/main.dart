import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set high-contrast monochrome system status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase with safe fallback for seamless local/demo runs
  try {
    await Firebase.initializeApp();
    debugPrint('[Firebase] Successfully initialized Firebase Core.');
  } catch (e) {
    debugPrint(
      '[Firebase] Notice: Running with built-in reactive data repository. '
      'Configure google-services.json / GoogleService-Info.plist for live cloud sync: $e',
    );
  }

  runApp(
    const ProviderScope(
      child: LLBRealEstateApp(),
    ),
  );
}

class LLBRealEstateApp extends ConsumerWidget {
  const LLBRealEstateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
