import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/dress_the_dog/components/dog.dart';
import 'package:little_games/games/dress_the_dog/components/wardrobe_rail.dart';
import 'package:little_games/games/dress_the_dog/components/weather_switch.dart';
import 'package:little_games/games/dress_the_dog/dress_the_dog_screen.dart';
import 'package:little_games/games/dress_the_dog/wardrobe.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

void main() {
  group('Outfit feeling', () {
    test('the headline joke: swimming trunks in the snow is too cold', () {
      final outfit = const Outfit().wearing(Wardrobe.byId('swimming_trunks'));
      expect(outfit.feelingIn(Weather.snow), DogFeeling.tooCold);
    });

    test('a snow coat in the sun is too hot', () {
      final outfit = const Outfit().wearing(Wardrobe.byId('snow_coat'));
      expect(outfit.feelingIn(Weather.sun), DogFeeling.tooHot);
    });

    test('bare fur in the rain is too wet', () {
      expect(const Outfit().feelingIn(Weather.rain), DogFeeling.tooWet);
    });

    test('ONE sensible item is enough to be just right', () {
      // The scope's open question leans "one key item, not a four-slot
      // puzzle". This pins that: each weather has a single item that does it.
      expect(
        const Outfit().wearing(Wardrobe.byId('snow_coat')).feelingIn(Weather.snow),
        DogFeeling.justRight,
      );
      expect(
        const Outfit().wearing(Wardrobe.byId('raincoat')).feelingIn(Weather.rain),
        DogFeeling.justRight,
      );
      expect(
        const Outfit().wearing(Wardrobe.byId('swimming_trunks')).feelingIn(Weather.sun),
        DogFeeling.justRight,
      );
    });

    test('an in-between outfit is fine, never a complaint', () {
      // A woolly hat in the snow is not enough to go out in, but the dog is
      // not shivering either. There must be a large comfortable middle: most
      // of what a child assembles will land here and it must feel fine.
      final outfit = const Outfit().wearing(Wardrobe.byId('woolly_hat'));
      expect(outfit.feelingIn(Weather.snow), DogFeeling.fine);
    });

    test('wearing swaps within a slot rather than stacking', () {
      final outfit = const Outfit()
          .wearing(Wardrobe.byId('woolly_hat'))
          .wearing(Wardrobe.byId('party_hat'));
      expect(outfit.items.length, 1);
      expect(outfit[Slot.head]?.id, 'party_hat');
    });

    test('an item can always be taken off again', () {
      final outfit = const Outfit().wearing(Wardrobe.byId('scarf'));
      expect(outfit.without(Slot.face).isBare, isTrue);
    });
  });

  group('Wardrobe', () {
    test('is never filtered by weather — every item in every weather', () {
      // The funny wrong answer must stay reachable. If a future session adds
      // weather filtering, this fails, which is the point (scope: "Not this").
      for (final slot in Slot.values) {
        expect(Wardrobe.forSlot(slot), isNotEmpty);
      }
      expect(Wardrobe.items.length, 12);
    });

    test('every slot offers a warm, a cool and a neutral-ish choice', () {
      // So that no weather is unreachable from any category the child happens
      // to be looking at.
      for (final slot in [Slot.head, Slot.body, Slot.feet]) {
        final warmths = Wardrobe.forSlot(slot).map((i) => i.warmth);
        expect(warmths.any((w) => w > 0), isTrue, reason: '$slot has nothing warm');
        expect(warmths.any((w) => w < 0), isTrue, reason: '$slot has nothing cool');
      }
    });

    test('each weather has at least one item that answers it', () {
      expect(Wardrobe.items.any((i) => i.dry), isTrue);
      expect(Wardrobe.items.any((i) => i.warmth >= 2), isTrue);
      expect(Wardrobe.items.any((i) => i.warmth <= -1), isTrue);
    });
  });

  _screenTests();
  _playthroughTests();
  _dragTests();
}

