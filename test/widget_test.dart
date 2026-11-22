// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:shadow_shat/burning_card_with_real_fire.dart';
import 'package:shadow_shat/day3.dart';
import 'package:shadow_shat/day4.dart';
import 'package:shadow_shat/ha_interaction.dart' as ha;
import 'package:shadow_shat/story_interaction_overlay.dart';
import 'package:shadow_shat/story_transition_placeholder.dart';
import 'package:shadow_shat/shadow_chat_screen.dart' show ShadowChatScreen;

import 'package:shadow_shat/main.dart';

void main() {
  test('Day 4 plays all nine story videos in order through The End', () {
    expect(dayFourVideoPaths, [
      'assets/videos/day4/day4_01.mp4',
      'assets/videos/day4/day4_02.mp4',
      'assets/videos/day4/day4_03.mp4',
      'assets/videos/day4/day4_04.mp4',
      'assets/videos/day4/day4_05_basement_collapse.mp4',
      'assets/videos/day4/day4_06_shadow_on_stairs.mp4',
      'assets/videos/day4/day4_07_light_from_guide.mp4',
      'assets/videos/day4/day4_08_exit_with_guide.mp4',
      'assets/videos/day4/day4_09_the_end.mp4',
    ]);
  });

  test('each Day 3 corridor reaches its matching Day 4 collapse', () {
    expect(dayThreeCorridorCollapseIndices, {
      dayThreeMirrorEndingPhase: 3,
      dayThreeNarrowEndingPhase: 1,
      dayThreeConflictEndingPhase: 2,
      dayThreeAlarmCorridorPhase: 0,
    });

    for (final collapseIndex in dayThreeCorridorCollapseIndices.values) {
      expect(
        dayFourNextVideoIndex(
          collapseIndex,
          corridorCollapseIndex: collapseIndex,
        ),
        dayFourSharedStoryStartIndex,
      );
    }

    expect(dayFourNextVideoIndex(0), 1);
    expect(
      dayFourNextVideoIndex(
        dayFourSharedStoryStartIndex,
        corridorCollapseIndex: 3,
      ),
      dayFourSharedStoryStartIndex + 1,
    );
    expect(
      dayFourNextVideoIndex(
        dayFourVideoPaths.length - 1,
        corridorCollapseIndex: 3,
      ),
      isNull,
    );
  });

  test('story decisions match the visible events in each video', () {
    expect(storyScenes, hasLength(5));
    expect(storyScenes[0].triggerAt, const Duration(milliseconds: 9500));
    expect(storyScenes[1].triggerAt, const Duration(seconds: 5));
    expect(storyScenes[2].triggerAt, const Duration(milliseconds: 8500));
    expect(storyScenes[2].autoAdvanceSeconds, 2);
    expect(storyScenes.skip(3), hasLength(2));
    expect(storyScenes[3].triggerAt, const Duration(seconds: 14));
    expect(storyScenes[4].triggerAt, const Duration(seconds: 28));
    expect(dayTwoStoryScenes, hasLength(3));
    expect(dayTwoStoryScenes[0].triggerAt, const Duration(seconds: 14));
    expect(dayTwoStoryScenes[1].triggerAt, const Duration(seconds: 22));
    expect(dayTwoStoryScenes[2].triggerAt, const Duration(seconds: 28));
    expect(dayTwoStoryScenes[1].statusAr, 'الظل يصعد السلم الحجري أمامك');
    expect(dayTwoStoryScenes[1].actionAr, 'اصعد السلم خلف الظل 🪜');
    expect(storyScenes[3].statusAr, ha.syncedStoryCues[3].statusAr);
    expect(storyScenes[3].actionAr, ha.syncedStoryCues[3].actionAr);
    expect(storyScenes[4].statusAr, ha.syncedStoryCues[4].statusAr);
    expect(storyScenes[4].actionAr, ha.syncedStoryCues[4].actionAr);
    expect(storyScenes[3].isQte, isFalse);
    expect(storyScenes[4].isQte, isFalse);
    expect(
      dayThreeFloorCollapseScene.triggerAt,
      const Duration(milliseconds: 2500),
    );
    expect(dayThreeFloorCollapseScene.retryFrom, Duration.zero);
    expect(dayThreeFloorCollapseScene.isQte, isTrue);
    expect(dayThreeFloorCollapseScene.qteSeconds, 3);
    expect(dayThreeFloorCollapseScene.statusAr, 'الأرض تنهار تحتك!');
    expect(dayThreeFloorCollapseScene.actionAr, 'احمِ نفسك فوراً! ⚠️');
  });

  testWidgets('Story action is delivered from the interaction overlay', (
    WidgetTester tester,
  ) async {
    var actionCount = 0;
    var failureCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              InteractiveStoryOverlay(
                scene: dayThreeFloorCollapseScene,
                showInteraction: true,
                onActionPressed: () => actionCount++,
                onQteFailed: () => failureCount++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('story-interaction-action')));
    await tester.pump();

    expect(actionCount, 1);
    expect(failureCount, 0);
  });

  testWidgets('day one shadow crossing auto-advances after two seconds', (
    WidgetTester tester,
  ) async {
    var actionCount = 0;
    var failureCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              InteractiveStoryOverlay(
                scene: storyScenes[2],
                showInteraction: true,
                onActionPressed: () => actionCount++,
                onQteFailed: () => failureCount++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));

    expect(actionCount, 1);
    expect(failureCount, 0);
  });

  testWidgets('scene transition shows a loading screen instead of black', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StoryTransitionPlaceholder()),
    );

    expect(find.text('جارٍ الانتقال للمشهد التالي...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Story QTE timeout triggers the scene failure callback', (
    WidgetTester tester,
  ) async {
    var failureCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              InteractiveStoryOverlay(
                scene: dayThreeFloorCollapseScene,
                showInteraction: true,
                onActionPressed: () {},
                onQteFailed: () => failureCount++,
              ),
            ],
          ),
        ),
      ),
    );

    for (var second = 0; second < 3; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));

    expect(failureCount, 1);
  });

  test('Day 3 video order and live scene context match the story', () async {
    expect(dayThreeStartingPhase, 1);
    expect(dayThreeCandleInteractionAt, const Duration(seconds: 6));
    expect(dayThreeFlashlightInteractionAt, const Duration(milliseconds: 4500));
    expect(dayThreeCandleQuestion, 'أين أنا؟');
    expect(dayThreeCandleStatus, 'المكان مظلم تماماً.. وهناك شمعة بجانبك');
    expect(dayThreeCandleAction, 'إشعال الشمعة بعود الثقاب 🔥');
    expect(dayThreeFlashlightStatus, 'الكشاف بجانبك على الأرض');
    expect(dayThreeFlashlightAction, 'التقط الكشاف 🔦');
    expect(dayThreeVideoPaths, [
      'assets/videos/day3/day3_04_first_corridor.mp4',
      'assets/videos/day3/day3_02_light_candle.mp4',
      'assets/videos/day3/day3_03_what_way.mp4',
      'assets/videos/day3/day3_04_first_corridor.mp4',
      'assets/videos/day3/day3_05_mirror.mp4',
      'assets/videos/day3/day3_06_second_corridor.mp4',
      'assets/videos/day3/day3_07_narrow_corridor_dark.mp4',
      'assets/videos/day3/clean-1.mp4',
      'assets/videos/day3/clean.mp4',
      'assets/videos/day3/day3_10_final_alarm_corridor.mp4',
    ]);
    expect(dayThreeCorridorFollowupPhases, {
      dayThreeMirrorCorridorPhase: dayThreeMirrorEndingPhase,
      dayThreeNarrowCorridorPhase: dayThreeNarrowEndingPhase,
      dayThreeConflictCorridorPhase: dayThreeConflictEndingPhase,
    });
    for (final phase in [
      dayThreeMirrorCorridorPhase,
      dayThreeMirrorEndingPhase,
      dayThreeNarrowCorridorPhase,
      dayThreeNarrowEndingPhase,
      dayThreeConflictCorridorPhase,
      dayThreeConflictEndingPhase,
      dayThreeAlarmCorridorPhase,
    ]) {
      expect(
        (await rootBundle.load(dayThreeVideoPaths[phase - 1])).lengthInBytes,
        greaterThan(0),
        reason: 'Day 3 phase $phase must have a bundled video',
      );
    }
    expect(dayThreeSceneContext(1), contains('falls as the door collapses'));
    expect(dayThreeSceneContext(2), contains('lights a candle'));
    expect(dayThreeSceneContext(3), contains('which way'));
    expect(dayThreeSceneContext(4), contains('mirror corridor'));
    expect(dayThreeSceneContext(5), contains('mirror'));
    expect(dayThreeSceneContext(6), contains('second corridor'));
    expect(dayThreeSceneContext(7), contains('light goes out'));
    expect(dayThreeSceneContext(8), contains('inner conflict corridor'));
    expect(
      dayThreeSceneContext(9),
      contains('inner conflict at the corridor end'),
    );
    expect(dayThreeSceneContext(10), contains('alarm on their phone'));
  });

  testWidgets('burn effect animates the card away', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: BurningCardWithRealFire(
            key: const ValueKey('burn-effect-test'),
            controller: controller,
            child: const Text('door card'),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      1,
    );

    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final middleOpacity = tester
        .widget<Opacity>(
          find.descendant(
            of: find.byKey(const ValueKey('burn-effect-test')),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    expect(middleOpacity, greaterThan(0));
    expect(middleOpacity, lessThan(1));
    expect(
      tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(CustomPaint),
            ),
          )
          .foregroundPainter,
      isA<RealFirePainter>(),
    );

    expect(
      tester
          .widget<ClipPath>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(ClipPath),
            ),
          )
          .clipper,
      isNotNull,
    );

    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0,
    );
  });

  test('duplicate Firebase initialization is ignored safely', () {
    final duplicateError = FirebaseException(
      plugin: 'firebase_core',
      code: 'duplicate-app',
      message: 'A Firebase App named "[DEFAULT]" already exists',
    );

    expect(isDuplicateFirebaseInitializationError(duplicateError), isTrue);
    expect(
      isDuplicateFirebaseInitializationError(
        FirebaseException(
          plugin: 'firebase_core',
          code: 'unknown',
          message: 'other error',
        ),
      ),
      isFalse,
    );
  });

  test(
    'Firebase web config falls back to demo mode when placeholder is used',
    () {
      const webAppId = '1:525641785110:web:abcdef123456';
      expect(
        hasUsableFirebaseWebConfig('REPLACE_WITH_WEB_API_KEY', webAppId),
        isFalse,
      );
      expect(hasUsableFirebaseWebConfig('abc123validkey', webAppId), isTrue);
      expect(hasUsableFirebaseWebConfig('', webAppId), isFalse);
      expect(
        hasUsableFirebaseWebConfig(
          'abc123validkey',
          '1:525641785110:android:abcdef123456',
        ),
        isFalse,
      );
    },
  );

  test('Firebase add failures expose the real error code', () {
    expect(
      firebaseWriteFailureMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      contains('permission-denied'),
    );
  });

  test('regular contact action blocks duplicate request states', () {
    expect(
      determineRegularContactAction(myStatus: 'pending', otherStatus: 'none'),
      'pending',
    );
    expect(
      determineRegularContactAction(myStatus: 'none', otherStatus: 'incoming'),
      'incoming',
    );
    expect(
      determineRegularContactAction(myStatus: 'accepted', otherStatus: 'none'),
      'accepted',
    );
    expect(
      determineRegularContactAction(myStatus: 'rejected', otherStatus: 'none'),
      'rejected',
    );
  });

  test('display names are sanitized consistently before saving', () {
    expect(sanitizeDisplayName('   علي   أحمد   '), 'علي أحمد');
    expect(sanitizeDisplayName(''), isEmpty);
  });

  test(
    'secret member removal policy allows group removal and owner-only room removal',
    () {
      expect(
        canRemoveSecretMember(
          isGroup: true,
          ownerVerified: false,
          isOwnerUser: false,
        ),
        isTrue,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: false,
          isOwnerUser: true,
        ),
        isFalse,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: true,
          isOwnerUser: true,
        ),
        isTrue,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: true,
          isOwnerUser: false,
        ),
        isFalse,
      );
    },
  );

  testWidgets('Shadow Chat app starts', (WidgetTester tester) async {
    appLockEnabledNotifier.value = true;
    appLockPasswordNotifier.value = await hashPassword(
      'test-app-lock-password',
    );
    await tester.pumpWidget(const MaterialApp(home: AppLockGate()));

    expect(find.byType(AppLockGate), findsOneWidget);
    expect(find.text('تغيير كلمة سر قفل التطبيق'), findsOneWidget);
  });

  testWidgets('closed door video fills the screen on phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
    expect(
      find.byKey(const ValueKey('shadow-door-black-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('shadow-door-video-player')),
      findsOneWidget,
    );
    expect(find.byType(VideoPlayer), findsOneWidget);
    final previewSize = tester.getSize(
      find.byKey(const ValueKey('shadow-door-preview')),
    );
    expect(previewSize, const Size(390, 844));
    expect(
      tester
          .widget<FittedBox>(
            find.descendant(
              of: find.byKey(const ValueKey('shadow-door-preview')),
              matching: find.byType(FittedBox),
            ),
          )
          .fit,
      BoxFit.cover,
    );
    expect(find.byKey(const ValueKey('shadow-door-frame')), findsNothing);
    expect(find.byKey(const ValueKey('shadow-door-image-left')), findsNothing);
    expect(find.byKey(const ValueKey('shadow-door-image-right')), findsNothing);
  });

  testWidgets('entering the door triggers a strong haptic impact', (
    WidgetTester tester,
  ) async {
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
    await tester.tap(find.byKey(const ValueKey('open-door')));
    await tester.pump();

    expect(
      platformCalls,
      contains(
        isA<MethodCall>()
            .having((call) => call.method, 'method', 'HapticFeedback.vibrate')
            .having(
              (call) => call.arguments,
              'arguments',
              'HapticFeedbackType.heavyImpact',
            ),
      ),
    );
  });

  testWidgets('journey has no bottom transition button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
    expect(find.byKey(const ValueKey('next-day')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('open-door')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('next-day')), findsNothing);
  });

  testWidgets('chat list opens the Shadow Chat door screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    firebaseReady = false;
    await tester.pumpWidget(const MaterialApp(home: ChatListScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محادثة الظل'));
    await tester.pumpAndSettle();

    expect(find.text('هل تجرأ على فتح الباب؟'), findsOneWidget);
    expect(find.text('الرجوع'), findsNothing);
    expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);
  });

  testWidgets('door exit button returns to the previous app page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShadowChatScreen(),
                  ),
                );
              },
              child: const Text('Open Shadow Chat'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Shadow Chat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exit-door')));
    await tester.pumpAndSettle();
    expect(find.text('Open Shadow Chat'), findsOneWidget);
  });

  testWidgets('local demo starts without initializing Firebase', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'startup_intro_seen': true,
      'has_seen_onboarding': true,
    });
    firebaseReady = false;
    appLockEnabledNotifier.value = false;
    await tester.pumpWidget(const ShadowChatApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatListScreen), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('محادثة الظل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('هل تجرأ على فتح الباب؟'), findsOneWidget);
    expect(find.text('الرجوع'), findsNothing);
    expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('local demo restores dark mode on startup', () async {
    SharedPreferences.setMockInitialValues({darkModeKey: false});

    await loadAppLockSettings();
    final preferences = await SharedPreferences.getInstance();

    expect(globalDarkModeNotifier.value, isTrue);
    expect(preferences.getBool(darkModeKey), isTrue);
  });
}
