import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoginChoicePage extends StatelessWidget {
  const LoginChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.directions_car_filled_rounded,
                color: AppTheme.primary,
                size: 74,
              ),
              const SizedBox(height: 12),
              const Text(
                'SafeCar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Escolha o perfil para acessar o protótipo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login_user');
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Sou usuário'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login_assistant');
                },
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Sou assistente técnico'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/intro1');
                },
                child: const Text('Rever introdução'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}