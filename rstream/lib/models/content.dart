import 'package:flutter/foundation.dart';

abstract class Content {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final List<String> categories;
  final double rating;
  final int viewCount;
  final DateTime addedAt;
  final ContentType type;

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.categories,
    required this.rating,
    required this.viewCount,
    required this.addedAt,
    required this.type,
  });

  Map<String, dynamic> toJson();
}

class Movie extends Content {
  final String streamUrl;
  final Duration duration;
  final int releaseYear;
  final List<String> cast;
  final String director;
  final String? trailerUrl;
  final bool isHD;

  Movie({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    required super.categories,
    required super.rating,
    required super.viewCount,
    required super.addedAt,
    required this.streamUrl,
    required this.duration,
    required this.releaseYear,
    required this.cast,
    required this.director,
    this.trailerUrl,
    this.isHD = true,
  }) : super(type: ContentType.movie);

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      categories: List<String>.from(json['categories'] as List),
      rating: (json['rating'] as num).toDouble(),
      viewCount: json['view_count'] as int,
      addedAt: DateTime.parse(json['added_at'] as String),
      streamUrl: json['stream_url'] as String,
      duration: Duration(seconds: json['duration'] as int),
      releaseYear: json['release_year'] as int,
      cast: List<String>.from(json['cast'] as List),
      director: json['director'] as String,
      trailerUrl: json['trailer_url'] as String?,
      isHD: json['is_hd'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'categories': categories,
      'rating': rating,
      'view_count': viewCount,
      'added_at': addedAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'stream_url': streamUrl,
      'duration': duration.inSeconds,
      'release_year': releaseYear,
      'cast': cast,
      'director': director,
      'trailer_url': trailerUrl,
      'is_hd': isHD,
    };
  }
}

class Series extends Content {
  final List<Season> seasons;
  final bool isComplete;
  final String? trailerUrl;
  final bool isHD;

  Series({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    required super.categories,
    required super.rating,
    required super.viewCount,
    required super.addedAt,
    required this.seasons,
    required this.isComplete,
    this.trailerUrl,
    this.isHD = true,
  }) : super(type: ContentType.series);

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      categories: List<String>.from(json['categories'] as List),
      rating: (json['rating'] as num).toDouble(),
      viewCount: json['view_count'] as int,
      addedAt: DateTime.parse(json['added_at'] as String),
      seasons: (json['seasons'] as List)
          .map((season) => Season.fromJson(season as Map<String, dynamic>))
          .toList(),
      isComplete: json['is_complete'] as bool,
      trailerUrl: json['trailer_url'] as String?,
      isHD: json['is_hd'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'categories': categories,
      'rating': rating,
      'view_count': viewCount,
      'added_at': addedAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'seasons': seasons.map((season) => season.toJson()).toList(),
      'is_complete': isComplete,
      'trailer_url': trailerUrl,
      'is_hd': isHD,
    };
  }
}

class Season {
  final String id;
  final int number;
  final List<Episode> episodes;
  final String? description;

  Season({
    required this.id,
    required this.number,
    required this.episodes,
    this.description,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      number: json['number'] as int,
      episodes: (json['episodes'] as List)
          .map((episode) => Episode.fromJson(episode as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'episodes': episodes.map((episode) => episode.toJson()).toList(),
      'description': description,
    };
  }
}

class Episode {
  final String id;
  final String title;
  final int number;
  final String streamUrl;
  final Duration duration;
  final String? thumbnail;
  final String? description;

  Episode({
    required this.id,
    required this.title,
    required this.number,
    required this.streamUrl,
    required this.duration,
    this.thumbnail,
    this.description,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as String,
      title: json['title'] as String,
      number: json['number'] as int,
      streamUrl: json['stream_url'] as String,
      duration: Duration(seconds: json['duration'] as int),
      thumbnail: json['thumbnail'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'number': number,
      'stream_url': streamUrl,
      'duration': duration.inSeconds,
      'thumbnail': thumbnail,
      'description': description,
    };
  }
}

class Channel extends Content {
  final String streamUrl;
  final bool isLive;
  final String? epgId;
  final Map<String, dynamic>? currentProgram;
  final bool isHD;

  Channel({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    required super.categories,
    required super.rating,
    required super.viewCount,
    required super.addedAt,
    required this.streamUrl,
    required this.isLive,
    this.epgId,
    this.currentProgram,
    this.isHD = true,
  }) : super(type: ContentType.channel);

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      categories: List<String>.from(json['categories'] as List),
      rating: (json['rating'] as num).toDouble(),
      viewCount: json['view_count'] as int,
      addedAt: DateTime.parse(json['added_at'] as String),
      streamUrl: json['stream_url'] as String,
      isLive: json['is_live'] as bool,
      epgId: json['epg_id'] as String?,
      currentProgram: json['current_program'] as Map<String, dynamic>?,
      isHD: json['is_hd'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'categories': categories,
      'rating': rating,
      'view_count': viewCount,
      'added_at': addedAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'stream_url': streamUrl,
      'is_live': isLive,
      'epg_id': epgId,
      'current_program': currentProgram,
      'is_hd': isHD,
    };
  }
}

enum ContentType {
  movie,
  series,
  channel,
}
