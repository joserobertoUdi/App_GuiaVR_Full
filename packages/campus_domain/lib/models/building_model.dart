import 'package:equatable/equatable.dart';

class BuildingModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> floorIds;
  final Map<String, dynamic>? metadata;

  const BuildingModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.latitude,
    required this.longitude,
    this.floorIds = const [],
    this.metadata,
  });

  bool get hasFloors => floorIds.isNotEmpty;

  BuildingModel copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    List<String>? floorIds,
    Map<String, dynamic>? metadata,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      floorIds: floorIds ?? this.floorIds,
      metadata: metadata ?? this.metadata,
    );
  }

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      floorIds: List<String>.from(json['floorIds'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'floorIds': floorIds,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, name, description, latitude, longitude, floorIds, metadata];
}