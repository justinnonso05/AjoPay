import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'user_profile.dart';

/// Caches the last-fetched profile so other screens (Home, PIN setup)
/// can read `has_pin`, `kyc_status`, wallet balance, etc. without refetching.
final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

class UserRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  UserRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  /// Submits the user's BVN for mock identity verification.
  Future<UserProfile> mockVerifyKyc(String bvn) async {
    final response = await _apiClient.post(
      ApiConstants.mockKycVerify,
      body: {'bvn': bvn},
      headers: await _secureStorage.authHeaders(),
    );
    return _parseUser(response);
  }

  Future<UserProfile> getMe() async {
    final response = await _apiClient.get(
      ApiConstants.me,
      headers: await _secureStorage.authHeaders(),
    );
    return _parseUser(response);
  }

  UserProfile _parseUser(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected response from server.');
    }
    return UserProfile.fromJson(data);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});
