import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

  @override
  void initState() {
    super.initState();
    unawaited(_playVideo(widget.corridorCollapseIndex ?? 0));
  }

  Future<void> _playVideo(int index) async {
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
      nextController.addListener(_checkProgress);

      final previousController = _controller;
      _controller = nextController;
      _currentIndex = index;
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
      unawaited(_playVideo(nextIndex));
    }
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
      child: AnimatedSwitcher(
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
    );
  }
}
