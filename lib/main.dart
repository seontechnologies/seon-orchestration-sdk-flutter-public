import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seon_orchestration_flutter/seon_orchestration_flutter.dart';

// ─── Regional base URLs (aligned with seon-orchestration-sdk-react-native-public) ─
const Map<SeonRegion, String> kBaseUrls = {
  SeonRegion.eu: 'https://api.seon.io/orchestration-api/',
  SeonRegion.us: 'https://api.us-east-1-main.seon.io/orchestration-api/',
  SeonRegion.apac: 'https://api.ap-southeast-1-main.seon.io/orchestration-api/',
};

enum SeonRegion { eu, us, apac }

enum _AppPhase { idle, initializing, verifying, done }

class SeonStatusMeta {
  final String label;
  final Color color;
  final String icon;

  const SeonStatusMeta({required this.label, required this.color, required this.icon});
}

const Map<SeonVerificationStatus, SeonStatusMeta> kStatusMeta = {
  SeonVerificationStatus.completedSuccess: SeonStatusMeta(
    label: 'Verification Passed',
    color: Color(0xFF22C55E),
    icon: '✓',
  ),
  SeonVerificationStatus.completedPending: SeonStatusMeta(
    label: 'Pending Manual Review',
    color: Color(0xFFF59E0B),
    icon: '⏳',
  ),
  SeonVerificationStatus.completedFailed: SeonStatusMeta(
    label: 'Verification Failed',
    color: Color(0xFFEF4444),
    icon: '✗',
  ),
  SeonVerificationStatus.completed: SeonStatusMeta(
    label: 'Verification Completed',
    color: Color(0xFF3B82F6),
    icon: '✓',
  ),
  SeonVerificationStatus.interruptedByUser: SeonStatusMeta(
    label: 'Cancelled by User',
    color: Color(0xFF6B7280),
    icon: '↩',
  ),
  SeonVerificationStatus.missingLocationPermission: SeonStatusMeta(
    label: 'Location Permission Required',
    color: Color(0xFFF97316),
    icon: '📍',
  ),
  SeonVerificationStatus.error: SeonStatusMeta(
    label: 'Error Occurred',
    color: Color(0xFFDC2626),
    icon: '!',
  ),
};

// ─── Design tokens (aligned with RN sample) ─────────────────────────────────────
abstract final class _C {
  static const primary = Color(0xFF1E40AF);
  static const background = Color(0xFFF1F5F9);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F172A);
  static const subtext = Color(0xFF64748B);
  static const placeholder = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const neutral = Color(0xFFCBD5E1);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeonExampleApp());
}

