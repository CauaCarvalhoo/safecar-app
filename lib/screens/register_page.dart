import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _profileType = 'usuario';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'Não foi possível criar o usuário.',
        );
      }

      await user.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'profileType': _profileType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
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
          content: Text('Não foi possível criar a conta. Tente novamente.'),
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
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet.';
      default:
        return 'Erro ao criar conta. Código: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Criar conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre-se para acessar o protótipo SafeCar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';

                        if (name.length < 3) {
                          return 'Informe seu nome completo.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Informe seu e-mail.';
                        }

                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Informe um e-mail válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _profileType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de perfil',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'usuario',
                          child: Text('Usuário'),
                        ),
                        DropdownMenuItem(
                          value: 'assistente',
                          child: Text('Assistente técnico'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _profileType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final password = value ?? '';

                        if (password.length < 6) {
                          return 'A senha precisa ter pelo menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final confirmPassword = value ?? '';

                        if (confirmPassword != _passwordController.text) {
                          return 'As senhas não coincidem.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _createAccount,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: Text(_loading ? 'Criando conta...' : 'Criar conta'),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(context, '/login_user');
                            },
                      icon: const Icon(Icons.login),
                      label: const Text('Já tenho conta'),
                    ),
                    const SizedBox(height: 16),

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