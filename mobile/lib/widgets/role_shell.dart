import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../store/app_store.dart';
import '../models/user_role.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key, required this.child});

  final Widget child;

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  static const _routes = [
    '/patient/home',
    '/patient/appointments',
    '/patient/messages',
    '/patient/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    _index = _routes.indexWhere((r) => location.startsWith(r));
    if (_index < 0) _index = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => context.go(_routes[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key, required this.child});

  final Widget child;

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _index = 0;

  static const _routes = [
    '/doctor/home',
    '/doctor/messages',
    '/doctor/patients',
    '/doctor/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    _index = _routes.indexWhere((r) => location.startsWith(r));
    if (_index < 0) _index = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => context.go(_routes[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), activeIcon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AppStore>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) {
          Navigator.pop(context);
          switch (i) {
            case 0:
              context.go('/admin/home');
            case 1:
              context.go('/admin/doctors');
            case 2:
              context.go('/admin/reports');
          }
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(28, 28, 16, 16),
            child: Text(
              'Smart Health',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: Text('Doctors'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: Text('Reports'),
          ),
        ],
      ),
      body: child,
    );
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/admin/doctors')) return 1;
    if (loc.startsWith('/admin/reports')) return 2;
    return 0;
  }
}

String homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.patient:
      return '/patient/home';
    case UserRole.doctor:
      return '/doctor/home';
    case UserRole.admin:
      return '/admin/home';
  }
}
