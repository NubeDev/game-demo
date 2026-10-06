const List<Song> songs = [
  Song('bit_forrest.mp3', 'Bit Forrest', artist: 'bertz'),
  Song('free_run.mp3', 'Free Run', artist: 'TAD'),
  Song('tropical_fantasy.mp3', 'Tropical Fantasy', artist: 'Spring Spring'),
];

/// The track a screen asks for by name, rather than by playlist position.
///
/// Both are from the template. Played at a low volume under the game: music
/// here is atmosphere, and must never compete with the sound cues a child is
/// actually responding to (CLAUDE.md §3).
class Songs {
  const Songs._();

  /// Calm and steady, for play.
  static const Song play = Song(
    'tropical_fantasy.mp3',
    'Tropical Fantasy',
    artist: 'Spring Spring',
  );

  /// Little Train's own music: a chugging xylophone-and-ukulele loop made with
  /// Google's Lyria model (`tools/gen_little_train_audio.py`). The first track
  /// in the app written for its game rather than borrowed from the template.
  ///
  /// It is a 30-second clip, so it [Song.loops] — otherwise the playlist would
  /// roll on to a template track half a minute into the ride. It is also kept
  /// OUT of the shuffled [songs] list, so no other screen ever lands on it.
  static const Song littleTrain = Song(
    'little_train.mp3',
    'Little Train',
    artist: 'Lyria (generated)',
    loops: true,
  );

  /// Brighter, for the picture menu.
  static const Song menu = Song('bit_forrest.mp3', 'Bit Forrest', artist: 'bertz');
}

class Song {
  final String filename;

  final String name;

  final String? artist;

  /// Repeat this song for as long as a screen is asking for it, instead of
  /// rolling on to the next one in the playlist. For short generated loops.
  final bool loops;

  const Song(this.filename, this.name, {this.artist, this.loops = false});

  @override
  String toString() => 'Song<$filename>';

  // Value equality: screens name their song with a fresh const instance, so
  // identity comparison would restart the track on every rebuild.
  @override
  bool operator ==(Object other) =>
      other is Song && other.filename == filename;

  @override
  int get hashCode => filename.hashCode;
}
