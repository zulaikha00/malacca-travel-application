import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> showAddAdminDialog(BuildContext context) async {
  bool isEmailValid = true;
  bool showPassword = false;
  bool isLoading = false;
  String roleValue = 'Admin';
  bool isPasswordValid = true; // Add this inside showAddAdminDialog

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Show dialog
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final colorScheme = theme.colorScheme;

  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: colorScheme.surface,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Add New Admin',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Fill in the details below to create a new admin account.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  _buildTextField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),

                  // Email with validation
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      labelText: 'Email Address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      errorText: isEmailValid || emailController.text.isEmpty
                          ? null
                          : '❌ Invalid email format',
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) {
                      setState(() {
                        isEmailValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Inside TextField for password:
                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => showPassword = !showPassword),
                      ),
                      errorText: isPasswordValid || passwordController.text.isEmpty
                          ? null
                          : '❌ Password must be at least 8 characters',
                    ),
                    onChanged: (value) {
                      setState(() {
                        isPasswordValid = value.length >= 8;
                      });
                    },
                  ),


                  const SizedBox(height: 12),

                  // Role dropdown
                  DropdownButtonFormField<String>(
                    value: roleValue,
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setState(() => roleValue = value!),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge),
                      labelText: 'Role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
            ),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final role = roleValue;

                if (name.isEmpty || email.isEmpty || password.isEmpty || role.isEmpty) {
                  showThemedSnackBar(context, '⚠️ All fields are required', false);
                  return;
                }

                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  showThemedSnackBar(context, '⚠️ Please enter a valid email', false);
                  return;
                }

                if (password.length < 8) {
                  setState(() => isPasswordValid = false); // trigger error display
                  showThemedSnackBar(context, '⚠️ Password must be at least 8 characters', false);
                  return;
                }


                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  showThemedSnackBar(context, '⚠️ Please log in first', false);
                  return;
                }

                try {
                  setState(() => isLoading = true);
                  final idToken = await user.getIdToken();

                  final response = await http.post(
                    Uri.parse('https://createadmin-asb6wdryia-uc.a.run.app'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $idToken',
                    },
                    body: json.encode({
                      'name': name,
                      'email': email,
                      'password': password,
                      'role': role,
                    }),
                  );

                  final data = json.decode(response.body);

                  if (response.statusCode == 200) {
                    Navigator.pop(context, true);
                    showThemedSnackBar(context, 'Admin created successfully!', true);
                  } else {
                    showThemedSnackBar(context, '❌ Error: ${data['error']}', false);
                  }
                } catch (e) {
                  showThemedSnackBar(context, '❌ Error: ${e.toString()}', false);
                } finally {
                  setState(() => isLoading = false);
                  nameController.clear();
                  emailController.clear();
                  passwordController.clear();
                  roleValue = 'Admin';
                }
              },
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: Text(isLoading ? 'Adding...' : 'Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Reusable input field
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required ThemeData theme,
  bool obscure = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  final isDark = theme.brightness == Brightness.dark;

  return TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: theme.textTheme.bodyMedium,
    decoration: InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
    ),
  );
}

/// Reusable snackbar with dark mode support
void showThemedSnackBar(BuildContext context, String message, bool isSuccess) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isDark
          ? colorScheme.surfaceVariant
          : isSuccess ? Colors.green[50] : Colors.red[50],
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : isSuccess ? Colors.green[900] : Colors.red[900],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
