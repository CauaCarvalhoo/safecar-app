import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_page.dart';
import 'screens/intro_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SafeCarApp());
}

class SafeCarApp extends StatelessWidget {
  const SafeCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeCar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),

        '/intro1': (context) => const IntroPage(
              icon: Icons.security,
              title: 'Proteção inteligente para o seu veículo',
              subtitle: 'Monitore portas, vidros, faróis e possíveis impactos em tempo real.',
              showSkip: true,
              nextRoute: '/intro2',
            ),

        '/intro2': (context) => const IntroPage(
              icon: Icons.sensors,
              title: 'Sensores conectados ao ESP32',
              subtitle: 'O protótipo já funciona em modo simulação e está preparado para receber sensores reais.',
              nextRoute: '/intro3',
              backRoute: '/intro1',
            ),

        '/intro3': (context) => const IntroPage(
              icon: Icons.notifications_active_outlined,
              title: 'Alertas claros no aplicativo',
              subtitle: 'Receba avisos de faróis acesos, vidros abertos e movimentações suspeitas.',
              nextRoute: '/register',
              backRoute: '/intro2',
            ),

        '/register': (context) => const RegisterPage(),
        '/login_user': (context) => const LoginPage(userType: 'usuario'),
        '/login_assistant': (context) => const LoginPage(userType: 'assistente'),
        '/home': (context) => const HomePage(),
      },
    );
  }
}