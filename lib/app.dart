import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/s01_splash/splash_screen.dart';
import 'ui/screens/s02_language/language_screen.dart';
import 'ui/screens/s03_first_setup/first_setup_screen.dart';
import 'ui/screens/s04_login/login_screen.dart';
import 'ui/screens/s05_home/home_screen.dart';
import 'ui/screens/s06_start_audit/start_audit_screen.dart';
import 'ui/screens/s07_checkpoint/checkpoint_screen.dart';
import 'ui/screens/s08_fail_detail/fail_detail_screen.dart';
import 'ui/screens/s10_review/review_submit_screen.dart';
import 'ui/screens/s11_submitted/submitted_screen.dart';
import 'ui/screens/s12_audit_history/audit_history_screen.dart';
import 'ui/screens/s13_audit_detail/audit_detail_screen.dart';
import 'ui/screens/s14_cap_list/cap_list_screen.dart';
import 'ui/screens/s15_cap_create/cap_create_screen.dart';
import 'ui/screens/s16_cap_detail/cap_detail_screen.dart';
import 'ui/screens/s17_cap_mark_done/cap_mark_done_screen.dart';
import 'ui/screens/s22_reference/reference_index_screen.dart';
import 'ui/screens/s23_rating_scale/rating_scale_screen.dart';
import 'ui/screens/s24_escalation_triggers/escalation_triggers_screen.dart';
import 'ui/screens/s25_evidence/evidence_screen.dart';
import 'ui/screens/s26_glossary/glossary_screen.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/s27_settings/settings_screen.dart';
import 'ui/screens/s28_manage_cros/manage_cros_screen.dart';
import 'ui/screens/s29_manage_users/manage_users_screen.dart';
import 'ui/screens/s30_change_pin/change_pin_screen.dart';
import 'ui/screens/s31_language/settings_language_screen.dart';
import 'ui/screens/s32_backup_export/backup_export_screen.dart';
import 'ui/theme/app_theme.dart';

/// Top-level [GoRouter] provider so navigation stack persists across widget rebuilds.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 's01_splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        name: 's02_language',
        builder: (_, __) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 's03_first_setup',
        builder: (_, __) => const FirstSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 's04_login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 's05_home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/audit/start',
        name: 's06_start_audit',
        builder: (_, __) => const StartAuditScreen(),
      ),
      GoRoute(
        path: '/audit/checkpoint',
        name: 's07_checkpoint',
        builder: (_, __) => const CheckpointScreen(),
      ),
      GoRoute(
        path: '/audit/fail-detail',
        name: 's08_fail_detail',
        builder: (_, __) => const FailDetailScreen(),
      ),
      // S9 Photo Capture is folded into S8 (inline camera launch).
      GoRoute(
        path: '/audit/review',
        name: 's10_review',
        builder: (_, __) => const ReviewSubmitScreen(),
      ),
      GoRoute(
        path: '/audit/submitted',
        name: 's11_submitted',
        builder: (_, __) => const SubmittedScreen(),
      ),
      GoRoute(
        path: '/audits',
        name: 's12_audit_history',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const AuditHistoryScreen(),
      ),
      GoRoute(
        path: '/audits/:id',
        name: 's13_audit_detail',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (context, state) => AuditDetailScreen(
          auditId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/caps',
        name: 's14_cap_list',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const CapListScreen(),
      ),
      GoRoute(
        path: '/caps/new',
        name: 's15_cap_create',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CapCreateScreen(
            originAuditId: state.uri.queryParameters['auditId'] ?? extra?['auditId'] as String?,
            originCheckpointId: state.uri.queryParameters['checkpointId'] ?? extra?['checkpointId'] as String?,
            originResultId: state.uri.queryParameters['resultId'] ?? extra?['resultId'] as String?,
            initialProblemStatement: state.uri.queryParameters['problem'] ?? extra?['problem'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/caps/:id',
        name: 's16_cap_detail',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (context, state) => CapDetailScreen(
          capId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/caps/:id/mark-done',
        name: 's17_cap_mark_done',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (context, state) => CapMarkDoneScreen(
          capId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/reference',
        name: 's22_reference_index',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const ReferenceIndexScreen(),
      ),
      GoRoute(
        path: '/reference/rating',
        name: 's23_rating_scale',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const RatingScaleScreen(),
      ),
      GoRoute(
        path: '/reference/escalation',
        name: 's24_escalation_triggers',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const EscalationTriggersScreen(),
      ),
      GoRoute(
        path: '/reference/evidence',
        name: 's25_evidence',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const EvidenceScreen(),
      ),
      GoRoute(
        path: '/reference/glossary',
        name: 's26_glossary',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => const GlossaryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 's27_settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/cros',
        name: 's28_manage_cros',
        builder: (_, __) => const ManageCrosScreen(),
      ),
      GoRoute(
        path: '/settings/users',
        name: 's29_manage_users',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user?.role != 'OWNER') {
            return '/settings';
          }
          return null;
        },
        builder: (_, __) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/settings/change-pin',
        name: 's30_change_pin',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/settings';
          }
          return null;
        },
        builder: (_, __) => const ChangePinScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        name: 's31_language',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/settings';
          }
          return null;
        },
        builder: (_, __) => const SettingsLanguageScreen(),
      ),
      GoRoute(
        path: '/settings/backup-export',
        name: 's32_backup_export',
        redirect: (context, state) {
          final auth = ref.read(authProvider);
          if (auth.user == null) {
            return '/settings';
          }
          return null;
        },
        builder: (_, __) => const BackupExportScreen(),
      ),
    ],
  );
});

/// Root app widget. Binds [routerProvider], [localeProvider], and [AppTheme].
class SaagarAuditApp extends ConsumerWidget {
  const SaagarAuditApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Saagar Audit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
