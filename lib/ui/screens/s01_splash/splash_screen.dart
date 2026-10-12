import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';

/// S1 Splash — boots the app, restores language pref, and routes the user.
///
/// Routing:
///   * no language saved              → /language (S2)
///   * language saved + no users      → /setup (S3)
///   * language saved + users exist   → /login (S4)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await ref.read(localeProvider.notifier).load();
    await ref.read(authProvider.notifier).loadPersistedState();
    if (!mounted) return;

    final locale = ref.read(localeProvider);
    if (locale == null) {
      context.goNamed('s02_language');
      return;
    }

    final isFirstLaunch = await AppDatabase.instance.isFirstLaunch();
    if (!mounted) return;

    if (isFirstLaunch) {
      context.goNamed('s03_first_setup');
    } else {
      context.goNamed('s04_login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Saagar',
              style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 52,
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Audit',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 18,
                letterSpacing: 4,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(AppColors.goldLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
