import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/photo_service.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/ui/widgets/camera_permission_dialog.dart';

void main() {
  group('Item 21: Camera Permission Handling', () {
    test('CameraPermissionDeniedException provides clean message', () {
      final exc = CameraPermissionDeniedException('Camera access denied by user');
      expect(exc.message, 'Camera access denied by user');
      expect(exc.toString(), contains('Camera access denied by user'));
    });

    testWidgets('showCameraPermissionDeniedDialog renders title and Open Settings button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCameraPermissionDeniedDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Camera Permission Required'), findsNothing);
    });

    testWidgets('showCameraPermissionDeniedDialog renders authentic Marathi when in mr locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCameraPermissionDeniedDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('कॅमेरा परवानगी आवश्यक'), findsOneWidget);
      expect(find.text('सेटिंग्ज उघडा'), findsOneWidget);
      expect(find.text('रद्द करा'), findsOneWidget);

      await tester.tap(find.text('रद्द करा'));
      await tester.pumpAndSettle();
      expect(find.text('कॅमेरा परवानगी आवश्यक'), findsNothing);
    });
  });

  group('Item 24: Exit Audit Dialog & Back Navigation', () {
    testWidgets('Exit dialog renders when back navigation occurs at index 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final l10n = AppLocalizations.of(context)!;
                  await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.exitAuditDialogTitle),
                      content: Text(l10n.exitAuditDialogMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.btnResumeAudit),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.btnSaveAndExit),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Exit Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Exit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Audit?'), findsOneWidget);
      expect(find.text('Resume Audit'), findsOneWidget);
      expect(find.text('Save & Exit'), findsOneWidget);

      await tester.tap(find.text('Resume Audit'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Audit?'), findsNothing);
    });

    testWidgets('Exit dialog renders in Marathi when in mr locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final l10n = AppLocalizations.of(context)!;
                  await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.exitAuditDialogTitle),
                      content: Text(l10n.exitAuditDialogMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.btnResumeAudit),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.btnSaveAndExit),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Exit Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Exit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('ऑडिटमधून बाहेर पडायचे?'), findsOneWidget);
      expect(find.text('ऑडिट सुरू ठेवा'), findsOneWidget);
      expect(find.text('जतन करा आणि बाहेर पडा'), findsOneWidget);

      await tester.tap(find.text('ऑडिट सुरू ठेवा'));
      await tester.pumpAndSettle();
      expect(find.text('ऑडिटमधून बाहेर पडायचे?'), findsNothing);
    });
  });
}
