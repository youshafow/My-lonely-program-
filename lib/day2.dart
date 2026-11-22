import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'story_interaction_overlay.dart';
import 'story_transition_placeholder.dart';

const dayTwoShadowForestEndAt = Duration(seconds: 10);

class DayTwoVideoBackground extends StatefulWidget {
  const DayTwoVideoBackground({
    required this.videoPath,
    required this.phase,
    required this.onCheckpoint,
    required this.onWhispersStart,
    required this.onWhispersEnd,
    required this.onComplete,
    required this.scene,
    required this.onStoryAction,
    required this.onInteractionChanged,
    required this.onRestart,
    super.key,
  });

  final String videoPath;
  final int phase;
  final VoidCallback onCheckpoint;
  final VoidCallback onWhispersStart;
  final VoidCallback onWhispersEnd;
  final VoidCallback onComplete;
  final StorySceneData? scene;
  final VoidCallback onStoryAction;
  final ValueChanged<bool> onInteractionChanged;
  final VoidCallback onRestart;

  @override
  State<DayTwoVideoBackground> createState() => _DayTwoVideoBackgroundState();
}

class _DayTwoVideoBackgroundState extends State<DayTwoVideoBackground> {
  late final VideoPlayerController _controller;
  bool _failed = false;
  bool _checkpointSent = false;
  bool _completionSent = false;
  bool _whispersEnded = false;
  bool _waitingForDecision = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      widget.videoPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..addListener(_checkProgress);
    unawaited(_initializeVideo());
  }

  @override
  void didUpdateWidget(covariant DayTwoVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase && _failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCheckpoint();
      });
      return;
    }
    if (oldWidget.phase != widget.phase) {
      _checkpointSent = false;
      _completionSent = false;
      unawaited(_resumePhase());
    }
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setPlaybackSpeed(0.65);
      await _controller.setVolume(widget.phase == 1 ? 0 : 1);
      if (widget.phase == 1) widget.onWhispersStart();
      await _controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Day two video failed: $error');
      _failed = true;
      if (mounted) {
        setState(() {});
        widget.onCheckpoint();
      }
    }
  }

  Future<void> _resumePhase() async {
    try {
      await _controller.setVolume(1);
      await _controller.play();
    } catch (error) {
      debugPrint('Day two video resume failed: $error');
      if (mounted) widget.onCheckpoint();
    }
  }

  void _checkProgress() {
    if (!_controller.value.isInitialized) return;
    final value = _controller.value;
    final scene = widget.scene;
    if (widget.phase == 1 &&
        !_whispersEnded &&
        value.position >= dayTwoShadowForestEndAt) {
      _whispersEnded = true;
      unawaited(_controller.setVolume(1));
      widget.onWhispersEnd();
    }
    if (scene != null &&
        !_checkpointSent &&
        (value.position >= scene.triggerAt || value.isCompleted)) {
      _checkpointSent = true;
      unawaited(_controller.pause());
      setState(() => _waitingForDecision = true);
      widget.onInteractionChanged(true);
      widget.onCheckpoint();
      return;
    }
    if (scene == null && value.isCompleted && !_completionSent) {
      _completionSent = true;
      widget.onComplete();
    }
  }

  void _pressStoryAction() {
    if (!_waitingForDecision) return;
    setState(() => _waitingForDecision = false);
    widget.onInteractionChanged(false);
    widget.onStoryAction();
  }

  Future<void> _restartCurrentScene() async {
    final scene = widget.scene;
    if (scene == null ||
        !_waitingForDecision ||
        !_controller.value.isInitialized) {
      return;
    }
    setState(() => _waitingForDecision = false);
    _checkpointSent = false;
    widget.onInteractionChanged(false);
    widget.onRestart();

    try {
      await _controller.seekTo(
        scene.retryFrom ?? Duration(seconds: (widget.phase - 1) * 10),
      );
      await _controller.play();
    } catch (error) {
      debugPrint('Day two scene restart failed: $error');
      if (!mounted) return;
      setState(() => _failed = true);
      widget.onCheckpoint();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkProgress);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget videoContent;
    if (_failed || !_controller.value.isInitialized) {
      videoContent = StoryTransitionPlaceholder(
        message: _failed ? 'تعذر تشغيل فيديو اليوم الثاني' : null,
      );
    } else {
      final videoSize = _controller.value.size;
      videoContent = ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [...previousChildren, ?currentChild],
            ),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: videoContent,
          ),
          if (widget.scene case final scene?)
            InteractiveStoryOverlay(
              scene: scene,
              showInteraction: _waitingForDecision,
              onActionPressed: _pressStoryAction,
              onQteFailed: _restartCurrentScene,
            ),
        ],
      ),
    );
  }
}
