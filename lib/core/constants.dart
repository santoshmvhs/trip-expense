class ApiEndpoints {
  // For macOS desktop / iOS simulator
  static const String baseUrl = 'http://localhost:8000/api/v1';
  // For Android emulator, use: 'http://10.0.2.2:8000/api/v1'
  
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  
  static String moments() => '/moments';
  static String moment(String id) => '/moments/$id';
  static String closeMoment(String id) => '/moments/$id/close';
  static String momentSummary(String id) => '/moments/$id/summary';
  
  static String participants(String momentId) => '/moments/$momentId/participants';
  static String contributions(String momentId) => '/moments/$momentId/contributions';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String userId = 'user_id';
}

