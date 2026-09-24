import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/storage/secure_storage_service.dart';
import 'package:wordstation_flutter/features/auth/models/login_request.dart';
import 'package:wordstation_flutter/features/auth/models/token_response.dart';
import 'package:wordstation_flutter/features/auth/models/user_model.dart';
import 'package:wordstation_flutter/features/auth/services/auth_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('Auth - Models & Serialization', () {
    test('LoginRequest serialization', () {
      const req = LoginRequest(email: 'user@wordstation.com', password: 'Password123!');
      final json = req.toJson();
      expect(json['email'], 'user@wordstation.com');
      expect(json['password'], 'Password123!');
    });

    test('TokenResponse and UserModel parsing', () {
      final tokenJson = {
        'token': 'mock_access_token_abc',
        'refreshToken': 'mock_refresh_token_xyz',
        'userId': 'usr_42',
        'email': 'user@wordstation.com',
      };

      final tokenResp = TokenResponse.fromJson(tokenJson);
      expect(tokenResp.accessToken, 'mock_access_token_abc');
      expect(tokenResp.refreshToken, 'mock_refresh_token_xyz');
      expect(tokenResp.userId, 'usr_42');

      const user = UserModel(id: 'usr_42', email: 'user@wordstation.com');
      expect(user.id, 'usr_42');
      expect(user.email, 'user@wordstation.com');
      expect(user.toJson()['email'], 'user@wordstation.com');
    });
  });

  group('Auth - SecureStorage Token Lifecycle', () {
    test('Token save, read, validation and clear lifecycle', () async {
      final storage = SecureStorageService();
      await storage.clearAll();

      expect(await storage.hasValidToken(), isFalse);

      await storage.saveTokens(
        accessToken: 'jwt_mock_token_123',
        refreshToken: 'refresh_mock_token_456',
        email: 'test@wordstation.com',
        userId: 'usr_99',
      );

      expect(await storage.hasValidToken(), isTrue);
      expect(await storage.getAccessToken(), 'jwt_mock_token_123');
      expect(await storage.getRefreshToken(), 'refresh_mock_token_456');
      expect(await storage.getUserEmail(), 'test@wordstation.com');
      // Resolved userId in WordStation maps to email when email is provided
      expect(await storage.getUserId(), 'test@wordstation.com');

      await storage.clearAll();
      expect(await storage.hasValidToken(), isFalse);
      expect(await storage.getAccessToken(), isNull);
    });
  });

  group('Auth - API Service Calls', () {
    test('loginWithEmail sends POST and returns parsed UserModel', () async {
      final storage = SecureStorageService();
      await storage.clearAll();

      final mockClient = createMockApiClient((options) {
        if (options.path.contains('/auth/login') && options.method == 'POST') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'token': 'jwt_access_abc',
              'refreshToken': 'jwt_refresh_xyz',
              'userId': 'usr_login_1',
              'email': 'login@wordstation.com',
            },
          );
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final authService = AuthService(apiClient: mockClient, storage: storage);
      final user = await authService.loginWithEmail('login@wordstation.com', 'Pass123!');

      expect(user.email, 'login@wordstation.com');
      expect(user.id, 'login@wordstation.com');
      expect(await storage.getAccessToken(), 'jwt_access_abc');
    });

    test('registerWithEmail sends POST and persists tokens', () async {
      final storage = SecureStorageService();
      await storage.clearAll();

      final mockClient = createMockApiClient((options) {
        if (options.path.contains('/auth/register') && options.method == 'POST') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'token': 'reg_token_789',
              'refreshToken': 'reg_refresh_000',
              'userId': 'usr_reg_2',
              'email': 'reg@wordstation.com',
            },
          );
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final authService = AuthService(apiClient: mockClient, storage: storage);
      final user = await authService.register('reg@wordstation.com', 'Pass123!');

      expect(user.email, 'reg@wordstation.com');
      expect(user.id, 'reg@wordstation.com');
      expect(await storage.getAccessToken(), 'reg_token_789');
    });
  });
}
