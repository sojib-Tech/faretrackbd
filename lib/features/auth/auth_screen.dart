import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbController;
  late final TabController _tabController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authProvider.notifier)
        .logIn(_emailController.text, _passwordController.text);
    if (success && mounted) {
      FocusScope.of(context).unfocus();
      context.go(ref.read(authProvider).isAdmin ? '/admin' : '/home');
    }
  }

  Future<void> _handleSignUp() async {
    try {
      FocusScope.of(context).unfocus();

      final rawEmail = _emailController.text;
      final email = rawEmail.trim();

      if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'সঠিক Email address দিন',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final success = await ref
          .read(authProvider.notifier)
          .signUp(_nameController.text, email, _passwordController.text);
      if (success && mounted) {
        FocusScope.of(context).unfocus();
        context.go('/home');
      }
    } catch (e, stack) {
      debugPrint('--- [UI CRASH]: $e');
      debugPrint('--- [UI CRASH] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ক্র্যাশ: ${e.toString()}',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B0B2E), Color(0xFF120A24), Color(0xFF0A0612)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _OrbPainter(_orbController.value),
                );
              },
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 20),
                      _buildHeading(),
                      const SizedBox(height: 32),
                      _buildTabToggle(),
                      const SizedBox(height: 24),
                      _buildForm(authState),
                      const SizedBox(height: 20),
                      _buildBottomText(),
                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 16),
                      _buildGoogleOption(authState),
                      const SizedBox(height: 12),
                      _buildGuestOption(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }

  Widget _buildHeading() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Column(
          children: [
            Text(
              _tabController.index == 0 ? 'Welcome Back' : 'Create Account',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tabController.index == 0
                  ? 'Sign in to continue your journey'
                  : 'Join us and start tracking',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF8B8FA3),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabItem('Sign In', 0),
          const SizedBox(width: 4),
          _buildTabItem('Sign Up', 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: LinearGradient(
            colors: isSelected
                ? const [Color(0xFF7C3AED), Color(0xFF3B82F6)]
                : const [
                    Color(0xFF7C3AED),
                    Color(0xFF3B82F6),
                  ].map((c) => c.withValues(alpha: 0.0)).toList(),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuint,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOutQuint,
      switchOutCurve: Curves.easeInOutQuint,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutQuint,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      child: _tabController.index == 0
          ? _buildSignInForm(authState)
          : _buildSignUpForm(authState),
    );
  }

  Widget _buildSignInForm(AuthState authState) {
    return Column(
      key: const ValueKey('signin'),
      children: [
        const SizedBox(height: 20),
        _buildField(
          controller: _emailController,
          focusNode: _emailFocus,
          hint: 'Email',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          hint: 'Password',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showForgotPasswordSheet(),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
        if (authState.error != null) _buildError(authState.error!),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: 'Sign In',
          isLoading: authState.isLoading,
          onTap: _handleSignIn,
        ),
      ],
    );
  }

  Widget _buildSignUpForm(AuthState authState) {
    return Column(
      key: const ValueKey('signup'),
      children: [
        const SizedBox(height: 20),
        _buildField(
          controller: _nameController,
          focusNode: _nameFocus,
          hint: 'Full Name',
          icon: Icons.person_outlined,
          enabled: true,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _emailController,
          focusNode: _emailFocus,
          hint: 'Email',
          icon: Icons.email_outlined,
          enabled: true,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          hint: 'Password',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          enabled: true,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          hint: 'Confirm Password',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          enabled: true,
        ),
        if (authState.error != null) _buildError(authState.error!),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: 'Create Account',
          isLoading: authState.isLoading,
          onTap: _handleSignUp,
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
        border: Border.all(
          color: focusNode.hasFocus && enabled
              ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        style: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.4),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: const Color(
              0xFFFFFFFF,
            ).withValues(alpha: enabled ? 0.25 : 0.1),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: (focusNode.hasFocus && enabled)
                ? const Color(0xFF7C3AED).withValues(alpha: 0.7)
                : const Color(
                    0xFFFFFFFF,
                  ).withValues(alpha: enabled ? 0.3 : 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
        border: Border.all(
          color: focusNode.hasFocus && enabled
              ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        enabled: enabled,
        style: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.4),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: const Color(
              0xFFFFFFFF,
            ).withValues(alpha: enabled ? 0.25 : 0.1),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(
            Icons.lock_outlined,
            size: 20,
            color: (focusNode.hasFocus && enabled)
                ? const Color(0xFF7C3AED).withValues(alpha: 0.7)
                : const Color(
                    0xFFFFFFFF,
                  ).withValues(alpha: enabled ? 0.3 : 0.1),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          error,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFEF4444).withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox.shrink();
  }

  Widget _buildBottomText() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return GestureDetector(
          onTap: () =>
              _tabController.animateTo(_tabController.index == 0 ? 1 : 0),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF8B8FA3),
              ),
              children: [
                TextSpan(
                  text: _tabController.index == 0
                      ? "Don't have an account? "
                      : 'Already have an account? ',
                ),
                TextSpan(
                  text: _tabController.index == 0 ? 'Sign Up' : 'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) context.go('/home');
  }

  Widget _buildGuestOption() {
    return GestureDetector(
      onTap: () async {
        await ref.read(authProvider.notifier).enterGuestMode();
        if (mounted) context.go('/home');
      },
      child: Text(
        'সাইন-ইন ছাড়া চালু করুন',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildGoogleOption(AuthState authState) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: authState.isLoading ? null : _handleGoogleSignIn,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
        label: const Text('Google দিয়ে সাইন ইন করুন'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotPasswordSheet(
        emailController: emailCtrl,
        onSent: () {
          Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Password reset email sent'),
                backgroundColor: const Color(0xFF27AE60),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double value;

  _OrbPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    _drawOrb(
      canvas,
      paint,
      size,
      0.2 + 0.12 * math.sin(value * 2 * math.pi),
      0.15 + 0.1 * math.cos(value * 2 * math.pi * 0.7),
      220,
      const Color(0xFF7C3AED).withValues(alpha: 0.12),
    );

    _drawOrb(
      canvas,
      paint,
      size,
      0.7 + 0.15 * math.cos(value * 2 * math.pi * 0.6),
      0.6 + 0.12 * math.sin(value * 2 * math.pi * 0.8),
      180,
      const Color(0xFF3B82F6).withValues(alpha: 0.1),
    );

    _drawOrb(
      canvas,
      paint,
      size,
      0.5 + 0.1 * math.sin(value * 2 * math.pi * 0.5 + 1),
      0.85 + 0.08 * math.cos(value * 2 * math.pi * 0.4),
      140,
      const Color(0xFF8B5CF6).withValues(alpha: 0.08),
    );
  }

  void _drawOrb(
    Canvas canvas,
    Paint paint,
    Size size,
    double x,
    double y,
    double diameter,
    Color color,
  ) {
    paint.color = color;
    canvas.drawCircle(
      Offset(size.width * x, size.height * y),
      diameter / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final VoidCallback onSent;

  const _ForgotPasswordSheet({
    required this.emailController,
    required this.onSent,
  });

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  bool _sending = false;

  Future<void> _sendReset() async {
    setState(() => _sending = true);
    final error = await ref
        .read(authProvider.notifier)
        .resetPassword(widget.emailController.text);
    setState(() => _sending = false);
    if (error == null) {
      widget.onSent();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1A1A2E),
          border: Border.all(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                ),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reset Password',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email to receive a password reset link',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF8B8FA3),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
                border: Border.all(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: widget.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendReset(),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Email',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.25),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 20,
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _sending ? null : _sendReset,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Send Reset Link',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
