import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 1 of 3', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.33,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Continue',
              onPressed: () => context.push('/register/role'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterRoleScreen extends StatefulWidget {
  const RegisterRoleScreen({super.key});

  @override
  State<RegisterRoleScreen> createState() => _RegisterRoleScreenState();
}

class _RegisterRoleScreenState extends State<RegisterRoleScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 2 of 3', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('I am a...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.66, backgroundColor: Colors.grey.shade200, color: AppColors.primary),
            const SizedBox(height: 32),
            _RoleCard(
              icon: Icons.person,
              title: 'Patient',
              subtitle: 'Book appointments and consult doctors',
              selected: _selectedRole == UserRole.patient,
              onTap: () => setState(() => _selectedRole = UserRole.patient),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.medical_services,
              title: 'Doctor',
              subtitle: 'Manage schedule and consult patients',
              selected: _selectedRole == UserRole.doctor,
              onTap: () => setState(() => _selectedRole = UserRole.doctor),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Continue',
              onPressed: _selectedRole == null
                  ? null
                  : () => context.push('/register/details', extra: _selectedRole),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class RegisterDetailsScreen extends StatelessWidget {
  const RegisterDetailsScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 3 of 3', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              role == UserRole.doctor ? 'Doctor Profile' : 'Patient Profile',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 1, backgroundColor: Colors.grey.shade200, color: AppColors.primary),
            const SizedBox(height: 32),
            if (role == UserRole.patient) ...[
              const TextField(decoration: InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake_outlined))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Blood Group', prefixIcon: Icon(Icons.bloodtype_outlined))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Known Allergies', prefixIcon: Icon(Icons.warning_amber_outlined))),
            ] else ...[
              const TextField(decoration: InputDecoration(labelText: 'Specialty', prefixIcon: Icon(Icons.medical_information_outlined))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Qualifications', prefixIcon: Icon(Icons.school_outlined))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Consultation Fee (GHS)', prefixIcon: Icon(Icons.payments_outlined))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Working Hours', prefixIcon: Icon(Icons.schedule_outlined))),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Complete Registration',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account created (mock). Please login.')),
                );
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
