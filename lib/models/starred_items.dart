import 'album.dart';
import 'artist.dart';
import 'song.dart';

class StarredItems {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;

  const StarredItems({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });
}
