import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:milk_delivery_assist/models/auth/user_session.dart';
import '../models/product.dart';

class ProductApi {
  static const String baseUrl =
      "http://madbackend-env.eba-7mxiyptt.ap-south-1.elasticbeanstalk.com/mad-be/api/products"; // Android emulator

  static Future<List<Product>> fetchProducts(String category) async {
    final token = await UserSession.getToken(); // 🔑 fetch token
    if (token == null) {
      throw Exception("User is not logged in");
    }
    final response = await http.get(
      Uri.parse("$baseUrl?category=$category"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "$token",
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch products");
    }
  }
  
}
