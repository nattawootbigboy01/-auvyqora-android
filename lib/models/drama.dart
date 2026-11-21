import 'episode.dart';

class Drama {
  const Drama({required this.id, required this.title, required this.synopsis, required this.genre, required this.episodes, this.isFeatured = false});
  final String id;
  final String title;
  final String synopsis;
  final String genre;
  final List<Episode> episodes;
  final bool isFeatured;
}
