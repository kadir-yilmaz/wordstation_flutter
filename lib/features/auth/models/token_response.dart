class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String? userId;
  final String? email;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
    this.email,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    dynamic findVal(Map map, List<String> keys) {
      for (final key in keys) {
        if (map.containsKey(key) && map[key] != null) {
          return map[key];
        }
      }
      for (final entry in map.entries) {
        for (final key in keys) {
          if (entry.key.toString().toLowerCase() == key.toLowerCase() &&
              entry.value != null) {
            return entry.value;
          }
        }
      }
      return null;
    }

    final targetMap = (json['data'] is Map || json['Data'] is Map)
        ? (json['data'] ?? json['Data']) as Map
        : json;

    final token = findVal(targetMap, [
          'token',
          'Token',
          'accessToken',
          'AccessToken',
          'access_token',
          'jwt',
          'Jwt'
        ]) ??
        findVal(json, [
          'token',
          'Token',
          'accessToken',
          'AccessToken',
          'access_token',
          'jwt',
          'Jwt'
        ]) ??
        '';

    final refreshToken = findVal(
            targetMap, ['refreshToken', 'RefreshToken', 'refresh_token']) ??
        findVal(json, ['refreshToken', 'RefreshToken', 'refresh_token']) ??
        '';

    final userId = findVal(
            targetMap, ['userId', 'UserId', 'user_id', 'id', 'Id']) ??
        findVal(json, ['userId', 'UserId', 'user_id', 'id', 'Id']);

    final email = findVal(
            targetMap, ['email', 'Email', 'userEmail', 'UserEmail']) ??
        findVal(json, ['email', 'Email', 'userEmail', 'UserEmail']);

    return TokenResponse(
      accessToken: token.toString(),
      refreshToken: refreshToken.toString(),
      userId: userId?.toString(),
      email: email?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': accessToken,
      'refreshToken': refreshToken,
      if (userId != null) 'userId': userId,
      if (email != null) 'email': email,
    };
  }
}
