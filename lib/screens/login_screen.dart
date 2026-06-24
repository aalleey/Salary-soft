import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../auth/models/app_user.dart';
import '../providers/theme_provider.dart';
import 'dashboard_screen.dart';
import 'employee_dashboard_screen.dart';
import 'superadmin/superadmin_dashboard_screen.dart';
import 'forgot_password_screen.dart';

enum LoginMode { selection, client, owner }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  LoginMode _mode = LoginMode.selection;

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _bgController;
  late AnimationController _orbController;
  late AnimationController _cardController;
  late AnimationController _shimmerController;

  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _orbController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    _cardController.forward();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final saved = await authProvider.getSavedUsername();
    if (saved != null && mounted) {
      setState(() {
        _usernameController.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _orbController.dispose();
    _cardController.dispose();
    _shimmerController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login logic ───────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (success) {
      _navigateByRole(authProvider);
    } else {
      setState(() {
        _errorMessage = authProvider.error ?? 'Login failed. Please check your credentials.';
      });
    }
  }

  void _navigateByRole(AuthProvider authProvider) {
    final role = authProvider.userRole ?? UserRole.staff;
    Widget destination;

    switch (role) {
      case UserRole.superAdmin:
        destination = const SuperAdminDashboardScreen();
        break;
      case UserRole.clientAdmin:
      case UserRole.lowerAdmin:
        destination = const DashboardScreen();
        break;
      case UserRole.staff:
        destination = const EmployeeDashboardScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _setMode(LoginMode mode) {
    _cardController.reset();
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
    _cardController.forward();
  }

  // ── Colors based on mode ──────────────────────────────────────────────────
  Color get _accentColor {
    switch (_mode) {
      case LoginMode.client:
        return const Color(0xFF00C2FF);
      case LoginMode.owner:
        return const Color(0xFFBB86FC);
      case LoginMode.selection:
        return const Color(0xFF00C2FF);
    }
  }

  Color get _accentColorDark {
    switch (_mode) {
      case LoginMode.client:
        return const Color(0xFF0066FF);
      case LoginMode.owner:
        return const Color(0xFF7C3AED);
      case LoginMode.selection:
        return const Color(0xFF0066FF);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF060D1F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildOrbs(size),
          _buildGridLines(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 40),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _mode == LoginMode.selection
                              ? _buildSelectionView()
                              : _buildLoginCard(),
                        ),
                        const SizedBox(height: 28),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Theme toggle
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        theme.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => theme.toggleTheme(),
                      tooltip: theme.isDarkMode ? 'Light Mode' : 'Dark Mode',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              -0.5 + 1.0 * _bgController.value,
              -0.5 + 0.5 * _bgController.value,
            ),
            radius: 1.6,
            colors: const [
              Color(0xFF0D1F3C),
              Color(0xFF060D1F),
              Color(0xFF020810),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbs(Size size) {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, _) => Stack(
        children: [
          // Top right orb — accent
          Positioned(
            top: -140 + 60 * _orbController.value,
            right: -100 + 40 * _orbController.value,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withValues(alpha: 0.12),
                    _accentColorDark.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom left orb — purple
          Positioned(
            bottom: -120 + 50 * _orbController.value,
            left: -80 + 30 * _orbController.value,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Center subtle glow
          Positioned(
            top: size.height * 0.3,
            left: size.width * 0.1,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withValues(alpha: 0.04 * _orbController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo mark
        AnimatedBuilder(
          animation: _orbController,
          builder: (context, _) {
            final pulse = 0.97 + 0.03 * _orbController.value;
            return Transform.scale(
              scale: pulse,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _accentColor.withValues(alpha: 0.18 * pulse),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_accentColorDark, _accentColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.4 * pulse),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // App name with shimmer
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            return ShaderMask(
              shaderCallback: (bounds) {
                final t = _shimmerController.value;
                return LinearGradient(
                  begin: Alignment(t * 3 - 1.5, 0),
                  end: Alignment(t * 3 - 0.5, 0),
                  colors: [
                    Colors.white,
                    Colors.white,
                    _accentColor,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ).createShader(bounds);
              },
              child: const Text(
                'SalarySoft',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
            color: _accentColor.withValues(alpha: 0.06),
          ),
          child: Text(
            'ENTERPRISE PAYROLL MANAGEMENT',
            style: TextStyle(
              fontSize: 10.5,
              color: _accentColor.withValues(alpha: 0.9),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Portal Selection View ─────────────────────────────────────────────────

  Widget _buildSelectionView() {
    return Column(
      key: const ValueKey('selection'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose Your Portal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the portal you want to access',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 28),
        _buildPortalTile(
          title: 'Client & Staff Portal',
          subtitle: 'For institutes, admins and employees',
          icon: Icons.corporate_fare_rounded,
          accentColor: const Color(0xFF00C2FF),
          darkColor: const Color(0xFF0066FF),
          tag: 'STAFF',
          onTap: () => _setMode(LoginMode.client),
        ),
        const SizedBox(height: 16),
        _buildPortalTile(
          title: 'Software Owner Portal',
          subtitle: 'Central system management & control',
          icon: Icons.admin_panel_settings_rounded,
          accentColor: const Color(0xFFBB86FC),
          darkColor: const Color(0xFF7C3AED),
          tag: 'ADMIN',
          onTap: () => _setMode(LoginMode.owner),
        ),
        const SizedBox(height: 20),
        // Divider with label
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.08),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'SECURED BY AES-256',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.2),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.08),
                thickness: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortalTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color darkColor,
    required String tag,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [darkColor, accentColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tag + arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.25),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Login Card ────────────────────────────────────────────────────────────

  Widget _buildLoginCard() {
    final isClient = _mode == LoginMode.client;
    final title = isClient ? 'Client Portal' : 'Owner Portal';
    final subtitle = isClient
        ? 'Sign in to your institute dashboard'
        : 'Access the central management system';
    final icon = isClient ? Icons.corporate_fare_rounded : Icons.admin_panel_settings_rounded;

    return ClipRRect(
      key: ValueKey(_mode),
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card header with accent strip
              Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => _setMode(LoginMode.selection),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [_accentColorDark, _accentColor],
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error banner
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        child: _errorMessage != null ? _buildErrorBanner() : const SizedBox.shrink(),
                      ),
                      if (_errorMessage != null) const SizedBox(height: 16),

                      // Username field
                      _buildField(
                        controller: _usernameController,
                        label: 'Username or Email',
                        icon: Icons.person_outline_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter your username or email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      _buildField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Remember me + forgot password
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: _rememberMe
                                          ? _accentColor
                                          : Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    color: _rememberMe
                                        ? _accentColor.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                  ),
                                  child: _rememberMe
                                      ? Icon(Icons.check_rounded,
                                          size: 12, color: _accentColor)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                color: _accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sign in button
                      _buildSignInButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field ─────────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13.5),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 19),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 19,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(
              Icons.close_rounded,
              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign In button ────────────────────────────────────────────────────────

  Widget _buildSignInButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final loading = auth.isLoading;
        return GestureDetector(
          onTap: loading ? null : _handleLogin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: loading
                    ? [
                        _accentColorDark.withValues(alpha: 0.5),
                        _accentColor.withValues(alpha: 0.5),
                      ]
                    : [_accentColorDark, _accentColor],
              ),
              boxShadow: loading
                  ? []
                  : [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 11, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 5),
            Text(
              'Secure  •  Encrypted  •  Trusted',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'SalarySoft v2.0',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

// ── Grid line painter ──────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C2FF).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner accent dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00C2FF).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

