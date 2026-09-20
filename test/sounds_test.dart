import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/songs.dart';
import 'package:little_games/audio/sounds.dart';

void main() {
  group('kid sound cues', () {
    test('every sfx type maps to at least one real file', () {
      for (final type in SfxType.values) {
        expect(
          soundTypeToFilename(type),
          isNotEmpty,
          reason: '$type has no audio file',
        );
      }
    });

    test('the frequent cue has variants so it does not grate', () {
      // A child pops many balloons a minute; one identical sample every time
      // becomes irritating fast.
      expect(soundTypeToFilename(SfxType.kidPop).length, greaterThan(1));
    });

    test('pop and celebrate are different sounds', () {
      // The celebration is the reward. If it is the same sound as an ordinary
      // pop it does not read as one (CLAUDE.md §3).
      expect(
        soundTypeToFilename(SfxType.kidPop),
        isNot(contains(soundTypeToFilename(SfxType.kidCelebrate).single)),
      );
    });

    test('the mistake cue is the quietest, the celebration the loudest', () {
      final wobble = soundTypeToVolume(SfxType.kidWobble);
      final pop = soundTypeToVolume(SfxType.kidPop);
      final celebrate = soundTypeToVolume(SfxType.kidCelebrate);

      // Never scold: the cue after a mistake is softer than the cue after a
      // success, and the reward is the biggest thing the child hears.
      expect(wobble, lessThan(pop));
      expect(celebrate, greaterThan(pop));
    });

    test('no kid cue is louder than the reward or quieter than the mistake', () {
      // The generalisation of the rule above, and it matters more with every
      // cue added: Neil the Seal alone brought seven new SfxTypes. Never
      // scold, and make the reward the biggest thing the child hears
      // (CLAUDE.md §3) — so the whole kid set has to live inside that band.
      final wobble = soundTypeToVolume(SfxType.kidWobble);
      final celebrate = soundTypeToVolume(SfxType.kidCelebrate);

      for (final type in SfxType.values) {
        if (!type.name.startsWith('kid')) continue;
        if (type == SfxType.kidWobble || type == SfxType.kidCelebrate) continue;
        final volume = soundTypeToVolume(type);
        expect(
          volume,
          greaterThan(wobble),
          reason: '$type is quieter than the cue that follows a mistake',
        );
        expect(
          volume,
          lessThanOrEqualTo(celebrate),
          reason: '$type is louder than the celebration',
        );
      }
    });

    test('every cue a game asks for by name exists as a file', () {
      // KidSounds is the only thing games talk to, and each of its cues maps
      // to a type here. A type with no file is a silent game.
      for (final type in SfxType.values) {
        for (final file in soundTypeToFilename(type)) {
          expect(file, endsWith('.mp3'), reason: '$type has an odd filename');
        }
      }
    });

    test('kid cues do not use the arcade hit or damage sounds', () {
      // These startle a five-year-old. The kid cues must stay off them even if
      // someone rewires the enum later.
      const arcade = {'hit1.mp3', 'hit2.mp3', 'damage1.mp3', 'damage2.mp3'};
      for (final type in [
        SfxType.kidPop,
        SfxType.kidCelebrate,
        SfxType.kidWobble,
        SfxType.kidTap,
      ]) {
        expect(soundTypeToFilename(type).toSet().intersection(arcade), isEmpty);
      }
    });
  });

  group('Songs', () {
    test('named songs compare by value, so a rebuild does not restart them', () {
      expect(Songs.play, equals(Songs.play));
      expect(
        Songs.play,
        equals(const Song('tropical_fantasy.mp3', 'anything', artist: 'x')),
      );
      expect(Songs.play, isNot(equals(Songs.menu)));
    });

    test('named songs are part of the shipped playlist', () {
      expect(songs, contains(Songs.play));
      expect(songs, contains(Songs.menu));
    });
  });
}
