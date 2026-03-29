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
}

const exerciseVideos = [
  ExerciseVideo(
    title: 'Full Body HIIT Workout',
    youtubeId: 'ml6cT4AZdqI',
    durationMinutes: 20,
  ),
  ExerciseVideo(
    title: '10 Min Morning Stretch',
    youtubeId: 'g_tea8ZNsgA',
    durationMinutes: 10,
  ),
  ExerciseVideo(
    title: '30 Min Fat Burning Cardio',
    youtubeId: 'gC_L9qAHVJ8',
    durationMinutes: 30,
  ),
  ExerciseVideo(
    title: '15 Min Ab Workout',
    youtubeId: '1919eTCoESo',
    durationMinutes: 15,
  ),
  ExerciseVideo(
    title: '20 Min Full Body Strength',
    youtubeId: 'UBMk30rjy0o',
    durationMinutes: 20,
  ),
  ExerciseVideo(
    title: '10 Min Yoga for Beginners',
    youtubeId: 'v7AYKMP6rOE',
    durationMinutes: 10,
  ),
  ExerciseVideo(
    title: '25 Min HIIT Cardio Blast',
    youtubeId: 'Mvo2snJGhtM',
    durationMinutes: 25,
  ),
  ExerciseVideo(
    title: '15 Min Leg Day Workout',
    youtubeId: 'UItWltVZZmE',
    durationMinutes: 15,
  ),
  ExerciseVideo(
    title: '20 Min Upper Body Workout',
    youtubeId: 'FBCnlKQbb6Y',
    durationMinutes: 20,
  ),
  ExerciseVideo(
    title: '12 Min Stretching Routine',
    youtubeId: 'sTANio_2E0Q',
    durationMinutes: 12,
  ),
];
