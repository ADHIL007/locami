import 'package:flutter/scheduler.dart';
import 'package:locami/theme/theme_provider.dart';

class PerformanceService {
  PerformanceService._();
  static final PerformanceService instance = PerformanceService._();

  bool _isMonitoring = false;
  int _slowFrameCount = 0;
  final int _slowFrameThreshold = 60; // Approx 1 second of slow frames
  bool _optimized = false;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _slowFrameCount = 0;
    _optimized = false;

    SchedulerBinding.instance.addTimingsCallback((timings) {
      if (!_isMonitoring || _optimized || timings.isEmpty) return;

      // Use the most recent frame timing
      final FrameTiming timing = timings.last;
      
      // Total frame time in milliseconds
      final double totalTime = timing.totalSpan.inMicroseconds / 1000.0;

      // If frame takes more than 16.6ms (60fps threshold)
      if (totalTime > 20.0) {
        _slowFrameCount++;
      } else {
        if (_slowFrameCount > 0) _slowFrameCount--;
      }

      // If we detect consistent lag, drop UI mode
      if (_slowFrameCount > _slowFrameThreshold) {
        _applyOptimization();
      }
    });
  }

  void _applyOptimization() {
    _optimized = true;
    final theme = ThemeProvider.instance;
    
    if (theme.uiMode == 'high') {
      theme.setUiMode('mid');
      _slowFrameCount = 0;
      _optimized = false; // Try monitoring again for 'mid'
    } else if (theme.uiMode == 'mid') {
      theme.setUiMode('low');
      _isMonitoring = false; // Final optimization
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
  }
}