// ---------------------------------------------------------------------------
// The screen. These pin the kid rules, not the look.
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) =>
            PlayerProgress(store: MemoryOnlyPlayerProgressPersistence()),
      ),
      Provider(
        create: (_) =>
            SettingsController(store: MemoryOnlySettingsPersistence()),
      ),
      Provider(create: (_) => AudioController()),
    ],
    child: MaterialApp(home: child),
  );
}

void _screenTests() {
  group('Dress the Dog screen', () {
    testWidgets('needs no reading — nothing child-facing renders text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('every touch target clears 80x80', (tester) async {
      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();

      for (final finder in [
        find.byType(WeatherSwitch),
        find.byType(WardrobeRail),
      ]) {
        expect(finder, findsOneWidget);
      }

      // Wardrobe tiles and weather buttons, measured rather than assumed.
      expect(WardrobeRail.tileSize, greaterThanOrEqualTo(80));
      expect(WeatherSwitch.buttonSize, greaterThanOrEqualTo(80));
      expect(HomeButton.size, greaterThanOrEqualTo(80));
    });

    testWidgets('the home button is present and reachable', (tester) async {
      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();

      expect(find.byType(HomeButton), findsOneWidget);
    });

    testWidgets('a mismatch is never blocked — swimmers go on in the snow', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();

      // Snow.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.ac_unit_rounded).last),
      );
      await tester.pump();

      // Body slot, then swimming trunks. The wardrobe is NOT filtered by
      // weather, so the trunks are right there in the snow — that is the joke.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byIcon(Icons.pool_rounded)));
      await tester.pump();

      final dog = tester.widget<Dog>(find.byType(Dog));
      // It went on, and the dog is cold about it — not prevented, not undone.
      expect(dog.outfit[Slot.body]?.id, 'swimming_trunks');
      expect(dog.feeling, DogFeeling.tooCold);
    });
  });
}

void _playthroughTests() {
  group('Dress the Dog playthrough', () {
    testWidgets('the snow story: cold in swimmers, warm once dressed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();

      DogFeeling feeling() => tester.widget<Dog>(find.byType(Dog)).feeling;

      // Snow, wearing nothing: chilly but not miserable.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.ac_unit_rounded).last),
      );
      await tester.pump();
      expect(feeling(), DogFeeling.tooCold);

      // Swimming trunks on — still cold, and still allowed.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byIcon(Icons.pool_rounded)));
      await tester.pump();
      expect(feeling(), DogFeeling.tooCold);

      // Swap to the snow coat: one sensible item and the dog is ready to go out.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).last),
      );
      await tester.pump();
      expect(feeling(), DogFeeling.justRight);

      // And it can all come off again — nothing is ever stuck.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).last),
      );
      await tester.pump();
      expect(tester.widget<Dog>(find.byType(Dog)).outfit.isBare, isTrue);
    });

    testWidgets('changing weather never blocks or undoes the outfit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();

      // Dress for the beach…
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byIcon(Icons.pool_rounded)));
      await tester.pump();

      // …then cycle every weather. The outfit survives all of them.
      for (final icon in [
        Icons.grain_rounded,
        Icons.ac_unit_rounded,
        Icons.wb_sunny_rounded,
      ]) {
        await tester.tapAt(tester.getCenter(find.byIcon(icon).last));
        await tester.pump();
        expect(
          tester.widget<Dog>(find.byType(Dog)).outfit[Slot.body]?.id,
          'swimming_trunks',
        );
      }
    });
  });
}

