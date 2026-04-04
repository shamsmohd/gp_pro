import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class ExerciseVideo {
  const ExerciseVideo({
    required this.title,
    required this.youtubeId,
    required this.durationMinutes,
  });

  final String title;
  final String youtubeId;
  final int durationMinutes;

  String get url => 'https://www.youtube.com/watch?v=$youtubeId';
  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/0.jpg';

  factory ExerciseVideo.fromJson(Map<String, dynamic> json) {
    return ExerciseVideo(
      title: json['title'] as String,
      youtubeId: json['youtubeId'] as String,
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}

List<ExerciseVideo>? _cachedVideos;

Future<List<ExerciseVideo>> loadExerciseVideos() async {
  if (_cachedVideos != null) return _cachedVideos!;

  final jsonString = await rootBundle.loadString('assets/exercise_videos.json');
  final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
  _cachedVideos = jsonList
      .map((e) => ExerciseVideo.fromJson(e as Map<String, dynamic>))
      .toList();
  return _cachedVideos!;
}

ExerciseVideo pickDailyVideo(List<ExerciseVideo> videos) {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  final random = Random(seed);
  return videos[random.nextInt(videos.length)];
}
