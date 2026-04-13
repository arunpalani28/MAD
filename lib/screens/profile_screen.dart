import 'package:flutter/material.dart';
import 'package:milk_delivery_assist/screens/active_subscriptions_screen.dart';
import 'package:milk_delivery_assist/screens/email_login_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/auth/user_session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserSession? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserSession.loadUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.name);
    final mobileController = TextEditingController(text: _user!.mobile ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final regExp = RegExp(r'^[0-9]{10}$');
                  if (value == null || value.isEmpty) {
                    return 'Enter mobile number';
                  } else if (!regExp.hasMatch(value)) {
                    return 'Enter valid 10-digit number';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedName = nameController.text.trim();
                final updatedMobile = mobileController.text.trim();

                // Call API to update user details
                final response = await http.post(
                  Uri.parse('http://madbackend-env.eba-7mxiyptt.ap-south-1.elasticbeanstalk.com/mad-be/api/auth/update'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "id": _user!.userId,
                    "name": updatedName,
                    "email": _user!.email,
                    "mobile": updatedMobile,
                    "role": _user!.role,
                    "isKycComplete": _user!.isKycComplete,
                  }),
                );

                if (response.statusCode == 201 || response.statusCode == 200) {
                  // Save locally
                  await UserSession.saveUser(
                    userId: _user!.userId,
                    name: updatedName,
                    email: _user!.email,
                    role: _user!.role,
                    isKycComplete: _user!.isKycComplete,
                    mobile: updatedMobile,
                  );
                  await _loadUser();
                  Navigator.pop(context);
                } else {
                  // Error handling
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = context.watch<AppState>().walletBalance;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user?.name ?? 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?.mobile ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KYC: ${_user?.isKycComplete ?? "NO"}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    // Edit Profile Button moved below profile info
                    ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Wallet Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: AppTheme.accent),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wallet Balance',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '₹$walletBalance',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            backgroundColor: AppTheme.primary,
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Top Up',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Menu Options
                  _buildMenuOption(
  Icons.calendar_month,
  'My Subscriptions',
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveSubscriptionsScreen(),
      ),
    );
  },
),
                  _buildMenuOption(Icons.history, 'Order History', () {}),
                  _buildMenuOption(Icons.location_on_outlined, 'Manage Addresses', () {}),
                  _buildMenuOption(Icons.support_agent, 'Help & Support', () {}),
                  _buildMenuOption(Icons.logout, 'Logout', () async {
                    await UserSession.clear();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const EmailLoginWidget()),
                      (route) => false,
                    );
                  }, isDestructive: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.black87,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }
}
