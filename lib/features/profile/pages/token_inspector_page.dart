import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/services/auth_service.dart';

class TokenInspectorPage extends ConsumerStatefulWidget {
  const TokenInspectorPage({super.key});

  @override
  ConsumerState<TokenInspectorPage> createState() => _TokenInspectorPageState();
}

class _TokenInspectorPageState extends ConsumerState<TokenInspectorPage> {
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _email;
  Map<String, dynamic> _jwtClaims = {};
  DateTime? _accessExpDate;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _loadTokenData();
    _startTicker();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _accessExpDate != null) {
        setState(() {});
      }
    });
  }

  Future<void> _loadTokenData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storage = ref.read(authServiceProvider).storage;
      final accessToken = await storage.getAccessToken();
      final refreshToken = await storage.getRefreshToken();
      final userId = await storage.getUserId();
      final email = await storage.getUserEmail();

      if (accessToken != null && accessToken.isNotEmpty) {
        final claims = JwtDecoder.decode(accessToken);
        final expDate = JwtDecoder.getExpirationDate(accessToken);

        if (mounted) {
          setState(() {
            _accessToken = accessToken;
            _refreshToken = refreshToken;
            _userId = userId;
            _email = email;
            _jwtClaims = claims;
            _accessExpDate = expDate;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _accessToken = null;
            _refreshToken = null;
            _userId = userId;
            _email = email;
            _jwtClaims = {};
            _accessExpDate = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefreshToken() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      HapticFeedback.mediumImpact();
      final authService = ref.read(authServiceProvider);
      final response = await authService.refreshTokenManual();

      final claims = JwtDecoder.decode(response.accessToken);
      final expDate = JwtDecoder.getExpirationDate(response.accessToken);

      if (mounted) {
        setState(() {
          _accessToken = response.accessToken;
          _refreshToken = response.refreshToken;
          _userId = response.userId ?? _userId;
          _email = response.email ?? _email;
          _jwtClaims = claims;
          _accessExpDate = expDate;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Token başarıyla yenilendi!'),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yenileme hatası: $_errorMessage'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label panoya kopyalandı!'),
        backgroundColor: AppColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _platformStorageInfo {
    if (kIsWeb) {
      return 'Web Secure Storage / SameSite HttpOnly Cookie & Local Protection';
    }
    if (Platform.isIOS) {
      return 'Apple Keychain (kSecAttrAccessibleAfterFirstUnlock)';
    }
    if (Platform.isMacOS) {
      return 'macOS Keychain Services (Hardware-backed Secure Storage)';
    }
    if (Platform.isAndroid) {
      return 'Android Keystore + EncryptedSharedPreferences (AES-256 GCM)';
    }
    return 'OS Native Secure Storage';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingDuration = _accessToken != null ? JwtDecoder.getRemainingTime(_accessToken!) : null;
    final remainingTimeStr = JwtDecoder.formatDuration(remainingDuration);
    final isAuthenticated = _accessToken != null && _accessToken!.isNotEmpty && !(remainingDuration?.isNegative ?? true);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 8),
            foregroundColor: const Color(0xFF34C759),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          label: const Text(
            'Back',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Token & Auth Inspector',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                ),
              )
            : ResponsiveContent(
                maxWidth: 960,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Banner (Cookie & Token Demo - WordStation Auth Mimarisinin Röntgeni)
                      _buildHeaderBanner(isDark, isAuthenticated, remainingTimeStr),

                      const SizedBox(height: 20),

                      // 2. Access Token Card (JWT)
                      _buildAccessTokenCard(isDark, remainingTimeStr),

                      const SizedBox(height: 20),

                      // 3. Refresh Token Card
                      _buildRefreshTokenCard(isDark),

                      const SizedBox(height: 20),

                      // 4. Claims & Storage Information Card
                      _buildClaimsTableCard(isDark),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark, bool isAuthenticated, String remainingTimeStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161820) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2F3E) : const Color(0xFFE5E5EA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 28,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cookie & Token Demo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WordStation Auth Mimarisinin Röntgeni • Kalan: $remainingTimeStr',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Top Right Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Refresh Token Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isRefreshing ? null : _handleRefreshToken,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF34C759).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRefreshing)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                                ),
                              )
                            else
                              const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF34C759)),
                            const SizedBox(width: 6),
                            const Text(
                              'Token Yenile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Authenticated Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAuthenticated
                          ? const Color(0xFF34C759).withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAuthenticated ? const Color(0xFF34C759) : AppColors.error,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAuthenticated ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 15,
                          color: isAuthenticated ? const Color(0xFF34C759) : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAuthenticated ? 'Authenticated' : 'Unauthenticated',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isAuthenticated ? const Color(0xFF34C759) : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTokenCard(bool isDark, String remainingTimeStr) {
    final expFormatted = _accessExpDate != null ? JwtDecoder.formatDate(_accessExpDate) : 'Bilinmiyor';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161820) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2F3E) : const Color(0xFFE5E5EA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blue Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 20, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Access Token (JWT)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Raw Token Label & Copy Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Raw Token',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Tokenı Kopyala',
                          onPressed: _accessToken != null
                              ? () => _copyToClipboard(_accessToken!, 'Access Token')
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Token Raw Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1015) : const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF232634) : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: SelectableText(
                    _accessToken ?? 'Access Token bulunamadı.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Color(0xFF64B5F6),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Expiration Details
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 8),
                    Text(
                      'Expires: $expFormatted  (Kalan Süre: $remainingTimeStr)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshTokenCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161820) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2F3E) : const Color(0xFFE5E5EA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Orange Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFF9500),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.autorenew_rounded, size: 20, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Refresh Token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Opaque Token (JWT değil - sunucu tarafında doğrulanır)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Refresh Tokenı Kopyala',
                      onPressed: _refreshToken != null
                          ? () => _copyToClipboard(_refreshToken!, 'Refresh Token')
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1015) : const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF232634) : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: SelectableText(
                    _refreshToken ?? 'Refresh Token bulunamadı.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Color(0xFFFFB74D),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 8),
                    Text(
                      'Durum: Aktif ve Güvenli Depolamada Saklanıyor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsTableCard(bool isDark) {
    // Generate unified claims list from JWT and storage info
    final rows = <MapEntry<String, String>>[];

    if (_email != null && _email!.isNotEmpty) {
      rows.add(MapEntry('name', _email!));
      rows.add(MapEntry('emailaddress', _email!));
    }
    if (_userId != null && _userId!.isNotEmpty) {
      rows.add(MapEntry('nameidentifier', _userId!));
    }

    _jwtClaims.forEach((key, value) {
      if (key != 'email' && key != 'sub' && key != 'nameid' && key != 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress') {
        rows.add(MapEntry(key, value.toString()));
      }
    });

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      final preview = _accessToken!.length > 40
          ? '${_accessToken!.substring(0, 30)}...'
          : _accessToken!;
      rows.add(MapEntry('Token', preview));
    }

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      final preview = _refreshToken!.length > 30
          ? '${_refreshToken!.substring(0, 25)}...'
          : _refreshToken!;
      rows.add(MapEntry('RefreshToken', preview));
    }

    if (_accessExpDate != null) {
      rows.add(MapEntry('AccessTokenExpiration', _accessExpDate!.toIso8601String()));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161820) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2F3E) : const Color(0xFFE5E5EA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Turquoise Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF00C7BE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Cookie & Cihaz Güvenli Depolama (Claims)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${rows.length} adet',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Storage Diagnostic Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7BE).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00C7BE).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF00C7BE)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Depolama Mimarisi: $_platformStorageInfo',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00C7BE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tokenlar platformun en yüksek güvenlikli donanım destekli şifreli kasasında saklanır. Ağ isteklerinde otomatik Bearer başlığı ile gönderilir.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Claim Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          'Value',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Claims Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = rows[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Claim Type Badge
                          Expanded(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.key,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF9500),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Claim Value
                          Expanded(
                            flex: 6,
                            child: InkWell(
                              onTap: () => _copyToClipboard(item.value, item.key),
                              borderRadius: BorderRadius.circular(6),
                              child: Text(
                                item.value,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
