import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';

/// Two-beat splash: the Mindar mark, then the slogan, before routing to
/// either the calendar (if a session token exists) or the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _frame = 0; // 0 = icon, 1 = slogan
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _frame = 1);

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;

    final loggedIn = await _api.hasSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => loggedIn ? const CalendarScreen() : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _frame == 0 ? _iconFrame() : _sloganFrame(),
      ),
    );
  }

  Widget _iconFrame() {
    return Center(
      key: const ValueKey('icon'),
      child: Image.asset('assets/mindar_icon.png', width: 180, height: 180),
    );
  }

  Widget _sloganFrame() {
    return Center(
      key: const ValueKey('slogan'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/mindar_icon.png', width: 90, height: 90),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineMedium,
                children: const [
                  TextSpan(text: 'Make room for '),
                  TextSpan(text: 'what matters.', style: TextStyle(color: AppColors.accent, fontStyle: FontStyle.italic)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
