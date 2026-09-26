import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../theme/app_colors.dart';

/// A prominent language switcher chip placed in the AppBar.
/// Displays current language and toggles between English and Marathi (मराठी) on tap.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isMarathi = currentLocale?.languageCode == 'mr';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final newCode = isMarathi ? 'en' : 'mr';
              ref.read(localeProvider.notifier).set(Locale(newCode));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyMid,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldLight, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    size: 16,
                    color: AppColors.goldLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMarathi ? 'मराठी' : 'EN',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.swap_horiz,
                    size: 14,
                    color: AppColors.goldLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
