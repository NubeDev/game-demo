import 'package:flutter/material.dart';

import '../../shared/kid_palette.dart';

/// The weather the child has chosen. Three, because each has a piece of
/// clothing a five-year-old already associates with it — wind does not.
///
/// The child always picks this. Nothing in the game ever changes the weather on
/// its own: an outfit they were pleased with must never be invalidated by
/// something they did not do (scope: "Not this").
enum Weather { sun, rain, snow }

/// Where an item goes on the dog. One item per slot at a time, so tapping a
/// second hat swaps rather than stacking — no way to reach a broken-looking dog.
enum Slot { head, face, body, feet }

/// How the dog feels about what it is wearing, given the weather.
///
/// This is the whole game in one enum, so read the rule here (CLAUDE.md §3 —
/// "no losing", and the scope's Kid-rules impact):
///
///  * [justRight] is not "correct" and [tooCold]/[tooHot] are not "wrong".
///    Nothing is marked, scored or counted, and a mismatch is never blocked —
///    the child can leave the dog in swimming trunks in the snow forever.
///  * The mismatch reactions are the FUNNIEST thing in the game, on purpose.
///    Plenty of children will do it deliberately, and that is a success, not a
///    failure to correct.
///  * [justRight] earns a bigger reward (the dog goes out to play) rather than
///    a tick. The reward is what the dog does, never a judgement of the child.
enum DogFeeling {
  /// Dressed for the weather — the dog can go out and play.
  justRight,

  /// Shivering: too little on, in the snow. Slapstick, tail still wagging.
  /// Never distress — a five-year-old reads an unhappy animal as real.
  tooCold,

  /// Panting and fanning itself: too much on, in the sun.
  tooHot,

  /// Getting rained on with nothing to keep it dry. Ends in a good shake.
  tooWet,

  /// Nothing to report — comfortable enough, just wearing things.
  fine,
}

/// One thing the dog can wear.
///
/// [warmth] is the only number that matters: how much this item insulates,
/// from -2 (beachwear — actively less than bare fur) to 3 (a snow coat).
/// [dry] marks the items that keep rain off. Together they decide
/// [DogFeeling], which keeps the rule in one place instead of scattering
/// "if snowing and wearing trunks" checks through the animation code.
@immutable
class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.slot,
    required this.icon,
    required this.color,
    this.warmth = 0,
    this.dry = false,
  });

  /// Stable id, used by tests and by the saved-outfit shelf. Never shown.
  final String id;
  final Slot slot;

  /// Placeholder art: an icon, until real artwork arrives. Paths land in
  /// `assets.dart` and this becomes a sprite without touching the rules above.
  final IconData icon;
  final Color color;

  final int warmth;
  final bool dry;
}

/// What the dog is wearing: at most one item per slot.
@immutable
class Outfit {
  const Outfit([this.items = const {}]);

  final Map<Slot, WardrobeItem> items;

  bool get isBare => items.isEmpty;

  WardrobeItem? operator [](Slot slot) => items[slot];

  /// Puts [item] on, replacing whatever was in its slot.
  Outfit wearing(WardrobeItem item) =>
      Outfit({...items, item.slot: item});

  /// Takes the item off [slot] — tapping the item already on the dog removes
  /// it, so a child can always undo without finding a separate "remove" control.
  Outfit without(Slot slot) =>
      Outfit({...items}..remove(slot));

  /// Total insulation. Bare fur is 0.
  int get warmth =>
      items.values.fold(0, (sum, item) => sum + item.warmth);

  /// True if anything worn keeps the rain off.
  bool get isDry => items.values.any((item) => item.dry);

