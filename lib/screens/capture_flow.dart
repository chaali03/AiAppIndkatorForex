import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/screen_capture_service.dart';
import '../services/overlay_service.dart';
import '../ai/forex_analyzer.dart';

class CaptureFlowScreen extends StatefulWidget {
  const CaptureFlowScreen({super.key});

  @override
  State<CaptureFlowScreen> createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends State<CaptureFlowScreen> {
  bool _permissionGranted = false;
  bool _isStarting = false;
  Timer? _statusTimer;
  int _frames = 0;
  double _targetFps = 10; // informational only for now
  AnalysisResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _frames = ScreenCaptureService.frameCount;
          _latestResult = OverlayService.currentResult;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final overlayStatus = await Permission.systemAlertWindow.status;
    setState(() {
      _permissionGranted = overlayStatus == PermissionStatus.granted;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await ScreenCaptureService.requestPermissions();
    setState(() {
      _permissionGranted = granted;
    });
  }

  Future<void> _startCapture() async {
    setState(() {
      _isStarting = true;
    });
    await ScreenCaptureService.startCapture((_) {});
    if (mounted) {
      setState(() {
        _isStarting = false;
      });
    }
  }

  void _stopCapture() {
    ScreenCaptureService.stopCapture();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isCapturing = ScreenCaptureService.isCapturing;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        elevation: 0,
        title: const Text('AI Lens Capture', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Container(
        color: const Color(0xFF0B1220),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 16),
                _buildPermissionCard(),
                const SizedBox(height: 16),
                _buildSettingsCard(),
                const SizedBox(height: 16),
                _buildControlCard(isCapturing),
                const SizedBox(height: 16),
                _buildStatusCard(isCapturing),
                const SizedBox(height: 16),
                _buildSignalCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2638),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8AB4FF), size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Lens Screen Capture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Capture MetaTrader/TradingView screen for real-time AI analysis.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _permissionGranted ? Icons.verified : Icons.lock,
                color: _permissionGranted ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              Text(
                _permissionGranted ? 'Permission Granted' : 'Permission Required',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _permissionGranted
                ? 'Overlay permission is active. You can start capturing the screen.'
                : 'This app needs overlay permission to draw on top of other apps. Tap the button below to grant.',
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 12),
          if (!_permissionGranted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.security),
                label: const Text('Grant Permission'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: Color(0xFF8AB4FF)),
              SizedBox(width: 8),
              Text('Capture Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Target FPS',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              Text('${_targetFps.toInt()} FPS', style: const TextStyle(color: Colors.white)),
            ],
          ),
          Slider(
            value: _targetFps,
            min: 5,
            max: 30,
            divisions: 5,
            label: '${_targetFps.toInt()} FPS',
            onChanged: (v) => setState(() => _targetFps = v),
          ),
          const SizedBox(height: 4),
          Text(
            'Higher FPS gives smoother analysis but may use more battery.',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
          )
        ],
      ),
    );
  }

  Widget _buildControlCard(bool isCapturing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCapturing ? Icons.stop_circle : Icons.play_circle_fill, color: isCapturing ? const Color(0xFFFF6B6B) : const Color(0xFF34D399)),
              const SizedBox(width: 8),
              Text(
                isCapturing ? 'Capture Running' : 'Ready to Start',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !_permissionGranted
                      ? null
                      : (isCapturing
                          ? _stopCapture
                          : _isStarting
                              ? null
                              : _startCapture),
                  icon: Icon(isCapturing ? Icons.stop : Icons.play_arrow),
                  label: Text(isCapturing ? 'Stop Capture' : (_isStarting ? 'Starting...' : 'Start Capture')),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isCapturing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFFFBBF24)),
              SizedBox(width: 8),
              Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Capturing', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isCapturing ? const Color(0xFF34D399) : const Color(0xFFFF6B6B)).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCapturing ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: isCapturing ? const Color(0xFF34D399) : const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Frames analyzed', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              Text('$_frames', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard() {
    final result = _latestResult;
    final hasResult = result != null;

    final Color accent = hasResult ? result!.signalColor : const Color(0xFF8AB4FF);
    final String title = hasResult ? 'AI Signal: ${result!.signalUpperCase}' : 'AI Signal';
    final int confidence = hasResult ? result!.confidencePercent : 0;
    final String pattern = hasResult ? result!.pattern : 'Waiting for analysis...';
    final String reason = hasResult ? result!.reason : 'Start capture to receive live signals.';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: hasResult ? 1 : 0.85,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: Icon(
                    hasResult
                        ? (result!.signal.toLowerCase().contains('buy')
                            ? Icons.trending_up
                            : result!.signal.toLowerCase().contains('sell')
                                ? Icons.trending_down
                                : Icons.pause_circle_filled)
                        : Icons.auto_awesome,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (confidence / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Confidence', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          Text('$confidence%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Pattern', pattern, accent),
                if (hasResult)
                  _chip(
                    'Time',
                    _formatTime(result!.timestamp),
                    accent.withOpacity(0.9),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.3),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
