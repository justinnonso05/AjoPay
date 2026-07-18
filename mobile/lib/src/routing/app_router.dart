import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/bvn_verification_screen.dart';
import '../features/auth/presentation/join_or_create_screen.dart';
import '../features/auth/presentation/create_group_success_screen.dart';
import '../features/auth/presentation/join_group_success_screen.dart';
import '../features/auth/presentation/create_pin_screen.dart';
import '../features/auth/presentation/confirm_pin_screen.dart';
import '../features/home/presentation/home_screen.dart';

enum AppRoute {
  splash,
  onboarding,
  login,
  register,
  bvnVerification,
  joinOrCreate,
  createGroupSuccess,
  joinGroupSuccess,
  pinSetup,
  confirmPin,
  home,
}

final goRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      name: AppRoute.splash.name,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: AppRoute.onboarding.name,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: AppRoute.login.name,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: AppRoute.register.name,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/bvn-verification',
      name: AppRoute.bvnVerification.name,
      builder: (context, state) => const BvnVerificationScreen(),
    ),
    GoRoute(
      path: '/join-or-create',
      name: AppRoute.joinOrCreate.name,
      builder: (context, state) => const JoinOrCreateScreen(),
    ),
    GoRoute(
      path: '/create-group-success',
      name: AppRoute.createGroupSuccess.name,
      builder: (context, state) => CreateGroupSuccessScreen(
        data: state.extra as CreateGroupSuccessData,
      ),
    ),
    GoRoute(
      path: '/join-group-success',
      name: AppRoute.joinGroupSuccess.name,
      builder: (context, state) => JoinGroupSuccessScreen(
        data: state.extra as JoinGroupSuccessData,
      ),
    ),
    GoRoute(
      path: '/pin-setup',
      name: AppRoute.pinSetup.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CreatePinScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/pin-confirm',
      name: AppRoute.confirmPin.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ConfirmPinScreen(pin: state.extra as String),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/home',
      name: AppRoute.home.name,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.error}',
        style: const TextStyle(color: Colors.red),
      ),
    ),
  ),
);
