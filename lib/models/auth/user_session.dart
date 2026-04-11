import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String isKycComplete; // "yes" or "no"
  final String? mobile; // Nullable
  final String? token;

  UserSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.isKycComplete = "NO",
    this.mobile,
    this.token
  });

  // Save user
  static Future<void> saveUser({
    required int userId,
    required String name,
    required String email,
    required String role,
    String isKycComplete = "NO",
    String? mobile,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('role', role);
    await prefs.setString('isKycComplete', isKycComplete);
    if (token != null) await prefs.setString('token', token);
    if (mobile != null) await prefs.setString('mobile', mobile);
  }

  // Load user
  static Future<UserSession?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final role = prefs.getString('role');
    final isKycComplete = prefs.getString('isKycComplete') ?? "NO";
    final mobile = prefs.getString('mobile');
    final token = prefs.getString('token');

    if (userId != null && name != null && email != null && role != null) {
      return UserSession(
        userId: userId,
        name: name,
        email: email,
        role: role,
        isKycComplete: isKycComplete,
        mobile: mobile,
        token:token
      );
    }
    return null;
  }
  
  // Clear user session
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('role');
    await prefs.remove('isKycComplete');
    await prefs.remove('token');
    await prefs.remove('mobile');
  }
  // Get token directly
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  // Get token directly
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }
}
