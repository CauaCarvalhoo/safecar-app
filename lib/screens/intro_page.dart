import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? nextRoute;
  final String? backRoute;
  final bool showSkip;

  const IntroPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.nextRoute,
    this.backRoute,
    this.showSkip = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Center(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 104,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showSkip)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text('Pular'),
                    )
                  else if (backRoute != null)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, backRoute!);
                      },
                      child: const Text('Voltar'),
                    )
                  else
                    const SizedBox(width: 120),
                  ElevatedButton(
                    onPressed: nextRoute == null
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(context, nextRoute!);
                          },
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}