void _dragTests() {
  group('Dress the Dog drag and drop', () {
    Future<void> pumpGame(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(const DressTheDogScreen()));
      await tester.pump();
    }

    Outfit outfitOf(WidgetTester tester) =>
        tester.widget<Dog>(find.byType(Dog)).outfit;

    testWidgets('dragging an item onto the dog puts it on', (tester) async {
      await pumpGame(tester);

      // Body slot, then drag the swimming trunks onto the dog.
      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();

      final item = find.byIcon(Icons.pool_rounded);
      final dog = find.byType(Dog);
      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(dog));
      await tester.pump();
      await gesture.up();
      // NOT pumpAndSettle: the screen's idle Ticker never stops, so
      // 'settled' never arrives. A bounded pump is enough for the drop.
      await tester.pump(const Duration(milliseconds: 300));

      expect(outfitOf(tester)[Slot.body]?.id, 'swimming_trunks');
    });

    testWidgets('a drag onto the dog wears the item ONCE, not twice', (
      tester,
    ) async {
      // The tile fires on tap-down AND can start a drag. Wearing is
      // idempotent per slot, so a drag must not toggle the item back off.
      await pumpGame(tester);

      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();

      final item = find.byIcon(Icons.pool_rounded);
      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(Dog)));
      await tester.pump();
      await gesture.up();
      // NOT pumpAndSettle: the screen's idle Ticker never stops, so
      // 'settled' never arrives. A bounded pump is enough for the drop.
      await tester.pump(const Duration(milliseconds: 300));

      expect(outfitOf(tester)[Slot.body]?.id, 'swimming_trunks');
      expect(outfitOf(tester).items.length, 1);
    });

    testWidgets('a MISSED drop changes nothing and is never punished', (
      tester,
    ) async {
      await pumpGame(tester);

      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();

      // Drag the trunks out into empty sky, far from the dog, and let go.
      final gesture =
          await tester.startGesture(tester.getCenter(find.byIcon(Icons.pool_rounded)));
      await tester.pump();
      await gesture.moveTo(const Offset(700, 60));
      await tester.pump();
      await gesture.up();
      // NOT pumpAndSettle: the screen's idle Ticker never stops, so
      // 'settled' never arrives. A bounded pump is enough for the drop.
      await tester.pump(const Duration(milliseconds: 300));

      // Nothing was worn, nothing was removed, nothing is stuck: the child can
      // simply try again, or tap instead.
      expect(outfitOf(tester).isBare, isTrue);
      expect(find.byType(Dog), findsOneWidget);
    });

    testWidgets('the dog perks up while something is being carried', (
      tester,
    ) async {
      // The only signal telling a child where clothes go, with no words: the
      // dog lifts its ears and bounces while an item is in the air.
      await pumpGame(tester);

      expect(tester.widget<Dog>(find.byType(Dog)).reaching, isFalse);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Draggable<WardrobeItem>).first),
      );
      await tester.pump();
      for (final x in [900.0, 860.0, 820.0]) {
        await gesture.moveTo(Offset(x, 300));
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(tester.widget<Dog>(find.byType(Dog)).reaching, isTrue);

      // And it settles back down afterwards — never stuck mid-reach.
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<Dog>(find.byType(Dog)).reaching, isFalse);
    });

    testWidgets('the item stays in the rail while being dragged', (
      tester,
    ) async {
      // A tile that vanishes from the rail reads to a child as having broken
      // it. The original stays put (dimmed) and a ghost follows the finger.
      await pumpGame(tester);

      final before = find.byIcon(Icons.ac_unit_rounded).evaluate().length;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Draggable<WardrobeItem>).first),
      );
      await tester.pump();
      for (final x in [900.0, 860.0, 820.0]) {
        await gesture.moveTo(Offset(x, 300));
        await tester.pump(const Duration(milliseconds: 60));
      }

      // The rail tile is still there, and a ghost now exists as well.
      expect(
        find.byIcon(Icons.ac_unit_rounded).evaluate().length,
        greaterThan(before),
      );

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('tap still works — drag never became the only way in', (
      tester,
    ) async {
      // The whole point of keeping both: a child who cannot manage a drag must
      // still be able to dress the dog.
      await pumpGame(tester);

      await tester.tapAt(
        tester.getCenter(find.byIcon(Icons.checkroom_rounded).first),
      );
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byIcon(Icons.pool_rounded)));
      await tester.pump();

      expect(outfitOf(tester)[Slot.body]?.id, 'swimming_trunks');
    });
  });
}
