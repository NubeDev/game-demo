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

  /// Brighter, for the picture menu.
  static const Song menu = Song('bit_forrest.mp3', 'Bit Forrest', artist: 'bertz');
}

class Song {
  final String filename;

  final String name;

  final String? artist;

  const Song(this.filename, this.name, {this.artist});

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
