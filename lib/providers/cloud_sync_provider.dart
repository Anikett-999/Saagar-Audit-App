import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloud_sync_service.dart';

/// Riverpod StateNotifier managing live cloud sync state for the application.
class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  CloudSyncNotifier() : super(const CloudSyncState()) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> _init() async {
    final lastSync = await CloudSyncService.instance.getLastSyncTime();
    final pending = await CloudSyncService.instance.countPendingChanges();
    final hasNet = await CloudSyncService.instance.isNetworkAvailable();

    state = state.copyWith(
      lastSyncAt: lastSync,
      pendingCount: pending,
      status: hasNet ? CloudSyncStatus.idle : CloudSyncStatus.offline,
    );

    // Listen to network changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) {
        state = state.copyWith(status: CloudSyncStatus.offline);
      } else if (state.status == CloudSyncStatus.offline) {
        state = state.copyWith(status: CloudSyncStatus.idle);
        refreshPending();
      }
    });
  }

  /// Refreshes the count of pending local changes awaiting upload.
  Future<void> refreshPending() async {
    final count = await CloudSyncService.instance.countPendingChanges();
    final lastSync = await CloudSyncService.instance.getLastSyncTime();
    state = state.copyWith(
      pendingCount: count,
      lastSyncAt: lastSync,
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

    final result = await CloudSyncService.instance.syncAll(
      force: force,
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
  (ref) => CloudSyncNotifier(),
);
