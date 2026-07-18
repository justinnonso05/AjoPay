import '../config/env_config.dart';

class ApiConstants {
  static String get baseUrl => EnvConfig.baseUrl;

  /// The backend versions all routes under this prefix, e.g.
  /// https://ajopay.fastapicloud.dev/api/v1/auth/signup
  static const String apiPrefix = '/api/v1';

  // Auth endpoints
  static String get login => '$apiPrefix/auth/login';
  static String get register => '$apiPrefix/auth/signup';
  static String get verifyOtp => '$apiPrefix/auth/verify-otp';
  static String get setupPin => '$apiPrefix/auth/setup-pin';

  // Group endpoints
  static String get groups => '$apiPrefix/groups/';
  static String get joinGroup => '$apiPrefix/groups/join';
  static String groupMembers(String groupId) => '$apiPrefix/groups/$groupId/members';

  // User endpoints
  static String get me => '$apiPrefix/users/me';
  static String get mockKycVerify => '$apiPrefix/users/me/kyc/mock-verify';
  static String get bankAccount => '$apiPrefix/members/bank-account';
}
