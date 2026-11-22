class Episode {
  const Episode({
    required this.id,
    required this.title,
    required this.number,
    this.durationLabel = 'ตอนใหม่',
    this.hlsUrl = '',
  });

  final String id;
  final String title;
  final int number;
  final String durationLabel;
  final String hlsUrl;
}
