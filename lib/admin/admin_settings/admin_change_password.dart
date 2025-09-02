import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showChangePasswordDialog(BuildContext context) {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // 🔐 Visibility toggle flags
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor, // 🌙 Adapts to theme
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '🔐 Change Password',
            style: Theme.of(context).textTheme.titleLarge, // 🌓 Adaptive title style
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Enter your current password and the new password you wish to set.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔐 Current Password
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showCurrent ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => showCurrent = !showCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 🆕 New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => showNew = !showNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Confirm New Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => showConfirm = !showConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                final user = FirebaseAuth.instance.currentUser;

                if (newPasswordController.text.trim().isEmpty ||
                    confirmPasswordController.text.trim().isEmpty ||
                    currentPasswordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ All fields are required')),
                  );
                  return;
                }

                if (newPasswordController.text.trim() !=
                    confirmPasswordController.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Passwords do not match')),
                  );
                  return;
                }

                try {
                  setState(() => isLoading = true);

                  final cred = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: currentPasswordController.text.trim(),
                  );

                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPasswordController.text.trim());

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Password updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Update'),
            ),
          ],
        ),
      );
    },
  );
}
