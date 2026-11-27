import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

class DayFourInteractionOverlay extends StatefulWidget {
  final ValueListenable<Duration> position;
  final Duration totalDuration;
  final bool isPlaying;
  final VoidCallback onTogglePlayback;
  final ValueChanged<Duration> onSeek;

  const DayFourInteractionOverlay({
    super.key,
    required this.position,
    required this.totalDuration,
    required this.isPlaying,
    required this.onTogglePlayback,
    required this.onSeek,
  });

  @override
  State<DayFourInteractionOverlay> createState() =>
      _DayFourInteractionOverlayState();
}

class _DayFourInteractionOverlayState extends State<DayFourInteractionOverlay>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF070908);
  static const Color _cardDark = Color(0xFF101512);
  static const Color _neonGreen = Color(0xFF00FF66);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;

  String? _lastFeedbackToast;
  String? _loopingChoiceWindow;
  final Set<String> _visitedPassages = {};
  final Set<String> _dismissedChoiceWindows = {};

  // 4 تدميرات أخيرة في سلسلة الانهيارات قبل لحظة الجلوس
  static const List<String> _finalFourDestructionKeys = [
    'final_destruction_1', // ~00:17
    'final_destruction_2', // ~00:18 - 00:19
    'final_destruction_3', // ~00:20 - 00:21
    'final_destruction_4', // ~00:22 - 00:23
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..repeat(reverse: true);

    _pulseOpacity = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// شريط التنبيه النابض (بينور ويطفي) مقتصر على الـ 4 تدميرات الأخيرة فقط
  ({bool visible, String text}) _resolveFinalFourDestructionPulse(int sec) {
    if (sec == 17) {
      return (visible: true, text: 'انهيار 1/4 • ممرات لم تزرها بعد');
    }
    if (sec >= 18 && sec <= 19) {
      return (visible: true, text: 'انهيار 2/4 • ممرات لم تزرها بعد');
    }
    if (sec >= 20 && sec <= 21) {
      return (visible: true, text: 'انهيار 3/4 • ممرات لم تزرها بعد');
    }
    if (sec >= 22 && sec <= 23) {
      return (visible: true, text: 'انهيار 4/4 • ممرات لم تزرها بعد');
    }
    return (visible: false, text: '');
  }

  String? _resolveQuietWhisper(int sec) {
    if (sec >= 13 && sec <= 16) {
      return 'التقط أنفاسك... هناك ممرات لم تزرها بعد';
    }
    if (sec >= 41 && sec <= 48) {
      return 'التقط أنفاسك... هناك ممرات لم تزرها بعد';
    }
    if (sec >= 98 && sec <= 107) {
      return 'طريق مضاء... وبعض الممرات ما زالت بانتظار عودتك';
    }
    return null;
  }

  ({
    String windowKey,
    String question,
    Duration loopAt,
    List<SceneChoiceOption> options,
  })?
  _resolveActiveChoices(int sec) {
    if (sec >= 8 && !_dismissedChoiceWindows.contains('win_mirror_8_10')) {
      return (
        windowKey: 'win_mirror_8_10',
        question:
            'تحطمت المرآة وظهر ما كان يختبئ خلفك... هل الوحش يطاردك أم يكشف سراً دفيناً؟',
        loopAt: const Duration(seconds: 10),
        options: const [
          SceneChoiceOption(
            id: 'mirror_confront',
            label: 'مواجهة ما ظهر خلف المرآة ورفض الاستسلام',
            icon: Icons.shield_outlined,
          ),
          SceneChoiceOption(
            id: 'mirror_retreat',
            label: 'التراجع والبحث عن ممر آخر',
            icon: Icons.alt_route,
          ),
        ],
      );
    }

    if (sec >= 17 &&
        !_dismissedChoiceWindows.contains('win_destructions_17_23')) {
      return (
        windowKey: 'win_destructions_17_23',
        question:
            'أربعة ممرات لم تزرها بعد تنهار أمامك... ما الذي ينتظرك لو عدت إليها؟',
        loopAt: const Duration(seconds: 23),
        options: const [
          SceneChoiceOption(
            id: 'mark_explore_next',
            label: 'تثبيت إشارة للعودة واستكشاف الممرات الأربعة',
            icon: Icons.explore_outlined,
            passageKeyToMarkVisited: 'passage_collapse_26',
          ),
          SceneChoiceOption(
            id: 'stay_mirror_path',
            label: 'الاستمرار في ممر المرآة رغم الانهيارات',
            icon: Icons.alt_route,
            passageKeyToMarkVisited: 'passage_collapse_30',
          ),
        ],
      );
    }

    if (sec >= 52 && !_dismissedChoiceWindows.contains('win_52_59')) {
      return (
        windowKey: 'win_52_59',
        question: 'الظل يقترب من الضوء... كيف ستواجه اللحظة؟',
        loopAt: const Duration(seconds: 59),
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
    if (totalSec > 0 &&
        sec >= totalSec - 15 &&
        !_dismissedChoiceWindows.contains('win_end')) {
      return (
        windowKey: 'win_end',
        question:
            'وصلت إلى هنا... لكن المتاهة ما زالت تخفي ممرات لم تزرها بعد.',
        loopAt: widget.totalDuration,
        options: const [
          SceneChoiceOption(
            id: 'replay_unvisited',
            label: 'جرّب ممراً لم تزره بعد',
            icon: Icons.replay,
            passageKeyToMarkVisited: 'passage_collapse_34',
            seekToOnSelect: Duration(seconds: 24),
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
      widget.onSeek(option.seekToOnSelect!);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _lastFeedbackToast = null);
    });
  }

  void _loopUnansweredChoice(
    Duration position,
    ({
      String windowKey,
      String question,
      Duration loopAt,
      List<SceneChoiceOption> options,
    })?
    choicePack,
    bool showChoices,
  ) {
    if (choicePack == null || !showChoices) {
      _loopingChoiceWindow = null;
      return;
    }

    if (position < choicePack.loopAt) {
      if (_loopingChoiceWindow == choicePack.windowKey) {
        _loopingChoiceWindow = null;
      }
      return;
    }
    if (_loopingChoiceWindow == choicePack.windowKey) return;

    _loopingChoiceWindow = choicePack.windowKey;
    widget.onSeek(choicePack.loopAt - const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.position,
      builder: (context, position, _) => _buildOverlay(context, position),
    );
  }

  Widget _buildOverlay(BuildContext context, Duration position) {
    final currentSec = position.inSeconds;
    final pulseState = _resolveFinalFourDestructionPulse(currentSec);
    final whisperText = _resolveQuietWhisper(currentSec);
    final choicePack = _resolveActiveChoices(currentSec);
    final showChoices =
        choicePack != null &&
        !_dismissedChoiceWindows.contains(choicePack.windowKey);
    _loopUnansweredChoice(position, choicePack, showChoices);

    final unvisitedCount = _finalFourDestructionKeys
        .where((key) => !_visitedPassages.contains(key))
        .length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                  border: Border.all(color: _neonGreen.withOpacity(0.45)),
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
                onPressed: widget.onTogglePlayback,
                icon: Icon(
                  widget.isPlaying
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
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
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
                      border: Border.all(color: _neonGreen.withOpacity(0.7)),
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

            // 7. بطاقة السؤال والاختيارات في منتصف المشهد
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !showChoices,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: showChoices ? 1.0 : 0.0,
                  child: choicePack == null
                      ? const SizedBox.shrink()
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              key: const ValueKey('day-four-interaction-card'),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _bgDark.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _neonGreen.withOpacity(0.72),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.55),
                                    blurRadius: 18,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    choicePack.question,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: choicePack.options.map((opt) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
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
                                              color: _cardDark,
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              border: Border.all(
                                                color: _neonGreen.withOpacity(
                                                  0.75,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (opt.icon != null) ...[
                                                  Icon(
                                                    opt.icon,
                                                    size: 15,
                                                    color: _neonGreen,
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                Flexible(
                                                  child: Text(
                                                    opt.label,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
