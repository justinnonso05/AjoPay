import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'group_models.dart';

class GroupRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  GroupRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  Future<GroupResponse> createGroup(GroupCreateRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.groups,
      body: request.toJson(),
      headers: await _secureStorage.authHeaders(),
    );
    return _parseGroup(response);
  }

  Future<GroupResponse> joinGroup(String inviteCode) async {
    final response = await _apiClient.post(
      ApiConstants.joinGroup,
      body: {'invite_code': inviteCode},
      headers: await _secureStorage.authHeaders(),
    );
    return _parseGroup(response);
  }

  /// Returns how many members are in [groupId]. Used to populate the
  /// Join Group success screen, since the join response itself doesn't
  /// include a member count.
  Future<int> getMemberCount(String groupId) async {
    final response = await _apiClient.get(
      ApiConstants.groupMembers(groupId),
      headers: await _secureStorage.authHeaders(),
    );
    final data = response['data'];
    if (data is List) {
      return data.length;
    }
    return 0;
  }

  GroupResponse _parseGroup(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected response from server.');
    }
    return GroupResponse.fromJson(data);
  }
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});
