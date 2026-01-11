import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class ViewTrackerService {
  static final ViewTrackerService _instance = ViewTrackerService._internal();
  static ViewTrackerService get instance => _instance;

  ViewTrackerService._internal();

  final Set<String> _pendingIds = {};
  Timer? _flushTimer;
  static const int _batchThreshold = 20;
  static const Duration _flushInterval = Duration(seconds: 15);

  /// Track a view for a confession ID (Impression)
  void trackView(String confessionId) {
    if (_pendingIds.contains(confessionId)) return; // Already pending

    _pendingIds.add(confessionId);

    // If threshold reached, flush immediately
    if (_pendingIds.length >= _batchThreshold) {
      _flush();
    } else {
      // Otherwise ensure timer is running
      _startTimer();
    }
  }

  void _startTimer() {
    if (_flushTimer != null && _flushTimer!.isActive) return;

    _flushTimer = Timer(_flushInterval, () {
      _flush();
    });
  }

  Future<void> _flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_pendingIds.isEmpty) return;

    // Take snapshot of IDs to process
    final idsToProcess = _pendingIds.toList();
    _pendingIds.clear(); // Clear local buffer immediately to accept new ones

    try {
      debugPrint('👀 ViewTracker: Flushing ${idsToProcess.length} views to server...');
      
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      await functions.httpsCallable('incrementViewCountsBatch').call({
        'confessionIds': idsToProcess,
      });
      
      debugPrint('✅ ViewTracker: Successfully flushed ${idsToProcess.length} views.');
    } catch (e) {
      debugPrint('❌ ViewTracker: Error flushing views: $e');
      // Ideally we might want to retry, but for view counts, dropping is acceptable 
      // to avoid infinite loops or memory leaks on bad connection.
      // Re-adding them might cause duplicates if partially succeeded silently.
    }
  }

  /// Force flush manually (e.g. on app pause)
  void forceFlush() {
    _flush();
  }
}
