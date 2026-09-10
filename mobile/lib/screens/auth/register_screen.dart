import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_shell.dart';

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
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name, email, and password.')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    context.push('/register/role', extra: {
      'name': name,
      'email': email,
      'phone': _phoneController.text.trim(),
      'password': password,
    });
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
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Continue', onPressed: _continue),
          ],
        ),
      ),
    );
  }
}

class RegisterRoleScreen extends StatefulWidget {
  const RegisterRoleScreen({super.key, required this.draft});

  final Map<String, dynamic> draft;

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
            LinearProgressIndicator(
              value: 0.66,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primary,
            ),
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
                  : () => context.push('/register/details', extra: {
                        ...widget.draft,
                        'role': _selectedRole,
                      }),
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

class RegisterDetailsScreen extends StatefulWidget {
  const RegisterDetailsScreen({super.key, required this.draft});

  final Map<String, dynamic> draft;

  @override
  State<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends State<RegisterDetailsScreen> {
  final _specialtyController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _feeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _bloodController = TextEditingController();
  final _allergiesController = TextEditingController();
  bool _loading = false;

  UserRole get _role => widget.draft['role'] as UserRole;

  @override
  void dispose() {
    _specialtyController.dispose();
    _qualificationsController.dispose();
    _feeController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _bloodController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _dobController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_role == UserRole.doctor) {
      if (_specialtyController.text.trim().isEmpty || _feeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Specialty and consultation fee are required.')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final store = context.read<AppStore>();
      await store.register(
        name: widget.draft['name'] as String,
        email: widget.draft['email'] as String,
        password: widget.draft['password'] as String,
        phone: widget.draft['phone'] as String?,
        role: _role,
        specialty: _specialtyController.text.trim(),
        consultationFee: double.tryParse(_feeController.text.trim()),
        qualifications: _qualificationsController.text.trim(),
        yearsExperience: int.tryParse(_experienceController.text.trim()),
        bio: _bioController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _genderController.text.trim(),
        bloodGroup: _bloodController.text.trim(),
        allergies: _allergiesController.text.trim(),
      );

      if (!mounted) return;

      if (_role == UserRole.doctor) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. An admin must verify your profile before patients can book you.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully.')),
        );
      }
      context.go(homeRouteForRole(store.currentUser!.role));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              _role == UserRole.doctor ? 'Doctor Profile' : 'Patient Profile',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 1,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            if (_role == UserRole.patient) ...[
              TextField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDob,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bloodController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Known Allergies',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
            ] else ...[
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty *',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _qualificationsController,
                decoration: const InputDecoration(
                  labelText: 'Qualifications',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Consultation Fee (GHS) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  prefixIcon: Icon(Icons.timeline_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: _loading ? 'Creating account...' : 'Complete Registration',
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
