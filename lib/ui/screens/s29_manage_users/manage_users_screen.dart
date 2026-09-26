import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S29 — Settings: Manage Users (Owner-only).
///
/// Implements Spec §S29 and Sprint design:
/// - Strictly restricted to OWNER role; redirects any unauthorized access.
/// - Lists all users from [UserRepository.listAll] (active and inactive).
/// - Add new user (SM or GM only; never offers OWNER).
/// - Bcrypt hashes initial and reset PINs via [hashPin] before passing to repository.
/// - Soft-deactivation only (never hard-deletes, preserving audit trail integrity).
/// - Owner row cannot be deactivated (defended in UI and repository).
class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final list = await UserRepository.instance.listAll();
    if (!mounted) return;
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;

    // Defense-in-depth route guard: if current user is not OWNER, redirect to settings.
    if (currentUser == null || currentUser.role != 'OWNER') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            context.goNamed('s27_settings');
          } catch (_) {
            // Context does not contain GoRouter (e.g. isolated unit widget tests)
          }
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s29Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.s29AddUserTitle),
        onPressed: () => _openAddUserDialog(l10n, currentUser.id),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 96,
                      ),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(l10n, user);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id ?? '';

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.s29EmptyState,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.gray600,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(l10n.s29AddUserTitle),
                  onPressed: () => _openAddUserDialog(l10n, currentUserId),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AppLocalizations l10n, User user) {
    final isActive = user.isActive;
    final isOwner = user.isOwner;

    final roleBadgeText = switch (user.role) {
      'OWNER' => l10n.s27OwnerBadge,
      'GM' => l10n.s29RoleGm,
      _ => l10n.s29RoleSm,
    };

    final roleBadgeColor = switch (user.role) {
      'OWNER' => AppColors.gold,
      'GM' => AppColors.navyMid,
      _ => AppColors.green,
    };

    final roleBadgeBg = switch (user.role) {
      'OWNER' => AppColors.goldPale,
      'GM' => const Color(0xFFE8EEF5),
      _ => AppColors.greenPale,
    };

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? AppColors.gray200 : AppColors.gray300,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isActive ? roleBadgeColor : AppColors.gray400,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.navy : AppColors.gray800,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleBadgeBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: roleBadgeColor, width: 0.8),
                              ),
                              child: Text(
                                roleBadgeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: roleBadgeColor,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                            ),
                            if (user.phone != null && user.phone!.isNotEmpty)
                              Text(
                                user.phone!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray600,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(l10n, isActive),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reset PIN action (Owner action)
                  TextButton.icon(
                    icon: const Icon(Icons.lock_reset_outlined, size: 18),
                    label: Text(l10n.s29ResetPinAction),
                    onPressed: () => _openResetPinDialog(l10n, user),
                  ),
                  const SizedBox(width: 8),
                  // Deactivate or Reactivate action
                  if (isActive)
                    TextButton.icon(
                      icon: const Icon(Icons.block_outlined, size: 18, color: AppColors.red),
                      label: Text(
                        l10n.s29DeactivateAction,
                        style: const TextStyle(color: AppColors.red),
                      ),
                      onPressed: isOwner
                          ? () => _showOwnerDeactivationBlocked(l10n)
                          : () => _confirmDeactivation(l10n, user),
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.green),
                      label: Text(
                        l10n.s29ReactivateAction,
                        style: const TextStyle(color: AppColors.green),
                      ),
                      onPressed: () => _reactivateUser(l10n, user),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AppLocalizations l10n, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.greenPale : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.greenMid : AppColors.gray300,
        ),
      ),
      child: Text(
        isActive ? l10n.s29StatusActive : l10n.s29StatusInactive,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.green : AppColors.gray600,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }

  void _showOwnerDeactivationBlocked(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.s29CannotDeactivateOwner),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAddUserDialog(
    AppLocalizations l10n,
    String createdById,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    // Default to SM; allowed roles are SM or GM only (never OWNER)
    String selectedRole = 'SM';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.s29AddUserTitle,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  color: AppColors.navy,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.s29NameLabel,
                          hintText: l10n.s29NameHint,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (trimmed.length < 2 || trimmed.length > 50) {
                            return l10n.s29NameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.s29RoleLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // SegmentedButton strictly allows SM or GM only. OWNER is forbidden per Spec §S29.
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment<String>(
                            value: 'SM',
                            label: Text(l10n.s29RoleSm),
                            icon: const Icon(Icons.store_outlined),
                          ),
                          ButtonSegment<String>(
                            value: 'GM',
                            label: Text(l10n.s29RoleGm),
                            icon: const Icon(Icons.business_center_outlined),
                          ),
                        ],
                        selected: {selectedRole},
                        onSelectionChanged: (set) {
                          setDialogState(() {
                            selectedRole = set.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.s29PhoneLabel,
                          hintText: l10n.s29PhoneHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: l10n.s29PinLabel,
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (trimmed.length != 4 || !RegExp(r'^\d{4}$').hasMatch(trimmed)) {
                            return l10n.s29PinRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: l10n.s29PinConfirmLabel,
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (trimmed != pinController.text.trim()) {
                            return l10n.s29PinMismatch;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(l10n.s29CancelButton),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    // bcrypt-hash the entered PIN through the same path S03/S04 use
                    final pin = pinController.text.trim();
                    final pinHashed = hashPin(pin);

                    try {
                      await UserRepository.instance.addUser(
                        name: nameController.text.trim(),
                        role: selectedRole,
                        pinHash: pinHashed,
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        createdBy: createdById,
                      );
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop(true);
                      }
                    } catch (e) {
                      if (dialogCtx.mounted) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(l10n.s29SaveButton),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s29UserAddedSuccess),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openResetPinDialog(
    AppLocalizations l10n,
    User user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            l10n.s29ResetPinTitle(user.name),
            style: const TextStyle(
              fontFamily: 'DMSerifDisplay',
              color: AppColors.navy,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: l10n.s29NewPinLabel,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final trimmed = v?.trim() ?? '';
                    if (trimmed.length != 4 || !RegExp(r'^\d{4}$').hasMatch(trimmed)) {
                      return l10n.s29PinRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: l10n.s29ConfirmNewPinLabel,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final trimmed = v?.trim() ?? '';
                    if (trimmed != newPinController.text.trim()) {
                      return l10n.s29PinMismatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.s29CancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final newPin = newPinController.text.trim();
                final newHash = hashPin(newPin);

                try {
                  await UserRepository.instance.resetPin(user.id, newHash);
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop(true);
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.s29SaveButton),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s29ResetPinSuccess),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeactivation(
    AppLocalizations l10n,
    User user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.s29DeactivateConfirmTitle,
            style: const TextStyle(
              fontFamily: 'DMSerifDisplay',
              color: AppColors.red,
            ),
          ),
          content: Text(l10n.s29DeactivateConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.s29CancelButton),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.s29DeactivateAction),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await UserRepository.instance.deactivate(user.id);
        await _loadUsers();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s29UserDeactivatedSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is StateError ? l10n.s29CannotDeactivateOwner : e.toString()),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reactivateUser(
    AppLocalizations l10n,
    User user,
  ) async {
    await UserRepository.instance.reactivate(user.id);
    await _loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.s29UserReactivatedSuccess),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
