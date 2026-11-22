import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// نموذج حدث زمني مرتبط بثواني الفيديو
class TimedStoryCue {
  final String id;
  final Duration triggerTime; // الثانية التي يظهر فيها التفاعل ويقف الفيديو
  final Duration? subtitleStart; // بداية ظهور حوار الظل أو الترجمة
  final Duration? subtitleEnd; // نهاية ظهور الحوار
  final String? dialogueAr;
  final String? dialogueEn;
  final String statusAr;
  final String statusEn;
  final String actionAr;
  final String actionEn;
  final bool isQte;
  final int qteSeconds;
  final String? nextVideoUrl; // إذا كان كل مشهد في ملف فيديو منفصل

  const TimedStoryCue({
    required this.id,
    required this.triggerTime,
    this.subtitleStart,
    this.subtitleEnd,
    this.dialogueAr,
    this.dialogueEn,
    required this.statusAr,
    required this.statusEn,
    required this.actionAr,
    required this.actionEn,
    this.isQte = false,
    this.qteSeconds = 3,
    this.nextVideoUrl,
  });
}

/// التوقيتات المظبوطة بالثانية مع الفيديو الخاص بك
final List<TimedStoryCue> syncedStoryCues = [
  // 1. غابة النور (اليوم الأول)
  const TimedStoryCue(
    id: 'scene_1_forest',
    subtitleStart: Duration(seconds: 4),
    subtitleEnd: Duration(seconds: 20),
    dialogueAr:
        'أهلاً بك أيها المسافر.. خذ نفساً عميقاً، أنت في النور.. مؤقتاً.',
    dialogueEn:
        'Welcome, traveler. Take a deep breath. You are in the light... for now.',
    triggerTime: Duration(seconds: 20),
    statusAr: 'الطريق هادئ.. لكن الظلال تتحرك في العمق',
    statusEn: 'The path is quiet... yet shadows stir in the depths',
    actionAr: 'تقدّم بحذر في الغابة 👣',
    actionEn: 'Step carefully into the forest',
  ),

  // 2. سقوط الشجرة في الضباب
  const TimedStoryCue(
    id: 'scene_2_fallen_tree',
    triggerTime: Duration(seconds: 29),
    statusAr: 'شجرة ضخمة تسقط وتقطع طريقك وسط الضباب!',
    statusEn: 'A massive tree falls, blocking your path in the fog!',
    actionAr: 'اعبُر الجذع المكسور ⚡',
    actionEn: 'Climb over the fallen trunk',
  ),

  // 3. بوابة جذور الشجر
  const TimedStoryCue(
    id: 'scene_3_root_arch',
    subtitleStart: Duration(seconds: 54),
    subtitleEnd: Duration(seconds: 76),
    dialogueAr: 'الظل يظهر وسط الدخان ويشير لك نحو الممر.',
    dialogueEn: 'The Shadow emerges from the smoke, pointing toward the arch.',
    triggerTime: Duration(seconds: 76), // 01:16
    statusAr: 'الظل ينتظرك خلف بوابة الجذور',
    statusEn: 'The Shadow awaits beyond the root archway',
    actionAr: 'اعبُر البوابة خلف الظل 🌲',
    actionEn: 'Pass through the archway',
  ),

  // 4. دخول البوابة الحجرية
  const TimedStoryCue(
    id: 'scene_4_stone_gate',
    triggerTime: Duration(seconds: 92), // 01:32
    statusAr: 'الظل يفتح البوابة الحجرية أمامك',
    statusEn: 'The Shadow opens the stone gate ahead of you',
    actionAr: 'ادخل البوابة الحجرية 🚪',
    actionEn: 'Enter the stone gate',
  ),

  // 5. إغلاق الباب الخشبي (نهاية اليوم الأول)
  const TimedStoryCue(
    id: 'scene_5_locked_door',
    triggerTime: Duration(seconds: 108), // 01:48
    statusAr: 'أُغلق الباب من خلفك.. لا طريق للعودة',
    statusEn: 'The door slammed shut behind you... no way back',
    actionAr: 'اليوم التالي: واجه مصيرك 🕯️',
    actionEn: 'Next Day: Face your fate',
  ),

  // 6. انهيار السقف (تفاعل سريع QTE في اليوم الثاني)
  const TimedStoryCue(
    id: 'scene_6_ceiling_qte',
    triggerTime: Duration(seconds: 113), // 01:53 (قبل سقوط الحجارة بثانية)
    statusAr: 'السقف الحجري ينهار فوقك!',
    statusEn: 'The stone ceiling is collapsing above you!',
    actionAr: 'احمِ نفسك فوراً! ⚠️',
    actionEn: 'Brace yourself now!',
    isQte: true,
    qteSeconds: 3,
  ),

  // 7. الاستيقاظ في الظلام والشمعة
  const TimedStoryCue(
    id: 'scene_7_candle',
    subtitleStart: Duration(seconds: 118), // 01:58 ظهور جملة "أين أنا؟"
    subtitleEnd: Duration(seconds: 120),
    dialogueAr: 'أين أنا؟',
    dialogueEn: 'Where am I?',
    triggerTime: Duration(seconds: 120), // 02:00 ظهور زر إشعال الشمعة
    statusAr: 'المكان مظلم تماماً.. وهناك شمعة بجانبك',
    statusEn: 'It is pitch dark... there is a candle beside you',
    actionAr: 'إشعال الشمعة بعود ثقاب 🔥',
    actionEn: 'Light the candle with a match',
  ),

  // 8. صعود الدرج خلف الظل
  const TimedStoryCue(
    id: 'scene_8_shadow_stairs',
    triggerTime: Duration(seconds: 22),
    statusAr: 'الظل يصعد السلم الحجري أمامك',
    statusEn: 'The Shadow climbs the stone stairs ahead of you',
    actionAr: 'اصعد السلم خلف الظل 🪜',
    actionEn: 'Climb the stairs behind the Shadow',
  ),
];

