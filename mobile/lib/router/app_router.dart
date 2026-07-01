import 'package:go_router/go_router.dart';

import '../store/app_store.dart';
import '../models/appointment.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';
import '../screens/admin/admin_screens.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/doctor/doctor_screens.dart';
import '../screens/patient/appointment_screens.dart';
import '../screens/patient/doctor_list_screen.dart';
import '../screens/patient/patient_dashboard_screen.dart';
import '../screens/patient/patient_messages_records_screen.dart';
import '../screens/patient/symptom_checker_screen.dart';
import '../widgets/role_shell.dart';

class AppRouter {
  static GoRouter create(AppStore store) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: store,
      redirect: (context, state) {
        final loggedIn = store.isLoggedIn;
        final loc = state.matchedLocation;
        final isAuth = loc == '/' ||
            loc.startsWith('/login') ||
            loc.startsWith('/register') ||
            loc.startsWith('/forgot-password');

        if (!loggedIn && !isAuth) return '/login';
        if (loggedIn && (loc == '/login' || loc == '/')) {
          return homeRouteForRole(store.currentUser!.role);
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/register/role', builder: (_, __) => const RegisterRoleScreen()),
        GoRoute(
          path: '/register/details',
          builder: (_, state) => RegisterDetailsScreen(role: state.extra as UserRole),
        ),

        // Patient routes
        ShellRoute(
          builder: (_, __, child) => PatientShell(child: child),
          routes: [
            GoRoute(path: '/patient/home', builder: (_, __) => const PatientDashboardScreen()),
            GoRoute(path: '/patient/appointments', builder: (_, __) => const PatientAppointmentsScreen()),
            GoRoute(path: '/patient/messages', builder: (_, __) => const PatientMessagesScreen()),
            GoRoute(path: '/patient/profile', builder: (_, __) => const PatientProfileScreen()),
          ],
        ),
        GoRoute(path: '/patient/symptom-check', builder: (_, __) => const SymptomCheckerScreen()),
        GoRoute(path: '/patient/doctors', builder: (_, __) => const DoctorListScreen()),
        GoRoute(
          path: '/patient/doctors/:id',
          builder: (_, state) => DoctorProfileScreen(doctorId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/patient/book/:doctorId',
          builder: (_, state) => BookAppointmentScreen(doctorId: state.pathParameters['doctorId']!),
        ),
        GoRoute(
          path: '/patient/book/confirm',
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>;
            return BookingConfirmScreen(
              doctorId: extra['doctorId'] as String,
              slot: extra['slot'] as TimeSlot,
              type: extra['type'] as AppointmentType,
            );
          },
        ),
        GoRoute(
          path: '/patient/appointments/:id',
          builder: (_, state) => AppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/patient/messages/:id',
          builder: (_, state) => ChatThreadScreen(conversationId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/patient/call/:id',
          builder: (_, state) => VideoCallScreen(appointmentId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/patient/records', builder: (_, __) => const MedicalRecordsScreen()),
        GoRoute(
          path: '/patient/records/:id',
          builder: (_, state) => RecordDetailScreen(recordId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/patient/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(
          path: '/patient/feedback/:id',
          builder: (_, state) => FeedbackScreen(appointmentId: state.pathParameters['id']!),
        ),

        // Doctor routes
        ShellRoute(
          builder: (_, __, child) => DoctorShell(child: child),
          routes: [
            GoRoute(path: '/doctor/home', builder: (_, __) => const DoctorDashboardScreen()),
            GoRoute(path: '/doctor/messages', builder: (_, __) => const DoctorMessagesScreen()),
            GoRoute(path: '/doctor/patients', builder: (_, __) => const DoctorPatientsScreen()),
            GoRoute(path: '/doctor/profile', builder: (_, __) => const DoctorAccountScreen()),
          ],
        ),
        GoRoute(
          path: '/doctor/appointments/:id',
          builder: (_, state) => DoctorAppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/doctor/availability', builder: (_, __) => const ManageAvailabilityScreen()),
        GoRoute(
          path: '/doctor/consult/:id',
          builder: (_, state) => ConsultationRoomScreen(appointmentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/doctor/messages/:id',
          builder: (_, state) => DoctorChatThreadScreen(conversationId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/doctor/patients/:id',
          builder: (_, state) => PatientHistoryScreen(patientId: state.pathParameters['id']!),
        ),

        // Admin routes
        ShellRoute(
          builder: (_, __, child) => AdminShell(child: child),
          routes: [
            GoRoute(path: '/admin/home', builder: (_, __) => const AdminDashboardScreen()),
            GoRoute(path: '/admin/doctors', builder: (_, __) => const AdminDoctorsScreen()),
            GoRoute(path: '/admin/reports', builder: (_, __) => const AdminReportsScreen()),
          ],
        ),
      ],
    );
  }
}
