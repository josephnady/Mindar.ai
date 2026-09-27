import 'package:flutter/material.dart';
import '../models/event_type.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

/// Popup that captures a voice recording, live-transcribes it via the
/// device's speech recognizer, and returns the final transcript text
/// (or null if the user cancels) for the caller to POST to /api/events.
Future<String?> showVoiceInputDialog(BuildContext context, EventType type) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VoiceInputDialog(type: type),
  );
}

class _VoiceInputDialog extends StatefulWidget {
  final EventType type;
  const _VoiceInputDialog({required this.type});

  @override
  State<_VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<_VoiceInputDialog> {
  final _voice = VoiceService();
  String _transcript = '';
  bool _listening = false;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final granted = await _voice.requestMicPermission();
    if (!granted) {
      setState(() => _error = 'Microphone permission is needed to record a thought.');
      return;
    }
    final ok = await _voice.init();
    setState(() => _ready = ok);
    if (ok) _start();
  }

  Future<void> _start() async {
    setState(() => _listening = true);
    await _voice.startListening(onResult: (text, isFinal) {
      setState(() => _transcript = text);
    });
  }

  Future<void> _stop() async {
    await _voice.stopListening();
    setState(() => _listening = false);
  }

  @override
  void dispose() {
    _voice.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 26, backgroundColor: widget.type.color, child: Icon(widget.type.icon, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Recording a ${widget.type.label.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
            else ...[
              _MicPulse(active: _listening),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _transcript.isEmpty ? 'Listening... say your thought.' : _transcript,
                  style: TextStyle(color: _transcript.isEmpty ? AppColors.subtleGrey : AppColors.navy),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _transcript.trim().isEmpty
                        ? null
                        : () async {
                            if (_listening) await _stop();
                            if (!mounted) return;
                            Navigator.of(context).pop(_transcript.trim());
                          },
                    child: Text(_listening ? 'Stop & save' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MicPulse extends StatelessWidget {
  final bool active;
  const _MicPulse({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent.withOpacity(0.15) : AppColors.subtleGrey.withOpacity(0.1),
      ),
      child: Icon(Icons.mic, color: active ? AppColors.accent : AppColors.subtleGrey, size: 30),
    );
  }
}
