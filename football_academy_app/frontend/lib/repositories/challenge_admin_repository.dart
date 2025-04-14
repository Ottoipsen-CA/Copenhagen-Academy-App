import '../models/challenge_admin.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ChallengeAdminRepository {
  final ApiService _apiService;

  ChallengeAdminRepository(this._apiService);

  Future<List<ChallengeAdmin>> getChallenges() async {
    try {
      final response = await _apiService.get(ApiConfig.challenges);
      if (response is List) {
        return response.map((json) => ChallengeAdmin.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching challenges: $e');
      rethrow;
    }
  }

  Future<List<ChallengeAdmin>> getActiveChallenges() async {
    try {
      final response = await _apiService.get('${ApiConfig.challenges}/active');
      if (response is List) {
        return response.map((json) => ChallengeAdmin.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching active challenges: $e');
      rethrow;
    }
  }

  Future<ChallengeAdmin> createChallenge(ChallengeAdmin challenge) async {
    try {
      final response = await _apiService.post(
        ApiConfig.challenges,
        challenge.toJson(),
      );
      return ChallengeAdmin.fromJson(response);
    } catch (e) {
      print('Error creating challenge: $e');
      rethrow;
    }
  }

  Future<ChallengeAdmin> updateChallenge(ChallengeAdmin challenge) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.challenges}/${challenge.id}',
        challenge.toJson(),
      );
      return ChallengeAdmin.fromJson(response);
    } catch (e) {
      print('Error updating challenge: $e');
      rethrow;
    }
  }

  Future<void> deleteChallenge(int challengeId) async {
    try {
      await _apiService.delete('${ApiConfig.challenges}/$challengeId');
    } catch (e) {
      print('Error deleting challenge: $e');
      rethrow;
    }
  }
} 