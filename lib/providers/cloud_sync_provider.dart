import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_sync_service.dart';
import '../services/store_account_service.dart';
import 'auth_provider.dart';

/// Riverpod StateNotifier managing live cloud sync state for the application.
class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  CloudSyncNotifier([this._ref]) : super(const CloudSyncState()) {
    _init();
  }

  final Ref? _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const String prefKeyAutoSync = 'cloud_auto_sync_enabled';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final autoSync = prefs.getBool(prefKeyAutoSync) ?? true;
    final isPaired = await StoreAccountService.instance.isDevicePaired();
    final storeName = await StoreAccountService.instance.getPairedStoreName();
    final lastSync = await CloudSyncService.instance.getLastSyncTime();
    final pending = await CloudSyncService.instance.countPendingChanges();
    final hasNet = await CloudSyncService.instance.isNetworkAvailable();

    state = state.copyWith(
      lastSyncAt: lastSync,
      pendingCount: pending,
      status: hasNet ? CloudSyncStatus.idle : CloudSyncStatus.offline,
      isStorePaired: isPaired,
      pairedStoreName: storeName,
      isAutoSyncEnabled: autoSync,
    );

    // Auto-trigger background sync on app launch if online, paired, and auto-sync enabled
    if (hasNet && isPaired && autoSync) {
      unawaited(syncNow());
    }

    // Listen to network changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) {
        state = state.copyWith(status: CloudSyncStatus.offline);
      } else if (state.status == CloudSyncStatus.offline) {
        state = state.copyWith(status: CloudSyncStatus.idle);
        if (state.isStorePaired && state.isAutoSyncEnabled) {
          unawaited(syncNow());
        }
      }
    });
  }

  /// Toggles automatic background synchronization and persists setting.
  Future<void> toggleAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyAutoSync, enabled);
    state = state.copyWith(isAutoSyncEnabled: enabled);
  }

  /// Pairs device to the store account and triggers immediate sync if auto-sync is on.
  Future<bool> pairStoreAccount(String storeKey) async {
    final success = await StoreAccountService.instance.pairStoreAccount(storeKey: storeKey);
    if (success) {
      final name = await StoreAccountService.instance.getPairedStoreName();
      state = state.copyWith(
        isStorePaired: true,
        pairedStoreName: name,
      );
      if (state.isAutoSyncEnabled) {
        unawaited(syncNow());
      }
    }
    return success;
  }

  /// Disconnects device from store account (Owner only).
  Future<void> unpairStoreAccount() async {
    await StoreAccountService.instance.unpairStoreAccount();
    state = state.copyWith(
      isStorePaired: false,
      pairedStoreName: null,
    );
  }

  /// Rotates store passcode (Owner only) and updates credentials.
  Future<bool> rotateStorePasscode({
    required String currentPasscode,
    required String newPasscode,
  }) async {
    return await StoreAccountService.instance.rotateStorePasscode(
      currentPasscode: currentPasscode,
      newPasscode: newPasscode,
    );
  }

  /// Revokes remote device access (Kill Switch executed by Owner).
  Future<void> revokeDevice(String deviceId) async {
    await StoreAccountService.instance.revokeRemoteDevice(deviceId: deviceId);
  }

  /// Refreshes the count of pending local changes awaiting upload and store pairing.
  Future<void> refreshPending() async {
    final isPaired = await StoreAccountService.instance.isDevicePaired();
    final storeName = await StoreAccountService.instance.getPairedStoreName();
    final count = await CloudSyncService.instance.countPendingChanges();
    final lastSync = await CloudSyncService.instance.getLastSyncTime();
    state = state.copyWith(
      pendingCount: count,
      lastSyncAt: lastSync,
      isStorePaired: isPaired,
      pairedStoreName: storeName,
    );
  }

  /// Triggers a manual or automatic cloud synchronization pass.
  Future<SyncResult> syncNow({bool force = false}) async {
    if (state.status == CloudSyncStatus.syncing) {
      return const SyncResult(
        success: false,
        status: CloudSyncStatus.syncing,
        message: 'Sync already in progress.',
      );
    }

    state = state.copyWith(
      status: CloudSyncStatus.syncing,
      progress: 0.05,
      errorMessage: null,
    );

    final userRole = _ref?.read(authProvider).user?.role;
    final result = await CloudSyncService.instance.syncAll(
      force: force,
      userRole: userRole,
      onProgress: (progress, step) {
        state = state.copyWith(progress: progress);
      },
    );

    final now = DateTime.now();
    if (result.success) {
      final pendingAfter = await CloudSyncService.instance.countPendingChanges();
      state = state.copyWith(
        status: CloudSyncStatus.success,
        lastSyncAt: now,
        pendingCount: pendingAfter,
        pushedRecords: result.pushedRecords,
        pulledRecords: result.pulledRecords,
        uploadedPhotos: result.uploadedPhotos,
        progress: 1.0,
      );
    } else {
      state = state.copyWith(
        status: result.status,
        errorMessage: result.message,
        progress: 0.0,
      );
    }

    return result;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

final cloudSyncProvider =
    StateNotifierProvider<CloudSyncNotifier, CloudSyncState>(
  (ref) => CloudSyncNotifier(ref),
);
