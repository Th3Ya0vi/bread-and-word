import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'firebase_options.dart';
import 'services/daily_reminder_service.dart';
import 'services/deep_link_service.dart';
import 'services/firebase/auth_service.dart';
import 'services/firebase/block_service.dart';
import 'services/profile_prefs.dart';
import 'services/push_service.dart';
import 'services/youversion/versions.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Connect to Firebase and ensure the visitor is signed in (anonymously) so
  // they can read everything and post a prayer immediately. Never block on it.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AuthService.instance.ensureSignedIn();
    BlockService.instance.start(); // watch who I block / who blocks me
    PushService.instance.init(); // non-blocking — permission + token
    DailyReminderService.instance.init(); // daily "your daily bread" reminder
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  await BiblePrefs.instance.load();
  await ProfilePrefs.instance.load();
  ProfilePrefs.instance.bumpStreak();

  var onboarded = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    onboarded = prefs.getBool(onboardingDoneKey) ?? false;
  } catch (_) {}

  runApp(BreadAndWordApp(onboarded: onboarded));
  DeepLinkService.instance.init();
}

class BreadAndWordApp extends StatelessWidget {
  const BreadAndWordApp({super.key, required this.onboarded});

  final bool onboarded;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bread & Word',
      navigatorKey: DeepLinkService.instance.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      color: AppColors.paper,
      home: onboarded ? const AppShell() : const OnboardingScreen(),
    );
  }
}
