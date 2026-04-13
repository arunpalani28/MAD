import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:milk_delivery_assist/models/ActiveSubscription.dart';
import 'package:milk_delivery_assist/models/auth/user_session.dart';

// ---------------- Models ----------------
class DayInfo {
  final String date;
  final String status; // BOOKED / PAUSED / CANCELLED
  final int quantity;

  DayInfo({required this.date, required this.status, required this.quantity});

  factory DayInfo.fromJson(Map<String, dynamic> json) {
    return DayInfo(
      date: json['date'],
      status: json['status'],
      quantity: json['quantity'] ?? 1,
    );
  }

  DateTime get dateTime => DateTime.parse(date);
}

class SubscriptionCalendarResponse {
  final String productName;
  final double pricePerDay;
  final String subscriptionStart;
  final String subscriptionEnd;
  final List<DayInfo> days;

  SubscriptionCalendarResponse({
    required this.productName,
    required this.pricePerDay,
    required this.subscriptionStart,
    required this.subscriptionEnd,
    required this.days,
  });

  factory SubscriptionCalendarResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionCalendarResponse(
      productName: json['productName'],
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      subscriptionStart: json['subscriptionStart'],
      subscriptionEnd: json['subscriptionEnd'],
      days: (json['days'] as List<dynamic>)
          .map((d) => DayInfo.fromJson(d))
          .toList(),
    );
  }

  DateTime get startDate => DateTime.parse(subscriptionStart);
  DateTime get endDate => DateTime.parse(subscriptionEnd);
}

// ---------------- API Service ----------------
class SubscriptionApi {
  static const String baseUrl = "http://madbackend-env.eba-7mxiyptt.ap-south-1.elasticbeanstalk.com/mad-be/api"; // replace with your backend

  // Fetch calendar for subscription
  static Future<SubscriptionCalendarResponse?> fetchCalendar(int subscriptionId) async {
    try {
      final token = await UserSession.getToken(); // 🔑 fetch token
    if (token == null) {
      throw Exception("User is not logged in");
    }
      final url = Uri.parse("$baseUrl/subscriptions/$subscriptionId/calendar");
      final res = await http.get(url, headers: {"Content-Type": "application/json",
        "Authorization": "$token",});

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        return SubscriptionCalendarResponse.fromJson(jsonData);
      } else {
        return null; // Subscription not found
      }
    } catch (e) {
      print("Error fetching calendar: $e");
      return null;
    }
  }
static Future<List<ActiveSubscription>?> fetchActiveSubscriptions() async {
  try {
      final token = await UserSession.getToken();
      final email = await UserSession.getEmail(); 
      if (token== null || email == null) {
      throw Exception("User is not logged in");
    }
    
      final url = Uri.parse("$baseUrl/subscriptions/active");
      final body = json.encode({
        "userId":email
      });

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json",
        "Authorization": "$token",},
        body: body,
      );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => ActiveSubscription.fromJson(e))
          .toList();
    }
  } catch (e) {
    print(e.toString());
  }
  return null;
}

  // Update a single day (book/pause/cancel + quantity)
  static Future<bool> updateDay(int subscriptionId, String date, String status, int quantity,
  String productName,
  double pricePerDay) async {
    try {
      final token = await UserSession.getToken();
      final email = await UserSession.getEmail();  // 🔑 fetch token
    if (token == null || email == null) {
      throw Exception("User is not logged in");
    }
    
      final url = Uri.parse("$baseUrl/subscriptions/$subscriptionId/day");
      final body = json.encode({
        "date": date,
        "status": status,
        "quantity": quantity,
        "productName": productName,
        "pricePerDay": pricePerDay,
        "userId":email
      });

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json",
        "Authorization": "$token",},
        body: body,
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Error updating day: $e");
      return false;
    }
  }

static Future<int?> createSubscription({
  required DateTime startDate,
  required DateTime endDate,
  required String productName,
  required double pricePerDay,
  required List<Map<String, dynamic>> days,
}) async {
  try {
      final token = await UserSession.getToken();
      final email = await UserSession.getEmail();  // 🔑 fetch token
    if (token == null || email == null) {
      throw Exception("User is not logged in");
    }
    
    final url = Uri.parse("$baseUrl/subscriptions/create");

    // Convert days quantity to string if needed
    final List<Map<String, dynamic>> payloadDays = days
        .map((d) => {
              "date": d["date"].toString(),
              "status": d["status"].toString(),
              "quantity": d["quantity"].toString(),
            })
        .toList();

    final body = jsonEncode({
      "productName": productName,
      "pricePerDay": pricePerDay.toString(), // send as string
      "startDate": DateFormat('yyyy-MM-dd').format(startDate),
      "endDate": DateFormat('yyyy-MM-dd').format(endDate),
      "days": payloadDays,
      "userId":email
    });

    final response = await http.post(
      url,
        headers: {"Content-Type": "application/json",
        "Authorization": "$token",},
      body: body,
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      // Assuming backend returns {"subscription_id": 123}
      return int.tryParse(res["subscriptionId"].toString());
    } else {
      print("Create Subscription failed: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Create Subscription Error: $e");
    return null;
  }
}
/// Checks if the user has an active subscription for a specific product
  /// via the Spring Boot backend.
 static Future<bool> checkUserSubscription(String productId) async {
    try {
      final token = await UserSession.getToken(); // 🔑 fetch token
      final email = await UserSession.getEmail(); 
    if (token == null) {
      throw Exception("User is not logged in");
    }
      final url = Uri.parse('$baseUrl/subscriptions/check-active')
          .replace(queryParameters: {
        'userId': email,
        'productName': productId,
      });

      final response = await http.get(
        url,
         headers: {
        "Content-Type": "application/json",
        "Authorization": "$token",
      }
      );

      if (response.statusCode == 200) {
        // The API returns a boolean (true/false)
        return json.decode(response.body) == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

}
