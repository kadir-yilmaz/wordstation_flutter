import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
  DateTime? _accessIatDate;
  Duration? _accessLifespan;
  DateTime? _refreshExpDate;
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
      if (mounted && (_accessExpDate != null || _refreshExpDate != null)) {
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
        final iatDate = JwtDecoder.getIssuedAtDate(accessToken);
        final lifespan = JwtDecoder.getLifespan(accessToken);

        // Try to parse refresh token expiration from claims or storage
        DateTime? refExp;
        final refExpClaim = claims['RefreshTokenExpiration'] ??
            claims['refreshTokenExpiration'] ??
            claims['ref_exp'];
        if (refExpClaim != null) {
          refExp = DateTime.tryParse(refExpClaim.toString());
        }
        refExp ??= iatDate?.add(const Duration(days: 7));

        if (mounted) {
          setState(() {
            _accessToken = accessToken;
            _refreshToken = refreshToken;
            _userId = userId;
            _email = email;
            _jwtClaims = claims;
            _accessExpDate = expDate;
            _accessIatDate = iatDate;
            _accessLifespan = lifespan;
            _refreshExpDate = refExp;
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
            _accessIatDate = null;
            _accessLifespan = null;
            _refreshExpDate = null;
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
      final iatDate = JwtDecoder.getIssuedAtDate(response.accessToken);
      final lifespan = JwtDecoder.getLifespan(response.accessToken);

      DateTime? refExp;
      final refExpClaim = claims['RefreshTokenExpiration'] ??
          claims['refreshTokenExpiration'] ??
          claims['ref_exp'];
      if (refExpClaim != null) {
        refExp = DateTime.tryParse(refExpClaim.toString());
      }
      refExp ??= iatDate?.add(const Duration(days: 7));

      if (mounted) {
        setState(() {
          _accessToken = response.accessToken;
          _refreshToken = response.refreshToken;
          _userId = response.userId ?? _userId;
          _email = response.email ?? _email;
          _jwtClaims = claims;
          _accessExpDate = expDate;
          _accessIatDate = iatDate;
          _accessLifespan = lifespan;
          _refreshExpDate = refExp;
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

  Future<void> _openJwtIo(String token) async {
    final url = Uri.parse('https://jwt.io/#debugger-io?token=$token');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _copyToClipboard(url.toString(), 'jwt.io Bağlantısı');
      }
    } catch (_) {
      _copyToClipboard(url.toString(), 'jwt.io Bağlantısı');
    }
  }

  String get _accessStorageLocation {
    if (kIsWeb) {
      return 'Web Secure Storage (Memory / Authorization Header)';
    }
    if (Platform.isIOS) {
      return 'Apple Keychain (kSecAttrAccessibleAfterFirstUnlock)';
    }
    if (Platform.isMacOS) {
      return 'macOS Keychain Services (Hardware Security)';
    }
    if (Platform.isAndroid) {
      return 'Android Keystore + EncryptedSharedPreferences (AES-256 GCM)';
    }
    return 'Cihaz Güvenli Depolaması';
  }

  String get _refreshStorageLocation {
    if (kIsWeb) {
      return 'HttpOnly SameSite Secure Cookie (Tarayıcı JS okuyamaz, sunucuya şifreli taşınır)';
    }
    if (Platform.isIOS) {
      return 'Apple Keychain (kSecAttrAccessibleAfterFirstUnlock)';
    }
    if (Platform.isMacOS) {
      return 'macOS Keychain Services (Hardware Security)';
    }
    if (Platform.isAndroid) {
      return 'Android Keystore + EncryptedSharedPreferences (AES-256 GCM)';
    }
    return 'Cihaz Güvenli Depolaması';
  }

  String _formatRemainingHuman(DateTime? expDate) {
    if (expDate == null) return 'Bilinmiyor';
    final diff = expDate.difference(DateTime.now());
    if (diff.isNegative) return 'Süresi Doldu';

    if (diff.inDays > 0) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final mins = diff.inMinutes % 60;
      return '$days gün $hours sa $mins dk';
    }
    if (diff.inHours > 0) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      final secs = diff.inSeconds % 60;
      return '$hours sa $mins dk $secs sn';
    }
    final mins = diff.inMinutes;
    final secs = diff.inSeconds % 60;
    return '$mins dk $secs sn';
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Banner (Responsive & Mobile-Proof)
                      _buildHeaderBanner(isDark, isAuthenticated, remainingTimeStr),

                      const SizedBox(height: 18),

                      // 2. Access Token Card (JWT)
                      _buildAccessTokenCard(isDark, remainingTimeStr),

                      const SizedBox(height: 18),

                      // 3. Refresh Token Card
                      _buildRefreshTokenCard(isDark),

                      const SizedBox(height: 18),

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
      padding: const EdgeInsets.all(16),
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
          // Title Row with Shield
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cookie & Token Demo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'WordStation Auth Mimarisinin Röntgeni',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Actions & Status Badges Row (Wraps naturally on any screen size)
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
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
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
                            fontSize: 12.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isAuthenticated
                      ? const Color(0xFF34C759).withValues(alpha: 0.18)
                      : AppColors.error.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
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
                      size: 14,
                      color: isAuthenticated ? const Color(0xFF34C759) : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAuthenticated ? 'Authenticated' : 'Unauthenticated',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAuthenticated ? const Color(0xFF34C759) : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),

              // Remaining Live Timer Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222533) : const Color(0xFFE9E9EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF007AFF)),
                    const SizedBox(width: 5),
                    Text(
                      'Kalan: $remainingTimeStr',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTokenCard(bool isDark, String remainingTimeStr) {
    final expFormatted = _accessExpDate != null ? JwtDecoder.formatDate(_accessExpDate) : 'Bilinmiyor';
    final iatFormatted = _accessIatDate != null ? JwtDecoder.formatDate(_accessIatDate) : 'Bilinmiyor';
    final lifespanStr = JwtDecoder.formatLifespan(_accessLifespan);
    final remainingHuman = _formatRemainingHuman(_accessExpDate);

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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Access Token (JWT)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info 1: Tutulduğu Yer (Storage Location)
                _buildInfoTag(
                  icon: Icons.storage_rounded,
                  label: 'Tutulduğu Yer:',
                  value: _accessStorageLocation,
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                // Info 2: Ömrü & Kalan Süre
                _buildInfoTag(
                  icon: Icons.access_time_filled_rounded,
                  label: 'Token Ömrü:',
                  value: '$lifespanStr  •  Kalan: $remainingHuman ($remainingTimeStr)',
                  color: const Color(0xFF34C759),
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                // Info 3: Başlangıç & Bitiş Tarihleri
                _buildInfoTag(
                  icon: Icons.date_range_rounded,
                  label: 'Geçerlilik:',
                  value: '$iatFormatted → $expFormatted',
                  color: const Color(0xFFFF9500),
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Raw Token Header with Actions (Copy & jwt.io)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Raw Token (JWT)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        // Copy Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _accessToken != null
                                ? () => _copyToClipboard(_accessToken!, 'Access Token')
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF222533) : const Color(0xFFE9E9EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded, size: 14),
                                  SizedBox(width: 4),
                                  Text('Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // jwt.io Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _accessToken != null ? () => _openJwtIo(_accessToken!) : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFFFF9500)),
                                  SizedBox(width: 4),
                                  Text(
                                    'jwt.io ↗',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF9500)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Token Raw Monospace Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1015) : const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF232634) : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: SelectableText(
                    _accessToken ?? 'Access Token bulunamadı.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Color(0xFF64B5F6),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshTokenCard(bool isDark) {
    final refExpFormatted = _refreshExpDate != null ? JwtDecoder.formatDate(_refreshExpDate) : 'Bilinmiyor';
    final refRemainingHuman = _formatRemainingHuman(_refreshExpDate);

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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFF9500),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.autorenew_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Refresh Token',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info 1: Tutulduğu Yer
                _buildInfoTag(
                  icon: Icons.shield_rounded,
                  label: 'Tutulduğu Yer:',
                  value: _refreshStorageLocation,
                  color: const Color(0xFFFF9500),
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                // Info 2: Ömrü & Kalan Süre
                _buildInfoTag(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Token Ömrü:',
                  value: '7 Gün  •  Kalan: $refRemainingHuman',
                  color: const Color(0xFF34C759),
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                // Info 3: Bitiş Tarihi
                _buildInfoTag(
                  icon: Icons.event_available_rounded,
                  label: 'Bitiş Tarihi:',
                  value: refExpFormatted,
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Raw Token Header with Copy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Opaque Token (JWT değildir, decode edilemez)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _refreshToken != null
                            ? () => _copyToClipboard(_refreshToken!, 'Refresh Token')
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222533) : const Color(0xFFE9E9EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 14),
                              SizedBox(width: 4),
                              Text('Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1015) : const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF232634) : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: SelectableText(
                    _refreshToken ?? 'Refresh Token bulunamadı.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Color(0xFFFFB74D),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsTableCard(bool isDark) {
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
      final preview = _accessToken!.length > 30
          ? '${_accessToken!.substring(0, 25)}...'
          : _accessToken!;
      rows.add(MapEntry('Token', preview));
    }

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      final preview = _refreshToken!.length > 25
          ? '${_refreshToken!.substring(0, 20)}...'
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Cookie & Depolama Bilgileri (Claims)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${rows.length} adet',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Storage Diagnostic Box
                Container(
                  padding: const EdgeInsets.all(12),
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
                      const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF00C7BE)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platform: $_accessStorageLocation',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00C7BE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tokenlar platformun donanım destekli güvenli kasasında şifreli saklanır. Ağ isteklerinde otomatik Authorization Bearer başlığıyla gönderilir.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Claim Type',
                          style: TextStyle(
                            fontSize: 12,
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
                            fontSize: 12,
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.key,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF9500),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6,
                            child: InkWell(
                              onTap: () => _copyToClipboard(item.value, item.key),
                              borderRadius: BorderRadius.circular(6),
                              child: Text(
                                item.value,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
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

  Widget _buildInfoTag({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
