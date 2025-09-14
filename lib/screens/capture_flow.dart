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
    await Permission.systemAlertWindow.request();
    await _checkPermissions();
  }

  Future<void> _toggleCapture() async {
    if (_isStarting) return;

    setState(() {
      _isStarting = true;
    });

    if (!_permissionGranted) {
      await _requestPermissions();
    }

    if (_permissionGranted) {
      if (ScreenCaptureService.isCapturing) {
        ScreenCaptureService.stopCapture();
        OverlayService.hideOverlay();
      } else {
        ScreenCaptureService.startCapture((imageBytes) {
          // Handle captured image
        });
        OverlayService.showOverlay('ANALYZING');
      }
    }

    setState(() {
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildControlCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 16),
              if (_latestResult != null) _buildSignalCard(_latestResult!),
              const Spacer(),
              _buildCaptureButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BackButton(color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Screen Capture Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Capture your trading screen to analyze patterns and signals in real-time',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoStep(1, 'Press Start Capture to begin screen analysis'),
            const SizedBox(height: 8),
            _buildInfoStep(2, 'Position the floating overlay on your trading chart'),
            const SizedBox(height: 8),
            _buildInfoStep(3, 'AI will analyze patterns and provide signals'),
            const SizedBox(height: 8),
            _buildInfoStep(4, 'Press Stop Capture when finished'),
            const SizedBox(height: 16),
            Text(
              'Higher FPS provides smoother analysis but uses more resources',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capture Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Target FPS: ${_targetFps.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _targetFps,
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.grey[800],
              onChanged: (value) {
                setState(() {
                  _targetFps = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low (1 FPS)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                ),
                Text(
                  'High (30 FPS)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isCapturing = ScreenCaptureService.isCapturing;
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Capture', isCapturing ? 'Active' : 'Inactive',
                isCapturing ? Colors.green : Colors.red),
            const SizedBox(height: 8),
            _buildStatusRow('Frames Captured', '$_frames', Colors.blue),
            const SizedBox(height: 8),
            _buildStatusRow(
                'Permissions',
                _permissionGranted ? 'Granted' : 'Not Granted',
                _permissionGranted ? Colors.green : Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalCard(AnalysisResult result) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildResultRow('Signal', result.signal.toString(),
                _getSignalColor(result.signal)),
            const SizedBox(height: 8),
            _buildResultRow('Confidence', '${(result.confidence * 100).toInt()}%',
                _getConfidenceColor(result.confidence)),
            const SizedBox(height: 8),
            _buildResultRow(
                'Pattern', result.pattern, Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            _buildResultRow('Time', _formatTime(result.timestamp), Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Detected Indicators',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.indicators.entries
                  .map((entry) => _buildIndicatorChip(entry.key))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    final isCapturing = ScreenCaptureService.isCapturing;
    return ElevatedButton(
      onPressed: _isStarting ? null : _toggleCapture,
      style: ElevatedButton.styleFrom(
        backgroundColor: isCapturing ? Colors.red : Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _isStarting
            ? 'Processing...'
            : isCapturing
                ? 'Stop Capture'
                : 'Start Capture',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildIndicatorChip(String indicator) {
    return Chip(
      backgroundColor: Colors.grey[800],
      label: Text(
        indicator,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getSignalColor(String signal) {
    switch (signal.toUpperCase()) {
      case 'BUY':
        return Colors.green;
      case 'SELL':
        return Colors.red;
      case 'HOLD':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.amber;
    return Colors.red;
  }

  // Removed unused _chip method

  String _formatTime(DateTime dt) {
    String two(int n) {
      return n.toString().padLeft(2, '0');
    }
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
