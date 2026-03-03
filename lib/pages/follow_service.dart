import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';

class FollowService {
  static Future<List<int>> fetchFollowedConsultants(String token) async {
    final response = await http.get(
      Uri.parse('$api/followed_consultants'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'Success' && data['consultant_list'] is List) {
        return List<int>.from(data['consultant_list']);
      }
    }
    return [];
  }
}
