import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/api_client.dart';
import '../../data/member_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/presence_button.dart';
import 'widgets/result_view.dart';
import 'widgets/viewfinder.dart';

enum _View {
  permission,
  denied,
  scanning,
  expired,
  invalid,
  failed,
  duplicate,
  success,
}

/// Native hook that opens this app's page in the OS Settings.
const _settings = MethodChannel('presence/settings');

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.store});

  final MemberStore store;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  /// Remembered for this run only so we do not re-ask on every visit.
  static bool _granted = false;

  late _View _view = _granted ? _View.scanning : _View.permission;
  bool _handled = false;

  /// A code was read and the server has not answered yet.
  bool _checking = false;
  CheckInResult? _result;
  String _failure = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from Settings: try the camera again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _view == _View.denied) {
      _scan();
    }
  }

  void _scan() => setState(() {
    _handled = false;
    _checking = false;
    _view = _View.scanning;
  });

  void _onDetect(BarcodeCapture capture) {
    if (_handled || _view != _View.scanning) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue ?? '')
        .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    _granted = true;
    _resolve(raw);
  }

  /// The server decides. Success shows only after it recorded the visit.
  /// Leaving the scanning view unmounts and stops the camera.
  Future<void> _resolve(String payload) async {
    _handled = true;
    setState(() => _checking = true);
    try {
      final r = await widget.store.checkIn(payload);
      if (!mounted) return;
      setState(() {
        _result = r;
        _view = switch (r.result) {
          CheckIn.checkedIn => _View.success,
          CheckIn.duplicate => _View.duplicate,
          CheckIn.expired => _View.expired,
          CheckIn.invalid => _View.invalid,
        };
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = e.message;
        _view = _View.failed;
      });
    }
  }

  /// Debug only: shows a result screen without the camera or the server.
  void _preview(_View view) => setState(() {
    _handled = true;
    _result = CheckInResult(
      CheckIn.checkedIn,
      DateTime.now(),
      widget.store.currentStreak,
    );
    _view = view;
  });

  Widget _cameraError(BuildContext context, MobileScannerException error) {
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _view == _View.scanning) {
          setState(() => _view = _View.denied);
        }
      });
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PresenceSpace.s24),
        child: Text(
          'Camera unavailable on this device.',
          textAlign: TextAlign.center,
          style: PresenceType.sans(15, color: PresenceColors.mist),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Transform.translate(
                offset: const Offset(-8, 0),
                child: PresenceIconButton(
                  icon: LucideIcons.arrowLeft,
                  tooltip: 'Back to home',
                  onPressed: () => context.go('/home'),
                ),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Scan attendance', style: PresenceType.pageTitle),
                ),
              ),
            ],
          ),
          const SizedBox(height: PresenceSpace.s28),
          Expanded(
            child: Center(child: SingleChildScrollView(child: _body(context))),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final day = DateFormat('EEEE d MMMM');
    final today = day.format(widget.store.today);
    final at = _result?.checkedInAt ?? DateTime.now();
    return switch (_view) {
      _View.permission => _Prompt(
        title: 'Allow camera access',
        body: 'The camera is used only while you scan. Nothing is recorded or stored.',
        actions: [
          PresenceButton(label: 'Allow camera', height: 56, onPressed: _scan),
        ],
      ),
      _View.denied => _Prompt(
        title: 'Camera is off for Presence',
        body: 'Turn it on in Settings to scan the gym code.',
        actions: [
          PresenceButton(
            label: 'Open settings',
            height: 56,
            onPressed: () => _settings.invokeMethod<void>('open'),
          ),
          PresenceButton(
            label: 'Back to home',
            variant: ButtonVariant.secondary,
            height: 56,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      _View.scanning => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PresenceSpace.s28,
        children: [
          Viewfinder(
            child: MobileScanner(
              onDetect: _onDetect,
              errorBuilder: _cameraError,
            ),
          ),
          Column(
            children: [
              Text(
                _checking
                    ? 'Checking the code…'
                    : 'Point at the code on the gym screen.',
                textAlign: TextAlign.center,
                style: PresenceType.bodyMuted,
              ),
              if (kDebugMode)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: PresenceSpace.s20,
                  children: [
                    PresenceButton(
                      label: 'Preview: success',
                      variant: ButtonVariant.text,
                      textStyle: PresenceType.sans(
                        13,
                        color: PresenceColors.muted,
                      ),
                      onPressed: () => _preview(_View.success),
                    ),
                    PresenceButton(
                      label: 'Preview: expired code',
                      variant: ButtonVariant.text,
                      textStyle: PresenceType.sans(
                        13,
                        color: PresenceColors.muted,
                      ),
                      onPressed: () => _preview(_View.expired),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
      _View.expired => ResultView(
        icon: LucideIcons.circleAlert,
        title: 'That code has expired',
        body: 'Scan the code that is on the gym screen right now.',
        action: 'Scan again',
        onAction: _scan,
      ),
      _View.invalid => ResultView(
        icon: LucideIcons.circleAlert,
        title: 'That code is not for your gym',
        body: 'Scan the code that is on the gym screen right now.',
        action: 'Scan again',
        onAction: _scan,
      ),
      _View.failed => ResultView(
        icon: LucideIcons.wifiOff,
        title: 'You are not checked in',
        body: _failure,
        action: 'Scan again',
        onAction: _scan,
      ),
      _View.duplicate => ResultView(
        icon: LucideIcons.check,
        title: 'Already checked in',
        body: 'Your visit for $today is already recorded.',
        action: 'Done',
        onAction: () => context.go('/home'),
      ),
      _View.success => ResultView(
        icon: LucideIcons.check,
        positive: true,
        title: 'You are checked in',
        body: '${day.format(at)} · ${DateFormat('h:mm a').format(at)}',
        action: 'Done',
        onAction: () => context.go('/home'),
        extra: Padding(
          padding: const EdgeInsets.only(top: PresenceSpace.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: PresenceSpace.s8,
            children: [
              const Icon(
                LucideIcons.flame,
                size: 20,
                color: PresenceColors.ink,
              ),
              Text(
                '${_result?.currentStreak ?? 0}-day streak',
                style: PresenceType.sans(15, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: PresenceSpace.s28,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: PresenceColors.ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.camera,
            size: 40,
            color: PresenceColors.teal,
          ),
        ),
        Column(
          spacing: PresenceSpace.s8,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: PresenceType.sans(
                22,
                height: 1.2,
                weight: FontWeight.w600,
              ),
            ),
            Text(
              body,
              textAlign: TextAlign.center,
              style: PresenceType.bodyMuted,
            ),
          ],
        ),
        Column(spacing: PresenceSpace.s12, children: actions),
      ],
    );
  }
}
