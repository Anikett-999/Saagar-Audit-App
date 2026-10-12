import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/app.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s05_home/home_screen.dart';
import 'package:sagar_meeting_app/sagar_meeting_app.dart' hide AppTheme, AppDatabase;
import 'helpers/fake_database.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  Future<void> loadPersistedState({dynamic prefs}) async {}

  @override
  bool registerFailure({DateTime? at}) => false;

  @override
  void logout() {
    state = const AuthState();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> load() async {}

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const ownerUser = AuthUser(
    id: 'u_owner',
    name: 'Sagar Bora',
    role: 'OWNER',
    languagePref: 'en',
  );

  const smUser = AuthUser(
    id: 'u_sm',
    name: 'Rahul Store Manager',
    role: 'SM',
    languagePref: 'en',
  );

  const gmUser = AuthUser(
    id: 'u_gm',
    name: 'Vikram General Manager',
    role: 'GM',
    languagePref: 'en',
  );

  group('Executive Meeting Suite — Screen S05 AppBar Gate', () {
    late FakeDatabase fakeDb;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    testWidgets('Owner sees the Executive Suite icon in AppBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(
                const AuthState(user: ownerUser),
              ),
            ),
            localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              MeetingLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the Executive Suite AppBar button exists for OWNER
      final execBtn = find.byKey(const ValueKey('executive_suite_appbar_btn'));
      expect(execBtn, findsOneWidget);
      expect(find.byIcon(Icons.business_center_rounded), findsOneWidget);
    });

    testWidgets('Store Manager (SM) NEVER sees the Executive Suite icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(
                const AuthState(user: smUser),
              ),
            ),
            localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              MeetingLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the Executive Suite button does NOT exist for SM
      final execBtn = find.byKey(const ValueKey('executive_suite_appbar_btn'));
      expect(execBtn, findsNothing);
      expect(find.byIcon(Icons.business_center_rounded), findsNothing);
    });

    testWidgets('General Manager (GM) NEVER sees the Executive Suite icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(
                const AuthState(user: gmUser),
              ),
            ),
            localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              MeetingLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the Executive Suite button does NOT exist for GM
      final execBtn = find.byKey(const ValueKey('executive_suite_appbar_btn'));
      expect(execBtn, findsNothing);
      expect(find.byIcon(Icons.business_center_rounded), findsNothing);
    });

    test('GoRouter configuration assertion: NO route path ends with trailing slash', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthState(user: ownerUser)),
          ),
          localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
        ],
      );
      addTearDown(container.dispose);

      // Instantiating routerProvider executes GoRouter internal configuration assertions
      final router = container.read(routerProvider);
      expect(router, isNotNull);
      expect(MeetingRoutes.basePrefix, equals('/owner'));
      expect(MeetingRoutes.dashboard, equals('/owner'));
      expect(MeetingRoutes.dashboard.endsWith('/'), isFalse);

      for (final route in router.configuration.routes) {
        if (route is GoRoute && route.path != '/') {
          expect(
            route.path.endsWith('/'),
            isFalse,
            reason: 'Route "${route.path}" must NOT end with a trailing slash per GoRouter rules.',
          );
        }
      }
    });

    test('MeetingRoutes setters sanitize trailing slashes defensively', () {
      MeetingRoutes.basePrefix = '/owner/';
      expect(MeetingRoutes.basePrefix, equals('/owner'));
      expect(MeetingRoutes.dashboard, equals('/owner'));
      expect(MeetingRoutes.dashboard.endsWith('/'), isFalse);

      MeetingRoutes.basePrefix = '';
      expect(MeetingRoutes.basePrefix, equals(''));
      expect(MeetingRoutes.dashboard, equals('/'));

      // Restore
      MeetingRoutes.basePrefix = '/owner';
      expect(MeetingRoutes.dashboard, equals('/owner'));
    });

    testWidgets('Owner tapping Executive Suite button navigates via routerProvider to /owner', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthState(user: ownerUser)),
          ),
          localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              MeetingLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      // Navigate to /home
      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find the executive suite button and tap it
      final execBtn = find.byKey(const ValueKey('executive_suite_appbar_btn'));
      expect(execBtn, findsOneWidget);

      await tester.tap(execBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));

      // When pushed, DashboardPage is mounted onto the navigator stack
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('Non-owner (SM/GM) navigating to /owner is blocked by route guard and redirected to /home', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(const AuthState(user: smUser)),
          ),
          localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              MeetingLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      // SM user attempts to directly navigate to /owner
      router.go('/owner');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Guard redirects back to /home; DashboardPage is never mounted
      expect(find.byType(DashboardPage), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}



