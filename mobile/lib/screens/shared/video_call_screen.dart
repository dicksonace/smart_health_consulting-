import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/user_role.dart';
import '../store/app_store.dart';
import '../theme/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Map<String, dynamic>? _room;
  bool _loading = true;
  bool _ending = false;
  bool _webReady = false;
  bool _webFailed = false;
  bool _controlsVisible = true;
  String? _directionLabel;
  String? _errorText;
  int? _sessionId;
  DateTime? _joinedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _webController = null;
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _ensureMediaPermissions();
    if (!mounted) return;
    await _loadRoom();
  }

  Future<void> _ensureMediaPermissions() async {
    if (kIsWeb) return;
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cam = statuses[Permission.camera];
      final mic = statuses[Permission.microphone];
      if (cam == null || mic == null) return;

      if (cam.isPermanentlyDenied || mic.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable camera and microphone in settings for video calls.'),
          ),
        );
      }
    } catch (_) {
      // Permissions plugin may be unavailable on some desktop targets.
    }
  }

  Future<void> _loadRoom() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _webFailed = false;
      _errorText = null;
    });

    final store = context.read<AppStore>();
    try {
      final data = await store.fetchVideoRoom(widget.appointmentId);
      if (!mounted) return;

      setState(() {
        _room = data;
        _directionLabel = data['direction_label'] as String?;
        _loading = false;
      });

      if (data['can_join'] == true && data['join_url'] != null) {
        final start = await _startSession(store);
        if (!mounted) return;
        if (start != null && start['direction_label'] != null) {
          setState(() {
            _directionLabel = start['direction_label'] as String?;
          });
        }
        _setupWebView(data['join_url'] as String);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  Future<Map<String, dynamic>?> _startSession(AppStore store) async {
    try {
      final result = await store.startVideoCall(widget.appointmentId);
      final session = result['session'];
      if (session is Map) {
        _sessionId = int.tryParse(session['id']?.toString() ?? '');
      }
      _joinedAt = DateTime.now();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _joinedAt == null) return;
        setState(() => _elapsed = DateTime.now().difference(_joinedAt!));
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  void _setupWebView(String joinUrl) {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0B1220))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() {
                _webReady = true;
                _webFailed = false;
              });
            },
            onWebResourceError: (error) {
              if (!mounted) return;
              // Ignore subresource noise; only fail hard if page never becomes ready.
              if (!_webReady) {
                setState(() {
                  _webFailed = true;
                  _errorText = 'Video room failed to load. You can open it in the browser.';
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(joinUrl));

      setState(() {
        _webController = controller;
        _webReady = false;
        _webFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _webFailed = true;
        _errorText = e.toString();
      });
    }
  }

  Future<void> _hangUp() async {
    if (_ending) return;
    _ending = true;
    if (mounted) setState(() {});

    _ticker?.cancel();

    try {
      // Stop media pages safely before popping.
      await _webController?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}

    try {
      if (mounted) {
        await context.read<AppStore>().endVideoCall(
              widget.appointmentId,
              sessionId: _sessionId,
              reason: 'hangup',
            );
      }
    } catch (_) {}

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _openExternal() async {
    final url = _room?['join_url'] as String?;
    if (url == null) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser for the video call.')),
      );
    }
  }

  String get _timerLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = _elapsed.inHours;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final appt = store.appointmentById(widget.appointmentId);
    final canJoin = _room?['can_join'] == true;
    final peerName = _room?['peer_name'] as String? ??
        (store.currentUser?.role == UserRole.doctor
            ? appt?.patientName
            : appt?.doctorName) ??
        'Consultation';
    final me = store.currentUser?.name ?? 'You';
    final direction = _directionLabel ??
        _room?['direction_label'] as String? ??
        '$me → $peerName';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _hangUp();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : (canJoin && _webController != null && !_webFailed)
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => setState(() => _controlsVisible = !_controlsVisible),
                            child: WebViewWidget(controller: _webController!),
                          ),
                        ),
                        if (!_webReady)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0xCC0B1220),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 16),
                                    Text(
                                      'Connecting secure video room…',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_controlsVisible) ...[
                          _TopBar(
                            peerName: peerName,
                            directionLabel: direction,
                            timerLabel: _joinedAt == null ? 'Connecting…' : _timerLabel,
                            onClose: _hangUp,
                            onOpenExternal: _openExternal,
                          ),
                          _BottomControls(
                            ending: _ending,
                            onHangUp: _hangUp,
                            onOpenExternal: _openExternal,
                          ),
                        ],
                      ],
                    )
                  : _WaitingState(
                      room: _room,
                      peerName: peerName,
                      directionLabel: direction,
                      errorText: _errorText,
                      webFailed: _webFailed,
                      onBack: () => context.pop(),
                      onRetry: _loadRoom,
                      onOpenExternal: _openExternal,
                    ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.peerName,
    required this.directionLabel,
    required this.timerLabel,
    required this.onClose,
    required this.onOpenExternal,
  });

  final String peerName;
  final String directionLabel;
  final String timerLabel;
  final VoidCallback onClose;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    directionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                  ),
                  Text(
                    timerLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpenExternal,
              icon: const Icon(Icons.open_in_new, color: Colors.white70),
              tooltip: 'Open in browser',
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.ending,
    required this.onHangUp,
    required this.onOpenExternal,
  });

  final bool ending;
  final VoidCallback onHangUp;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Column(
        children: [
          const Text(
            'Use mute / camera buttons inside the video room',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundControl(
                icon: Icons.open_in_browser,
                label: 'Browser',
                onTap: onOpenExternal,
              ),
              const SizedBox(width: 22),
              _RoundControl(
                icon: ending ? Icons.hourglass_top : Icons.call_end,
                label: 'End call',
                danger: true,
                onTap: ending ? null : onHangUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? const Color(0xFFE11D48) : Colors.white.withValues(alpha: 0.14);

    return Column(
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({
    required this.room,
    required this.peerName,
    required this.directionLabel,
    required this.errorText,
    required this.webFailed,
    required this.onBack,
    required this.onRetry,
    required this.onOpenExternal,
  });

  final Map<String, dynamic>? room;
  final String peerName;
  final String directionLabel;
  final String? errorText;
  final bool webFailed;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final opensAt = room?['opens_at'] as String?;
    DateTime? opens;
    if (opensAt != null) {
      opens = DateTime.tryParse(opensAt)?.toLocal();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              webFailed ? Icons.error_outline : Icons.videocam_off,
              size: 44,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            webFailed ? 'Could not start in-app video' : 'Waiting for video with $peerName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            directionLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF93C5FD)),
          ),
          const SizedBox(height: 10),
          Text(
            webFailed
                ? (errorText ?? 'Open the call in your browser instead.')
                : 'The call room opens 1 hour before the appointment and stays open for 2 hours after.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (opens != null && !webFailed) ...[
            const SizedBox(height: 16),
            Text(
              'Opens ${DateFormat('EEE, MMM d · h:mm a').format(opens)}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onOpenExternal,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Open in browser'),
          ),
          TextButton(
            onPressed: onBack,
            child: const Text('Go back', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
