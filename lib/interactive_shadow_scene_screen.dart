import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SceneChoiceOption {
  final String id;
  final String label;
  final IconData? icon;
  final String? passageKeyToMarkVisited;
  final Duration? seekToOnSelect;

  const SceneChoiceOption({
    required this.id,
    required this.label,
    this.icon,
    this.passageKeyToMarkVisited,
    this.seekToOnSelect,
  });
}

class InteractiveShadowSceneScreen extends StatefulWidget {
  final List<String> assetPaths;
  final List<Duration> assetDurations;

  const InteractiveShadowSceneScreen({
    super.key,
    required this.assetPaths,
    required this.assetDurations,
  });

  Duration get totalDuration =>
      assetDurations.fold(Duration.zero, (sum, duration) => sum + duration);

  @override
  State<InteractiveShadowSceneScreen> createState() =>
      _InteractiveShadowSceneScreenState();
}

class _InteractiveShadowSceneScreenState
    extends State<InteractiveShadowSceneScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF070908);
  static const Color _cardDark = Color(0xFF101512);
  static const Color _neonGreen = Color(0xFF00FF66);

  VideoPlayerController? _videoController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;

  bool _isInitialized = false;
  bool _isAdvancing = false;
  int _currentAssetIndex = 0;
  Duration _elapsedBeforeCurrentVideo = Duration.zero;
  String? _videoError;
  String? _lastFeedbackToast;
  final Set<String> _visitedPassages = {};
  final Set<String> _dismissedChoiceWindows = {};

  // 4 تدميرات أخيرة في سلسلة الانهيارات قبل لحظة الجلوس
  static const List<String> _finalFourDestructionKeys = [
    'final_destruction_1', // ~00:22 - 00:24
    'final_destruction_2', // ~00:25 - 00:27
    'final_destruction_3', // ~00:30 - 00:32
    'final_destruction_4', // ~00:34 - 00:37
  ];

  @override
  void initState() {
    super.initState();
    if (widget.assetPaths.isEmpty ||
        widget.assetPaths.length != widget.assetDurations.length) {
      throw ArgumentError('Video paths and durations must have equal entries.');
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..repeat(reverse: true);

    _pulseOpacity = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    unawaited(_playVideoAt(0));
  }

  Future<void> _playVideoAt(
    int index, {
    Duration position = Duration.zero,
    Duration elapsedBefore = Duration.zero,
  }) async {
    final controller = VideoPlayerController.asset(widget.assetPaths[index]);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (position > Duration.zero) await controller.seekTo(position);
      if (!mounted) {
        await controller.dispose();
        return;
      }

      final previousController = _videoController;
      previousController?.removeListener(_onVideoTick);
      _videoController = controller;
      _currentAssetIndex = index;
      _elapsedBeforeCurrentVideo = elapsedBefore;
      _isInitialized = true;
      _isAdvancing = false;
      _videoError = null;
      controller.addListener(_onVideoTick);
      setState(() {});
      await controller.play();
      await previousController?.dispose();
    } catch (error) {
      debugPrint('Interactive shadow scene video failed: $error');
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _isInitialized = false;
        _isAdvancing = false;
        _videoError = error.toString();
      });
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (!mounted || !_isInitialized || controller == null) return;
    if (controller.value.hasError) {
      setState(() {
        _isInitialized = false;
        _videoError =
            controller.value.errorDescription ?? 'Unknown video error';
      });
      return;
    }
    if (controller.value.isCompleted &&
        !_isAdvancing &&
        _currentAssetIndex < widget.assetPaths.length - 1) {
      _isAdvancing = true;
      unawaited(
        _playVideoAt(
          _currentAssetIndex + 1,
          elapsedBefore: _elapsedBeforeCurrentVideo + controller.value.duration,
        ),
      );
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    final controller = _videoController;
    controller?.removeListener(_onVideoTick);
    unawaited(controller?.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  /// شريط التنبيه النابض (بينور ويطفي) مقتصر على الـ 4 تدميرات الأخيرة فقط
  ({bool visible, String text}) _resolveFinalFourDestructionPulse(int sec) {
    if (sec >= 22 && sec <= 24) {
      return (visible: true, text: 'تدمير 1/4 • ممرات لم تُزار بعد');
    }
    if (sec >= 25 && sec <= 27) {
      return (visible: true, text: 'تدمير 2/4 • ممر لم تطأه قدماك بعد');
    }
    if (sec >= 30 && sec <= 32) {
      return (visible: true, text: 'تدمير 3/4 • ممر جانبي لم تُكتشف بعد');
    }
    if (sec >= 34 && sec <= 37) {
      return (visible: true, text: 'تدمير 4/4 • أطلال ممرات بانتظار زيارتك');
    }
    return (visible: false, text: '');
  }

  String? _resolveQuietWhisper(int sec) {
    if (sec >= 38 && sec <= 49) {
      return 'التقط أنفاسك... هناك ممرات لم تزرها بعد';
    }
    if (sec >= 98 && sec <= 107) {
      return 'طريق مضاء... وبعض الممرات ما زالت بانتظار عودتك';
    }
    return null;
  }

  ({String windowKey, List<SceneChoiceOption> options})? _resolveActiveChoices(
    int sec,
  ) {
    if (sec >= 26 && sec <= 33) {
      return (
        windowKey: 'win_destructions_26_33',
        options: const [
          SceneChoiceOption(
            id: 'visit_unvisited_1',
            label: 'استكشف ممر لم تزره',
            icon: Icons.explore_outlined,
            passageKeyToMarkVisited: 'final_destruction_2',
          ),
          SceneChoiceOption(
            id: 'visit_unvisited_2',
            label: 'تفقّد الممر المنهار',
            icon: Icons.alt_route,
            passageKeyToMarkVisited: 'final_destruction_3',
          ),
        ],
      );
    }

    if (sec >= 52 && sec <= 59) {
      return (
        windowKey: 'win_52_59',
        options: const [
          SceneChoiceOption(
            id: 'reach_light',
            label: 'مدّ يدك نحو النور',
            icon: Icons.wb_sunny_outlined,
          ),
          SceneChoiceOption(
            id: 'watch_shadow',
            label: 'تأمل الظل بهدوء',
            icon: Icons.self_improvement,
          ),
        ],
      );
    }

    final totalSec = widget.totalDuration.inSeconds;
    if (totalSec > 0 && sec >= totalSec - 5) {
      return (
        windowKey: 'win_end',
        options: const [
          SceneChoiceOption(
            id: 'replay_unvisited',
            label: 'جرّب ممراً لم تزره بعد',
            icon: Icons.replay,
            seekToOnSelect: Duration(seconds: 22),
          ),
          SceneChoiceOption(
            id: 'restart_all',
            label: 'إعادة التجربة من البداية',
            icon: Icons.refresh,
            seekToOnSelect: Duration.zero,
          ),
        ],
      );
    }

    return null;
  }

  void _handleChoiceSelected(String windowKey, SceneChoiceOption option) {
    setState(() {
      _dismissedChoiceWindows.add(windowKey);
      if (option.passageKeyToMarkVisited != null) {
        _visitedPassages.add(option.passageKeyToMarkVisited!);
      }
      _lastFeedbackToast = 'اخترت: ${option.label}';
    });

    if (option.seekToOnSelect != null) {
      unawaited(_seekToGlobalPosition(option.seekToOnSelect!));
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _lastFeedbackToast = null);
    });
  }

  Future<void> _seekToGlobalPosition(Duration target) async {
    var elapsed = Duration.zero;
    for (var index = 0; index < widget.assetDurations.length; index++) {
      final segmentDuration = widget.assetDurations[index];
      if (target < elapsed + segmentDuration ||
          index == widget.assetDurations.length - 1) {
        await _playVideoAt(
          index,
          position: target - elapsed,
          elapsedBefore: elapsed,
        );
        return;
      }
      elapsed += segmentDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final currentSec =
        (_elapsedBeforeCurrentVideo +
                (controller?.value.position ?? Duration.zero))
            .inSeconds;
    final pulseState = _resolveFinalFourDestructionPulse(currentSec);
    final whisperText = _resolveQuietWhisper(currentSec);
    final choicePack = _resolveActiveChoices(currentSec);
    final showChoices =
        choicePack != null &&
        !_dismissedChoiceWindows.contains(choicePack.windowKey);

    final unvisitedCount = _finalFourDestructionKeys
        .where((key) => !_visitedPassages.contains(key))
        .length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgDark,
        body: SafeArea(
          child: !_isInitialized || controller == null
              ? Center(
                  child: _videoError == null
                      ? const CircularProgressIndicator(color: _neonGreen)
                      : Text(
                          'تعذر تشغيل فيديو التجربة\n$_videoError',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. الفيديو الرئيسي
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),

                    // 2. عدّاد الممرات غير المزارة الخاصة بالـ 4 تدميرات الأخيرة
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _cardDark.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _neonGreen.withOpacity(0.45),
                          ),
                        ),
                        child: Text(
                          'ممرات لم تُزار بعد: $unvisitedCount / ${_finalFourDestructionKeys.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // 3. زر تشغيل / إيقاف مؤقت
                    Positioned(
                      top: 10,
                      left: 12,
                      child: IconButton(
                        onPressed: () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                        icon: Icon(
                          controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: _neonGreen.withOpacity(0.9),
                          size: 32,
                        ),
                      ),
                    ),

                    // 4. شريط التنبيه النابض (بينور ويطفي) على الـ 4 تدميرات الأخيرة فقط
                    Positioned(
                      top: 62,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: IgnorePointer(
                          ignoring: !pulseState.visible,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: pulseState.visible ? 1.0 : 0.0,
                            child: FadeTransition(
                              opacity: _pulseOpacity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _cardDark.withOpacity(0.94),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _neonGreen.withOpacity(0.85),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _neonGreen.withOpacity(0.32),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.explore_outlined,
                                      size: 16,
                                      color: _neonGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        pulseState.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
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
                    ),

                    // 5. رسالة تشويقية هادئة
                    if (whisperText != null && !pulseState.visible)
                      Positioned(
                        bottom: 105,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _bgDark.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                            child: Text(
                              whisperText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 6. إشعار تأكيد سريع
                    if (_lastFeedbackToast != null)
                      Positioned(
                        bottom: 155,
                        left: 24,
                        right: 24,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _neonGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _neonGreen.withOpacity(0.7),
                              ),
                            ),
                            child: Text(
                              _lastFeedbackToast!,
                              style: const TextStyle(
                                color: _neonGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 7. أزرار التفاعل السريع المتدرجة أسفل الشاشة
                    Positioned(
                      bottom: 26,
                      left: 14,
                      right: 14,
                      child: IgnorePointer(
                        ignoring: !showChoices,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 260),
                          opacity: showChoices ? 1.0 : 0.0,
                          child: choicePack == null
                              ? const SizedBox.shrink()
                              : Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: choicePack.options.map((opt) {
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(22),
                                      onTap: () => _handleChoiceSelected(
                                        choicePack.windowKey,
                                        opt,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _cardDark.withOpacity(0.92),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: _neonGreen.withOpacity(0.65),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (opt.icon != null) ...[
                                              Icon(
                                                opt.icon,
                                                size: 15,
                                                color: _neonGreen,
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              opt.label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
