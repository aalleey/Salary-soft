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
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _cardController;

  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _orb1Controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _orb2Controller = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat(reverse: true);

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );

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
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _cardController.dispose();
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
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  // ── Palettes based on mode ────────────────────────────────────────────────
  List<Color> get _currentPalette {
    switch (_mode) {
      case LoginMode.client:
        return [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF312E81)];
      case LoginMode.owner:
        return [const Color(0xFF1A0533), const Color(0xFF0F081C), const Color(0xFF2E0942)];
      case LoginMode.selection:
        return [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF1A0533)];
    }
  }

  Color get _primaryColor {
    switch (_mode) {
      case LoginMode.client:
        return const Color(0xFF3B82F6); // Blue
      case LoginMode.owner:
        return const Color(0xFFF806CC); // Magenta
      case LoginMode.selection:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackground(),
          _buildFloatingOrbs(size),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogoSection(),
                        const SizedBox(height: 36),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          child: _mode == LoginMode.selection
                              ? _buildSelectionView()
                              : _buildGlassCard(),
                        ),
                        const SizedBox(height: 24),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => IconButton(
                    icon: Icon(
                      theme.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => theme.toggleTheme(),
                    tooltip: theme.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background & orbs ─────────────────────────────────────────────────────

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final p = _currentPalette;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(p[0], p[1], _bgController.value)!,
                Color.lerp(p[1], p[2], _bgController.value)!,
                Color.lerp(p[2], p[0], _bgController.value)!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrbs(Size size) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _orb1Controller,
          builder: (context, child) => Positioned(
            right: -80 + 40 * _orb1Controller.value,
            top: -60 + 30 * _orb1Controller.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryColor.withValues(alpha: 0.28),
                    _primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orb2Controller,
          builder: (context, child) => Positioned(
            left: -100 + 50 * _orb2Controller.value,
            bottom: -80 + 40 * _orb2Controller.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.18),
                    const Color(0xFF06B6D4).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogoSection() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF7C3AED), _primaryColor],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.55),
                blurRadius: 32,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'SalarySoft',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enterprise Payroll Management',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.60),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ── Portal Selection ──────────────────────────────────────────────────────

  Widget _buildSelectionView() {
    return Column(
      key: const ValueKey('selection'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPortalCard(
          title: 'Client & Staff Portal',
          subtitle: 'For institutes and employees',
          icon: Icons.business_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => _setMode(LoginMode.client),
        ),
        const SizedBox(height: 20),
        _buildPortalCard(
          title: 'Software Owner Portal',
          subtitle: 'For super admin management',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFFF806CC),
          onTap: () => _setMode(LoginMode.owner),
        ),
      ],
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Glass login card ──────────────────────────────────────────────────────

  Widget _buildGlassCard() {
    final title = _mode == LoginMode.client ? 'Client Portal' : 'Owner Portal';
    final subtitle = _mode == LoginMode.client 
      ? 'Sign in to your institute dashboard' 
      : 'Sign in to the central management system';

    return ClipRRect(
      key: const ValueKey('form'),
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => _setMode(LoginMode.selection),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Header ─────────────────────────────────────────────────
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 26),

                // ── Error banner ────────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: _errorMessage != null ? _buildErrorBanner() : const SizedBox.shrink(),
                ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // ── Username ────────────────────────────────────────────────
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

                // ── Password ────────────────────────────────────────────────
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

                // ── Remember me + Forgot password ───────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                              fillColor: WidgetStateProperty.resolveWith((s) {
                                if (s.contains(WidgetState.selected)) return _primaryColor;
                                return Colors.transparent;
                              }),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // ── Sign In button ──────────────────────────────────────────
                _buildSignInButton(),
              ],
            ),
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
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.55), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
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
              color: const Color(0xFFEF4444).withValues(alpha: 0.7),
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
            height: 54,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: loading ? 0.5 : 1.0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: loading ? 0.2 : 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
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
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
    return Text(
      'SalarySoft v1.0  •  Secure & Encrypted',
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }
}
