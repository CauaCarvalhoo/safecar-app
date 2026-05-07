import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  final String userType;

  const LoginPage({required this.userType, super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Usuário não encontrado.',
        );
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      String profileType = widget.userType;
      String userName = user.displayName ?? 'usuário';

      if (userDoc.exists) {
        final data = userDoc.data();

        profileType = data?['profileType']?.toString() ?? profileType;
        userName = data?['name']?.toString() ?? userName;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo, $userName! Perfil: ${_formatProfileType(profileType)}.'),
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getFirebaseErrorMessage(error.code))),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível fazer login. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet.';
      default:
        return 'Erro ao fazer login. Código: $code';
    }
  }

  String _formatProfileType(String profileType) {
    if (profileType == 'assistente') {
      return 'assistente técnico';
    }

    return 'usuário';
  }

  @override
  Widget build(BuildContext context) {
    final welcomeText = widget.userType == 'usuario'
        ? 'Entre para acompanhar o status do seu veículo.'
        : 'Entre para apoiar a configuração e manutenção do protótipo.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.directions_car_filled_rounded,
                      color: AppTheme.primary,
                      size: 72,
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
                    Text(
                      welcomeText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 34),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Digite seu e-mail.';
                        }

                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Digite um e-mail válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _login();
                        }
                      },
                      validator: (value) {
                        final password = value ?? '';

                        if (password.length < 6) {
                          return 'A senha precisa ter pelo menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(_loading ? 'Entrando...' : 'Entrar'),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Criar nova conta'),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(context, '/intro1');
                            },
                      child: const Text('Voltar para introdução'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}