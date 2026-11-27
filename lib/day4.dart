import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'day_four_interaction_overlay.dart';
import 'story_transition_placeholder.dart';

const dayFourVideoPaths = [
  'assets/videos/day4/day4_01.mp4',
  'assets/videos/day4/day4_02.mp4',
  'assets/videos/day4/day4_03.mp4',
  'assets/videos/day4/day4_04.mp4',
  'assets/videos/day4/day4_05_basement_collapse.mp4',
  'assets/videos/day4/day4_06_shadow_on_stairs.mp4',
  'assets/videos/day4/day4_07_light_from_guide.mp4',
  'assets/videos/day4/day4_08_exit_with_guide.mp4',
  'assets/videos/day4/day4_09_the_end.mp4',
];

const dayFourSharedStoryStartIndex = 4;

const dayFourVideoDurations = [
  Duration(milliseconds: 8847),
  Duration(milliseconds: 8940),
  Duration(milliseconds: 15325),
  Duration(milliseconds: 12539),
  Duration(milliseconds: 16720),
  Duration(milliseconds: 19923),
  Duration(milliseconds: 10027),
  Duration(milliseconds: 30000),
  Duration(milliseconds: 33739),
];

int? dayFourNextVideoIndex(int currentIndex, {int? corridorCollapseIndex}) {
  if (currentIndex == dayFourVideoPaths.length - 1) return null;
  if (corridorCollapseIndex != null) {
    if (currentIndex < dayFourSharedStoryStartIndex) {
      return dayFourSharedStoryStartIndex;
    }
  }
  return currentIndex + 1;
}

class DayFourVideoBackground extends StatefulWidget {
  const DayFourVideoBackground({super.key, this.corridorCollapseIndex});

  final int? corridorCollapseIndex;

  @override
  State<DayFourVideoBackground> createState() => _DayFourVideoBackgroundState();
}

class _DayFourVideoBackgroundState extends State<DayFourVideoBackground> {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  int _activation = 0;
  bool _transitioning = false;
  bool _failed = false;
  String? _failureMessage;
  Duration _elapsedBeforeCurrentVideo = Duration.zero;
  final ValueNotifier<Duration> _storyPosition = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    unawaited(_playVideo(widget.corridorCollapseIndex ?? 0));
  }

  List<int> get _experienceVideoIndices => [
    widget.corridorCollapseIndex ?? 0,
    ...List.generate(
      dayFourVideoPaths.length - dayFourSharedStoryStartIndex,
      (offset) => dayFourSharedStoryStartIndex + offset,
    ),
  ];

  Duration get _experienceDuration => _experienceVideoIndices.fold(
    Duration.zero,
    (total, index) => total + dayFourVideoDurations[index],
  );

  Future<void> _playVideo(
    int index, {
    Duration position = Duration.zero,
    Duration elapsedBefore = Duration.zero,
  }) async {
    final activation = ++_activation;
    _transitioning = true;
    final nextController = VideoPlayerController.asset(
      dayFourVideoPaths[index],
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await nextController.initialize();
      if (!mounted || activation != _activation) {
        await nextController.dispose();
        return;
      }

      await nextController.setLooping(false);
      await nextController.setVolume(1);
      if (position > Duration.zero) await nextController.seekTo(position);
      nextController.addListener(_checkProgress);

      final previousController = _controller;
      _controller = nextController;
      _currentIndex = index;
      _elapsedBeforeCurrentVideo = elapsedBefore;
      _storyPosition.value = elapsedBefore + position;
      _transitioning = false;
      _failed = false;
      _failureMessage = null;
      setState(() {});

      await _disposeController(previousController);
      if (!mounted || activation != _activation) return;
      await nextController.play();
    } catch (error) {
      debugPrint('Day four video failed: $error');
      if (!mounted || activation != _activation) {
        if (!identical(_controller, nextController)) {
          await _disposeController(nextController);
        }
        return;
      }
      final previousController = _controller;
      if (identical(previousController, nextController)) {
        _controller = null;
      }
      _transitioning = true;
      _failed = true;
      _failureMessage = error.toString();
      setState(() {});
      await _disposeController(nextController);
      if (!identical(previousController, nextController)) {
        await _disposeController(previousController);
      }
    }
  }

  void _checkProgress() {
    if (!mounted || _transitioning) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    final storyPosition = _elapsedBeforeCurrentVideo + value.position;
    if (_storyPosition.value != storyPosition) {
      _storyPosition.value = storyPosition;
    }
    if (value.hasError) {
      _transitioning = true;
      _failed = true;
      _failureMessage =
          value.errorDescription ?? 'Unknown video playback error';
      debugPrint('Day four video failed: $_failureMessage');
      setState(() {});
    } else if (value.isCompleted) {
      final nextIndex = dayFourNextVideoIndex(
        _currentIndex,
        corridorCollapseIndex: widget.corridorCollapseIndex,
      );
      if (nextIndex == null) return;
      _transitioning = true;
      unawaited(
        _playVideo(
          nextIndex,
          elapsedBefore: _elapsedBeforeCurrentVideo + value.duration,
        ),
      );
    }
  }

  Future<void> _seekToStoryPosition(Duration target) async {
    var elapsed = Duration.zero;
    for (final index in _experienceVideoIndices) {
      final duration = dayFourVideoDurations[index];
      if (target < elapsed + duration ||
          index == dayFourVideoPaths.length - 1) {
        final position = target - elapsed;
        final controller = _controller;
        if (index == _currentIndex &&
            controller != null &&
            controller.value.isInitialized) {
          _elapsedBeforeCurrentVideo = elapsed;
          await controller.seekTo(position);
          if (!mounted) return;
          _storyPosition.value = elapsed + position;
          if (!controller.value.isPlaying) await controller.play();
          return;
        }

        await _playVideo(index, position: position, elapsedBefore: elapsed);
        return;
      }
      elapsed += duration;
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _disposeController(VideoPlayerController? controller) async {
    if (controller == null) return;
    controller.removeListener(_checkProgress);
    await controller.dispose();
  }

  @override
  void dispose() {
    _activation++;
    unawaited(_disposeController(_controller));
    _storyPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final Widget videoContent;
    final Object videoKey;
    if (_failed) {
      videoContent = StoryTransitionPlaceholder(
        message: 'تعذر تشغيل فيديو اليوم الرابع\n$_failureMessage',
      );
      videoKey = 'error';
    } else if (controller == null || !controller.value.isInitialized) {
      videoContent = const StoryTransitionPlaceholder();
      videoKey = 'loading';
    } else {
      final videoSize = controller.value.size;
      videoContent = Center(
        child: AspectRatio(
          aspectRatio: videoSize.width / videoSize.height,
          child: VideoPlayer(
            controller,
            key: const ValueKey('day-four-video-player'),
          ),
        ),
      );
      videoKey = controller;
    }

    return ColoredBox(
      key: const ValueKey('day-four-video-background'),
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
            child: KeyedSubtree(
              key: ValueKey<Object>(videoKey),
              child: videoContent,
            ),
          ),
          DayFourInteractionOverlay(
            position: _storyPosition,
            totalDuration: _experienceDuration,
            isPlaying: controller?.value.isPlaying ?? false,
            onTogglePlayback: _togglePlayback,
            onSeek: _seekToStoryPosition,
          ),
        ],
      ),
    );
  }
}