/// ويدجت مشغل القصة المربوط بالتوقيت
class SyncedStoryVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final List<TimedStoryCue> cues;
  final Function(TimedStoryCue cue)?
  onLoadNextClip; // في حال استخدام ملفات منفصلة

  const SyncedStoryVideoPlayer({
    super.key,
    required this.controller,
    required this.cues,
    this.onLoadNextClip,
  });

  @override
  State<SyncedStoryVideoPlayer> createState() => _SyncedStoryVideoPlayerState();
}

class _SyncedStoryVideoPlayerState extends State<SyncedStoryVideoPlayer>
    with TickerProviderStateMixin {
  final Set<String> _completedCues = {};
  TimedStoryCue? _activeDecisionCue;
  TimedStoryCue? _activeDialogueCue;

  late AnimationController _pulseController;
  AnimationController? _qteController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    widget.controller.addListener(_onVideoTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onVideoTick);
    _pulseController.dispose();
    _qteController?.dispose();
    super.dispose();
  }

  void _onVideoTick() {
    if (!widget.controller.value.isInitialized) return;
    final Duration pos = widget.controller.value.position;

    // 1. فحص ظهور وإخفاء الترجمة والحوارات حسب الثانية الحالية
    TimedStoryCue? foundDialogue;
    for (final cue in widget.cues) {
      if (cue.subtitleStart != null &&
          cue.subtitleEnd != null &&
          !_completedCues.contains(cue.id)) {
        if (pos >= cue.subtitleStart! && pos <= cue.subtitleEnd!) {
          foundDialogue = cue;
          break;
        }
      }
    }

    if (_activeDialogueCue != foundDialogue) {
      setState(() => _activeDialogueCue = foundDialogue);
    }

    // 2. فحص نقاط التوقف والقرار (Trigger Time)
    if (_activeDecisionCue == null) {
      for (final cue in widget.cues) {
        if (!_completedCues.contains(cue.id)) {
          final int diffMs = (pos - cue.triggerTime).inMilliseconds.abs();
          // إذا وصل الفيديو لنقطة القرار (بفارق أقل من 350 ملي ثانية)
          if (pos >= cue.triggerTime && diffMs < 600) {
            _triggerDecisionPause(cue);
            break;
          }
        }
      }
    }
  }

  void _triggerDecisionPause(TimedStoryCue cue) {
    widget.controller.pause();
    HapticFeedback.lightImpact();

    setState(() {
      _activeDecisionCue = cue;
      // إذا كان هناك حوار مرتبط بنفس اللحظة يظل ظاهراً حتى يضغط اللاعب
      if (cue.dialogueAr != null) {
        _activeDialogueCue = cue;
      }
    });

    if (cue.isQte) {
      _qteController?.dispose();
      _qteController = AnimationController(
        vsync: this,
        duration: Duration(seconds: cue.qteSeconds),
      )..forward();

      _qteController!.addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            mounted &&
            _activeDecisionCue == cue) {
          // في حال انتهاء وقت الـ QTE دون ضغط: يعيد المشهد قبل الانهيار بـ 3 ثوانٍ
          _retryQteScene(cue);
        }
      });
    }
  }

  void _retryQteScene(TimedStoryCue cue) {
    HapticFeedback.heavyImpact();
    setState(() => _activeDecisionCue = null);
    final rewindTime = cue.triggerTime - const Duration(seconds: 3);
    widget.controller.seekTo(
      rewindTime > Duration.zero ? rewindTime : Duration.zero,
    );
    widget.controller.play();
  }

  void _onUserActionPressed() {
    if (_activeDecisionCue == null) return;
    final currentCue = _activeDecisionCue!;

    HapticFeedback.mediumImpact();
    _qteController?.stop();

    // إخفاء الترجمة والأزرار فوراً قبل بداية اللقطة التالية (مثل لقطة الكبريت 02:01)
    setState(() {
      _completedCues.add(currentCue.id);
      _activeDecisionCue = null;
      _activeDialogueCue = null;
    });

    if (currentCue.nextVideoUrl != null && widget.onLoadNextClip != null) {
      widget.onLoadNextClip!(currentCue);
    } else {
      widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isQte = _activeDecisionCue?.isQte ?? false;
    final Color accentColor = isQte
        ? Colors.redAccent
        : const Color(0xFF00FF88);

    return Stack(
      fit: StackFit.expand,
      children: [
        // مشغل الفيديو
        Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.isInitialized
                ? widget.controller.value.aspectRatio
                : 9 / 16,
            child: VideoPlayer(widget.controller),
          ),
        ),

        // طبقة النصوص والأزرار التفاعلية
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. صندوق الحوار / الترجمة في الأعلى (عربي فوق وإنجليزي تحت)
                if (_activeDialogueCue != null &&
                    _activeDialogueCue!.dialogueAr != null)
                  _buildBilingualDialogueBox(
                    _activeDialogueCue!.dialogueAr!,
                    _activeDialogueCue!.dialogueEn ?? '',
                    accentColor,
                  )
                else
                  const SizedBox.shrink(),

                // 2. زر القرار والتفاعل في الأسفل عند توقف الفيديو
                if (_activeDecisionCue != null)
                  _buildDecisionPanel(_activeDecisionCue!, accentColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBilingualDialogueBox(
    String arText,
    String enText,
    Color accentColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THE SHADOW',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.75),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الظل',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                arText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (enText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  enText,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionPanel(TimedStoryCue cue, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cue.statusAr,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cue.statusEn,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            fontStyle: FontStyle.italic,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 14),
        if (cue.isQte && _qteController != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedBuilder(
              animation: _qteController!,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 1.0 - _qteController!.value,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.redAccent,
                    ),
                  ),
                );
              },
            ),
          ),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final double scale = 1.0 + (_pulseController.value * 0.025);
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: _onUserActionPressed,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cue.actionAr,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cue.actionEn,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accentColor.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
