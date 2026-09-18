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
