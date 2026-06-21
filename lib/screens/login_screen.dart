import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../auth/models/app_user.dart';
import '../providers/theme_provider.dart';
import 'dashboard_screen.dart';
import 'employee_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import '../owner/screens/owner_dashboard_screen.dart';
import '../super_admin/screens/super_admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _bgController;   // background gradient shift
  late AnimationController _orb1Controller; // top-right orb drift
  late AnimationController _orb2Controller; // bottom-left orb drift
  late AnimationController _cardController; // card entrance

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
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
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
        _errorMessage =
            authProvider.error ?? 'Login failed. Please check your credentials.';
      });
    }
  }

  void _navigateByRole(AuthProvider authProvider) {
    final role = authProvider.userRole ?? UserRole.employee;
    Widget destination;

    switch (role) {
      case UserRole.superUser:
        destination = const DashboardScreen(); // Global dashboard handles SuperUser too
        break;
      case UserRole.admin:
        destination = const DashboardScreen();
        break;
      case UserRole.employee:
        destination = const EmployeeDashboardScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogoSection(),
                        const SizedBox(height: 36),
                        _buildGlassCard(),
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
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF1A0533), const Color(0xFF0D1B4B),
                  _bgController.value)!,
              Color.lerp(const Color(0xFF3B0764), const Color(0xFF1E1B4B),
                  _bgController.value)!,
              Color.lerp(const Color(0xFF4C1D95), const Color(0xFF1A1A4E),
                  _bgController.value)!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingOrbs(Size size) {
    return Stack(
      children: [
        // Orb 1 — top right, purple
        AnimatedBuilder(
          animation: _orb1Controller,
          builder: (_, __) => Positioned(
            right: -80 + 40 * _orb1Controller.value,
            top: -60 + 30 * _orb1Controller.value,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.28),
                  const Color(0xFF7C3AED).withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
        ),
        // Orb 2 — bottom left, cyan
        AnimatedBuilder(
          animation: _orb2Controller,
          builder: (_, __) => Positioned(
            left: -100 + 50 * _orb2Controller.value,
            bottom: -80 + 40 * _orb2Controller.value,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF06B6D4).withValues(alpha: 0.18),
                  const Color(0xFF06B6D4).withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
        ),
        // Orb 3 — centre-ish, pink
        AnimatedBuilder(
          animation: _bgController,
          builder: (_, __) => Positioned(
            left: size.width * 0.35 + 20 * _bgController.value,
            top: size.height * 0.12,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFF806CC).withValues(alpha: 0.13),
                  const Color(0xFFF806CC).withValues(alpha: 0.0),
                ]),
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
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFFF806CC)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.55),
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

  // ── Glass login card ──────────────────────────────────────────────────────

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Sign in to continue to your dashboard',
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
                  child: _errorMessage != null
                      ? _buildErrorBanner()
                      : const SizedBox.shrink(),
                ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // ── Username ────────────────────────────────────────────────
                _buildField(
                  controller: _usernameController,
                  label: 'Username or Email',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your username or email';
                    }
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
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              fillColor: WidgetStateProperty.resolveWith((s) {
                                if (s.contains(WidgetState.selected)) {
                                  return const Color(0xFF7C3AED);
                                }
                                return Colors.transparent;
                              }),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
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
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA78BFA),
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
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon,
            color: Colors.white.withValues(alpha: 0.55), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontSize: 13),
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
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: loading
                    ? [const Color(0xFF4B2A7A), const Color(0xFF7B3FA0)]
                    : [const Color(0xFF7C3AED), const Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED)
                      .withValues(alpha: loading ? 0.2 : 0.45),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
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
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
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
