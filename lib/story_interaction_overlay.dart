import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'ha_interaction.dart' as ha;

class StorySceneData {
  const StorySceneData({
    this.shadowAr,
    this.shadowEn,
    required this.statusAr,
    required this.statusEn,
    required this.actionAr,
    required this.actionEn,
    required this.triggerAt,
    this.retryFrom,
    this.shadowAt,
    this.isQte = false,
    this.qteSeconds = 4,
    this.autoAdvanceSeconds,
  });

  final String? shadowAr;
  final String? shadowEn;
  final String statusAr;
  final String statusEn;
  final String actionAr;
  final String actionEn;
  final Duration triggerAt;
  final Duration? retryFrom;
  final Duration? shadowAt;
  final bool isQte;
  final int qteSeconds;
  final int? autoAdvanceSeconds;
}

StorySceneData _storySceneFromCue(
  ha.TimedStoryCue cue, {
  required Duration triggerAt,
  Duration? retryFrom,
  Duration? shadowAt,
  String? shadowAr,
  String? shadowEn,
  String? statusAr,
  String? statusEn,
  String? actionAr,
  String? actionEn,
  int? autoAdvanceSeconds,
}) {
  return StorySceneData(
    shadowAr: shadowAr ?? cue.dialogueAr,
    shadowEn: shadowEn ?? cue.dialogueEn,
    statusAr: statusAr ?? cue.statusAr,
    statusEn: statusEn ?? cue.statusEn,
    actionAr: actionAr ?? cue.actionAr,
    actionEn: actionEn ?? cue.actionEn,
    triggerAt: triggerAt,
    retryFrom: retryFrom,
    shadowAt: shadowAt,
    isQte: cue.isQte,
    qteSeconds: cue.qteSeconds,
    autoAdvanceSeconds: autoAdvanceSeconds,
  );
}

final storyScenes = [
  _storySceneFromCue(
    ha.syncedStoryCues[0],
    triggerAt: const Duration(milliseconds: 9500),
  ),
  _storySceneFromCue(
    ha.syncedStoryCues[1],
    triggerAt: const Duration(seconds: 5),
  ),
  _storySceneFromCue(
    ha.syncedStoryCues[2],
    triggerAt: const Duration(milliseconds: 8500),
    shadowAt: const Duration(milliseconds: 8500),
    autoAdvanceSeconds: 2,
  ),
  _storySceneFromCue(
    ha.syncedStoryCues[3],
    triggerAt: const Duration(seconds: 14),
  ),
  _storySceneFromCue(
    ha.syncedStoryCues[4],
    triggerAt: const Duration(seconds: 28),
  ),
];

final dayTwoStoryScenes = [
  storyScenes[3],
  _storySceneFromCue(
    ha.syncedStoryCues[7],
    triggerAt: const Duration(seconds: 22),
  ),
  storyScenes[4],
];

final dayThreeFloorCollapseScene = _storySceneFromCue(
  ha.syncedStoryCues[5],
  triggerAt: const Duration(milliseconds: 2500),
  retryFrom: Duration.zero,
  statusAr: 'الأرض تنهار تحتك!',
  statusEn: 'The floor is collapsing beneath you!',
);

class InteractiveStoryOverlay extends StatefulWidget {
  const InteractiveStoryOverlay({
    super.key,
    required this.scene,
    required this.showInteraction,
    required this.onActionPressed,
    required this.onQteFailed,
  });

  final StorySceneData scene;
  final bool showInteraction;
  final VoidCallback onActionPressed;
  final VoidCallback onQteFailed;

  @override
  State<InteractiveStoryOverlay> createState() =>
      _InteractiveStoryOverlayState();
}

class _InteractiveStoryOverlayState extends State<InteractiveStoryOverlay> {
  Timer? _qteTimer;
  late int _remainingSeconds;
  bool _didHandleTimeout = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.scene.qteSeconds;
    if (widget.showInteraction) _startQteTimer();
  }

  @override
  void didUpdateWidget(covariant InteractiveStoryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showInteraction != widget.showInteraction ||
        oldWidget.scene != widget.scene) {
      _qteTimer?.cancel();
      _didHandleTimeout = false;
      _remainingSeconds = widget.scene.qteSeconds;
      if (widget.showInteraction) _startQteTimer();
    }
  }

  void _startQteTimer() {
    final autoAdvanceSeconds = widget.scene.autoAdvanceSeconds;
    final countdownSeconds = widget.scene.isQte
        ? widget.scene.qteSeconds
        : autoAdvanceSeconds;
    if (countdownSeconds == null || countdownSeconds <= 0) return;
    _remainingSeconds = countdownSeconds;
    _qteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
        return;
      }

      timer.cancel();
      _remainingSeconds = 0;
      if (_didHandleTimeout || !mounted) return;
      _didHandleTimeout = true;
      if (widget.scene.isQte) {
        widget.onQteFailed();
      } else {
        widget.onActionPressed();
      }
    });
  }

  void _pressAction() {
    _qteTimer?.cancel();
    widget.onActionPressed();
  }

  @override
  void dispose() {
    _qteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showInteraction) return const SizedBox.shrink();

    final scene = widget.scene;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 340,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xE6101715),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (scene.shadowAr != null) ...[
                      Text(
                        scene.shadowAr!,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scene.shadowEn!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      scene.statusAr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      scene.statusEn,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (scene.isQte || scene.autoAdvanceSeconds != null) ...[
                      Text(
                        '$_remainingSeconds',
                        key: const ValueKey('story-qte-countdown'),
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('story-interaction-action'),
                        onPressed: _pressAction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              scene.actionAr,
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              scene.actionEn,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
