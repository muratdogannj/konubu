import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/location_models.dart';

class TurkeyApiService {
  final http.Client _client;

  TurkeyApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Province>> getProvinces() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.turkeyApiBaseUrl}/provinces'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> provincesJson = data['data'] as List<dynamic>;
        
        return provincesJson
            .map((json) => Province.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching provinces: $e');
    }
  }

  Future<List<District>> getDistricts() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.turkeyApiBaseUrl}/districts'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> districtsJson = data['data'] as List<dynamic>;
        
        return districtsJson
            .map((json) => District.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  Future<List<District>> getDistrictsByProvinceId(int provinceId) async {
    final allDistricts = await getDistricts();
    return allDistricts.where((d) => d.provinceId == provinceId).toList();
  }

  void dispose() {
    _client.close();
  }
}
