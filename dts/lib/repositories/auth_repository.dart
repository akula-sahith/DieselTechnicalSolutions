import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "admin" | "reporter"
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'reporter',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.authLogin,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> registerReporter({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.registerReporter,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getReporters() async {
    try {
      final response = await _apiService.get(ApiConstants.getReporters);
      final data = response.data['data'] as Map<String, dynamic>;
      final reportersRaw = data['reporters'] as List? ?? [];
      return reportersRaw
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReporter(String id) async {
    try {
      await _apiService.delete('${ApiConstants.getReporters}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