class SeonExampleApp extends StatelessWidget {
  const SeonExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEON-Orch-Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _C.primary),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SeonRegion _region = SeonRegion.eu;
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _languageController = TextEditingController(text: 'en');

  _AppPhase _phase = _AppPhase.idle;
  String _statusMessage = 'Enter your token to begin';
  SeonVerificationResult? _result;
  DateTime? _resultAt;

  bool get _isBusy => _phase == _AppPhase.initializing || _phase == _AppPhase.verifying;

  @override
  void dispose() {
    _tokenController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String title, String body) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  String _mapInitError(SeonException e) {
    switch (e.code) {
      case SeonErrorCode.eNotInitialized:
        return 'SDK not initialized. Please try again.';
      case SeonErrorCode.eInitializationFailed:
        return 'Initialization failed. Check your token and base URL.';
      case SeonErrorCode.eVerificationInProgress:
        return 'A verification is already in progress.';
      default:
        return e.message;
    }
  }

  Future<void> _runVerification() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      await _showAlert('Token Required', 'Please enter your session token to proceed.');
      return;
    }

    setState(() {
      _phase = _AppPhase.initializing;
      _statusMessage = 'Initializing SDK…';
      _result = null;
      _resultAt = null;
    });

    final baseUrl = kBaseUrls[_region]!;
    final lang = _languageController.text.trim();
    final language = lang.isEmpty ? 'en' : lang;

    try {
      await SeonOrchestration.initialize(
        SeonConfig(
          baseUrl: baseUrl,
          token: token,
          language: language,
        ),
      );

      if (!mounted) return;
      setState(() {
        _phase = _AppPhase.verifying;
        _statusMessage = 'Launching verification flow…';
      });

      final result = await SeonOrchestration.startVerification();

      if (!mounted) return;
      setState(() {
        _phase = _AppPhase.done;
        _result = result;
        _resultAt = DateTime.now();
        _statusMessage = kStatusMeta[result.status]?.label ?? result.status.name;
      });

      final s = result.status;
      if (s == SeonVerificationStatus.completedSuccess) {
        await _showAlert('Identity Verified', 'Your identity has been successfully verified.');
      } else if (s == SeonVerificationStatus.completedPending) {
        await _showAlert(
          'Under Review',
          'Your submission is under review. You will be notified once a decision is made.',
        );
      } else if (s == SeonVerificationStatus.completedFailed) {
        await _showAlert(
          'Verification Failed',
          'We could not verify your identity. Please try again or contact support.',
        );
      } else if (s == SeonVerificationStatus.interruptedByUser) {
        setState(() {
          _phase = _AppPhase.idle;
          _statusMessage = 'Verification cancelled. Tap below to try again.';
          _result = null;
          _resultAt = null;
        });
      } else if (s == SeonVerificationStatus.missingLocationPermission) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Location Required'),
              content: const Text(
                'Location access is required for fraud prevention. Please enable it in your device settings.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    AppSettings.openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      } else if (s == SeonVerificationStatus.error) {
        await _showAlert('Error', result.errorMessage ?? 'An unexpected error occurred.');
      }
    } on SeonException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _AppPhase.idle;
        _statusMessage = 'Failed. Check your configuration and try again.';
      });
      await _showAlert('Error', _mapInitError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _AppPhase.idle;
        _statusMessage = 'Failed. Check your configuration and try again.';
      });
      await _showAlert('Error', e.toString());
    }
  }

  void _reset() {
    setState(() {
      _phase = _AppPhase.idle;
      _result = null;
      _resultAt = null;
      _statusMessage = 'Enter your token to begin';
    });
  }

  String _platformLine() {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      TargetPlatform.fuchsia => 'Fuchsia',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
    };
  }

  @override
  Widget build(BuildContext context) {
    final meta = _result != null ? kStatusMeta[_result!.status] : null;

    return Scaffold(
      backgroundColor: _C.primary,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ColoredBox(
                color: _C.background,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _ConfigurationCard(
                      region: _region,
                      onRegion: _isBusy
                          ? null
                          : (r) => setState(() => _region = r),
                      baseUrlHint: kBaseUrls[_region]!,
                      tokenController: _tokenController,
                      languageController: _languageController,
                      inputsEnabled: !_isBusy,
                    ),
                    const SizedBox(height: 14),
                    _StatusCard(
                      isBusy: _isBusy,
                      statusMessage: _statusMessage,
                      metaColor: meta?.color,
                    ),
                    if (_result != null && meta != null && _resultAt != null) ...[
                      const SizedBox(height: 14),
                      _ResultCard(
                        meta: meta,
                        result: _result!,
                        at: _resultAt!,
                        platformLine: _platformLine(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const _InfoBanner(),
                  ],
                ),
              ),
            ),
            _Footer(
              isBusy: _isBusy,
              initializing: _phase == _AppPhase.initializing,
              onStart: _runVerification,
              showReset: _phase == _AppPhase.done && _result != null,
              onReset: _reset,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/branding/seon_app_icon.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEON Orchestration SDK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Flutter SDK Example',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  final SeonRegion region;
  final void Function(SeonRegion)? onRegion;
  final String baseUrlHint;
  final TextEditingController tokenController;
  final TextEditingController languageController;
  final bool inputsEnabled;

  const _ConfigurationCard({
    required this.region,
    required this.onRegion,
    required this.baseUrlHint,
    required this.tokenController,
    required this.languageController,
    required this.inputsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
          const SizedBox(height: 16),
          const Text('Region', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SeonRegion.values.map((r) {
              final selected = region == r;
              final label = r.name.toUpperCase();
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: onRegion == null ? null : (_) => onRegion!(r),
                selectedColor: _C.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _C.subtext,
                ),
                side: BorderSide(color: selected ? _C.primary : _C.border, width: 1.5),
                backgroundColor: _C.background,
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(baseUrlHint, style: const TextStyle(fontSize: 11, color: _C.subtext, height: 1.45)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text('Session Token ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.text)),
              Text('*', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: tokenController,
            enabled: inputsEnabled,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            decoration: _inputDecoration('Paste your workflow token here'),
          ),
          const SizedBox(height: 5),
          const Text(
            'Obtain this token from your backend after authenticating the user\'s session.',
            style: TextStyle(fontSize: 11, color: _C.subtext, height: 1.45),
          ),
          const SizedBox(height: 16),
          const Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.text)),
          const SizedBox(height: 8),
          TextField(
            controller: languageController,
            enabled: inputsEnabled,
            maxLength: 5,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            decoration: _inputDecoration('en'),
          ),
          const SizedBox(height: 5),
          const Text(
            'ISO 639-1 code (e.g. en, de, fr). Defaults to device locale if empty.',
            style: TextStyle(fontSize: 11, color: _C.subtext, height: 1.45),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.placeholder),
      filled: true,
      fillColor: _C.background,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _C.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _C.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _C.primary, width: 1.5),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isBusy;
  final String statusMessage;
  final Color? metaColor;

  const _StatusCard({
    required this.isBusy,
    required this.statusMessage,
    required this.metaColor,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isBusy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: metaColor ?? _C.neutral,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusMessage,
                  style: const TextStyle(fontSize: 14, color: _C.text, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SeonStatusMeta meta;
  final SeonVerificationResult result;
  final DateTime at;
  final String platformLine;

  const _ResultCard({
    required this.meta,
    required this.result,
    required this.at,
    required this.platformLine,
  });

  @override
  Widget build(BuildContext context) {
    final t = TimeOfDay.fromDateTime(at).format(context);
    return _Card(
      leftAccent: meta.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(meta.icon, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
                    const SizedBox(height: 2),
                    Text(t, style: const TextStyle(fontSize: 12, color: _C.subtext)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _resultRow('Status', result.status.name),
          _resultRow('Platform', platformLine),
          if (result.errorMessage != null) _resultRow('Error', result.errorMessage!, valueColor: const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  static Widget _resultRow(String key, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(key, style: const TextStyle(fontSize: 12, color: _C.subtext, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: valueColor ?? _C.text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before you start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.primary)),
          SizedBox(height: 8),
          Text(
            '• Use a real physical device — the SDK detects simulators/emulators.\n'
            '• Grant camera, microphone, and location permissions when prompted.\n'
            '• Have a valid government-issued photo ID ready.\n'
            '• Ensure a stable internet connection before starting.',
            style: TextStyle(fontSize: 12, color: _C.primary, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isBusy;
  final bool initializing;
  final VoidCallback onStart;
  final bool showReset;
  final VoidCallback onReset;

  const _Footer({
    required this.isBusy,
    required this.initializing,
    required this.onStart,
    required this.showReset,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: _C.background,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: isBusy ? null : onStart,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: isBusy ? _C.subtext : _C.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: isBusy ? 0 : 6,
              shadowColor: _C.primary.withValues(alpha: 0.35),
            ),
            child: isBusy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(initializing ? 'Initializing…' : 'Verifying…', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  )
                : const Text('Start Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          if (showReset) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: _C.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Reset', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.subtext)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? leftAccent;

  const _Card({required this.child, this.leftAccent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: leftAccent != null ? Border(left: BorderSide(color: leftAccent!, width: 4)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
