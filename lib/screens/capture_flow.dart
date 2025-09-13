import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/screen_capture_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _frames = ScreenCaptureService.frameCount;
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
        title: const Text('Screen Capture'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
          ),
        ),
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
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.8),
            Colors.purple.shade900.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Lens Screen Capture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Capture MetaTrader/TradingView screen for real-time AI analysis.',
                  style: TextStyle(
                    fontSize: 14,
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _permissionGranted ? Icons.verified : Icons.lock,
                color: _permissionGranted ? Colors.green : Colors.orange,
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.cyan),
              SizedBox(width: 8),
              Text('Capture Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        gradient: LinearGradient(
          colors: [
            isCapturing ? Colors.red.shade900 : Colors.green.shade900,
            Colors.blue.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCapturing ? Icons.stop_circle : Icons.play_circle_fill, color: Colors.white),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  color: (isCapturing ? Colors.green : Colors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCapturing ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: isCapturing ? Colors.green : Colors.red,
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
}
