import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_textfield.dart';

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
                validator: (value) {
                  if (value == null || !value.endsWith('@gmail.com')) {
                    return "Email must end with @gmail.com";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return "Password must be at least 8 characters long";
                  }
                  if (!RegExp(
                    r'^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$',
                  ).hasMatch(value)) {
                    return "Password must contain letters, numbers, and special characters";
                  }
                  return null;
                },
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Registration successful! Please login.",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      auth.errorMessage.isNotEmpty
                                          ? auth.errorMessage
                                          : "Registration failed. Please try again.",
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