  /// How the dog feels, right now.
  ///
  /// The thresholds are deliberately wide: a child should fall into
  /// [justRight] by putting on ONE sensible thing, not by solving a four-slot
  /// puzzle (scope open question — leaning "one key item"). Anything in
  /// between is [fine], which is a perfectly good place to stay.
  DogFeeling feelingIn(Weather weather) {
    switch (weather) {
      case Weather.snow:
        if (warmth <= 0) return DogFeeling.tooCold;
        return warmth >= 2 ? DogFeeling.justRight : DogFeeling.fine;
      case Weather.sun:
        if (warmth >= 3) return DogFeeling.tooHot;
        // Beachwear in the sun is the ideal, and so is bare fur plus shades.
        return warmth <= -1 ? DogFeeling.justRight : DogFeeling.fine;
      case Weather.rain:
        if (!isDry) return DogFeeling.tooWet;
        return DogFeeling.justRight;
    }
  }
}

/// Every item in the wardrobe.
///
/// **Never filtered by weather.** Swimming trunks stay available in the snow,
/// or the funny wrong answer — the thing the child actually wants to do — would
/// be impossible to reach (scope: "What").
class Wardrobe {
  const Wardrobe._();

  static const items = <WardrobeItem>[
    // Head
    WardrobeItem(
      id: 'woolly_hat',
      slot: Slot.head,
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF4FC3F7),
      warmth: 1,
    ),
    WardrobeItem(
      id: 'sun_hat',
      slot: Slot.head,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFFE156),
      warmth: -1,
    ),
    WardrobeItem(
      id: 'party_hat',
      slot: Slot.head,
      icon: Icons.celebration_rounded,
      color: Color(0xFFFF6B8A),
    ),
    WardrobeItem(
      id: 'umbrella_hat',
      slot: Slot.head,
      icon: Icons.umbrella_rounded,
      color: Color(0xFFB07BE8),
      dry: true,
    ),
    // Face
    WardrobeItem(
      id: 'sunglasses',
      slot: Slot.face,
      icon: Icons.remove_red_eye_rounded,
      color: Color(0xFF4A3B33),
      warmth: -1,
    ),
    WardrobeItem(
      id: 'scarf',
      slot: Slot.face,
      icon: Icons.waves_rounded,
      color: Color(0xFFFF6B8A),
      warmth: 1,
    ),
    // Body
    WardrobeItem(
      id: 'snow_coat',
      slot: Slot.body,
      icon: Icons.checkroom_rounded,
      color: Color(0xFF6FD97F),
      warmth: 3,
    ),
    WardrobeItem(
      id: 'raincoat',
      slot: Slot.body,
      icon: Icons.umbrella_rounded,
      color: Color(0xFFFFB03A),
      warmth: 1,
      dry: true,
    ),
    WardrobeItem(
      id: 'swimming_trunks',
      slot: Slot.body,
      icon: Icons.pool_rounded,
      color: Color(0xFF4FC3F7),
      warmth: -2,
    ),
    // Feet
    WardrobeItem(
      id: 'wellies',
      slot: Slot.feet,
      icon: Icons.water_drop_rounded,
      color: Color(0xFFFFE156),
      warmth: 1,
      dry: true,
    ),
    WardrobeItem(
      id: 'snow_boots',
      slot: Slot.feet,
      icon: Icons.hiking_rounded,
      color: Color(0xFFB07BE8),
      warmth: 2,
    ),
    WardrobeItem(
      id: 'flip_flops',
      slot: Slot.feet,
      icon: Icons.beach_access_rounded,
      color: Color(0xFFFF6B8A),
      warmth: -1,
    ),
  ];

  /// The items for one slot, in wardrobe order.
  static List<WardrobeItem> forSlot(Slot slot) =>
      items.where((item) => item.slot == slot).toList();

  static WardrobeItem byId(String id) =>
      items.firstWhere((item) => item.id == id);

  /// The sky colours behind the dog for each weather. Pale, like the rest of
  /// the app, so the dog and the wardrobe stay the loudest things on screen.
  static (Color, Color) skyFor(Weather weather) => switch (weather) {
        Weather.sun => (KidPalette.skyTop, KidPalette.skyBottom),
        Weather.rain => (const Color(0xFFB8C6D4), const Color(0xFFDCE6EE)),
        Weather.snow => (const Color(0xFFD6E4F0), const Color(0xFFF4F9FF)),
      };
}
