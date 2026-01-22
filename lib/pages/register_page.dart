import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_textfield.dart';
import 'main_navigation_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _image;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _image != null
                      ? (kIsWeb
                            ? NetworkImage(_image!.path)
                            : FileImage(File(_image!.path)) as ImageProvider)
                      : null,
                  child: _image == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Upload Profile Picture",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _usernameController,
                label: "Username",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _fullNameController,
                label: "Full Name",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _bioController,
                label: "Bio",
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return auth.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              bool success = await auth.register(
                                username: _usernameController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                                fullName: _fullNameController.text,
                                bio: _bioController.text,
                                profileImage: _image,
                              );

                              if (success && context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MainNavigationPage(),
                                  ),
                                  (route) => false,
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Registration failed. Please try again.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text("REGISTER"),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
