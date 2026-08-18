import 'package:equatable/equatable.dart';

import 'node_model.dart';

enum RouteMode { guidedWalk, quickPreview, freeRoam }
enum RouteStatus { idle, calculating, active, paused, completed, failed, wrongDirection }

class RouteStep extends Equatable {
  final String nodeId;
  final String? instruction;
  final double? bearingToNext;
  final double? distanceToNext;
  final int estimatedSeconds;

  const RouteStep({
    required this.nodeId,
    this.instruction,
    this.bearingToNext,
    this.distanceToNext,
    this.estimatedSeconds = 0,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      nodeId: json['nodeId'] as String,
      instruction: json['instruction'] as String?,
      bearingToNext: (json['bearingToNext'] as num?)?.toDouble(),
      distanceToNext: (json['distanceToNext'] as num?)?.toDouble(),
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'instruction': instruction,
      'bearingToNext': bearingToNext,
      'distanceToNext': distanceToNext,
      'estimatedSeconds': estimatedSeconds,
    };
  }

  @override
  List<Object?> get props => [nodeId, instruction, bearingToNext, distanceToNext, estimatedSeconds];
}

class RouteModel extends Equatable {
  final String id;
  final String name;
  final String startNodeId;
  final String endNodeId;
  final List<String> nodeIds;
  final List<NodeModel> nodes;
  final List<RouteStep> steps;
  final double totalDistance;
  final int estimatedTimeSeconds;
  final RouteMode mode;
  final RouteStatus status;
  final int currentStepIndex;
  final bool isWrongDirection;
  final String? errorMessage;

  const RouteModel({
    required this.id,
    this.name = '',
    required this.startNodeId,
    required this.endNodeId,
    this.nodeIds = const [],
    this.nodes = const [],
    this.steps = const [],
    this.totalDistance = 0,
    this.estimatedTimeSeconds = 0,
    this.mode = RouteMode.guidedWalk,
    this.status = RouteStatus.idle,
    this.currentStepIndex = 0,
    this.isWrongDirection = false,
    this.errorMessage,
  });

  RouteModel copyWith({
    String? id,
    String? name,
    String? startNodeId,
    String? endNodeId,
    List<String>? nodeIds,
    List<NodeModel>? nodes,
    List<RouteStep>? steps,
    double? totalDistance,
    int? estimatedTimeSeconds,
    RouteMode? mode,
    RouteStatus? status,
    int? currentStepIndex,
    bool? isWrongDirection,
    String? errorMessage,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startNodeId: startNodeId ?? this.startNodeId,
      endNodeId: endNodeId ?? this.endNodeId,
      nodeIds: nodeIds ?? this.nodeIds,
      nodes: nodes ?? this.nodes,
      steps: steps ?? this.steps,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedTimeSeconds: estimatedTimeSeconds ?? this.estimatedTimeSeconds,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isWrongDirection: isWrongDirection ?? this.isWrongDirection,
      errorMessage: errorMessage,
    );
  }

  bool get isCompleted => status == RouteStatus.completed;
  bool get isActive => status == RouteStatus.active;
  bool get hasError => status == RouteStatus.failed;
  bool get isIdle => status == RouteStatus.idle;
  bool get isPaused => status == RouteStatus.paused;
  bool get isWrong => status == RouteStatus.wrongDirection;
  bool get isGuided => mode == RouteMode.guidedWalk;
  bool get isQuick => mode == RouteMode.quickPreview;

  NodeModel? get currentNode =>
      nodes.isNotEmpty && currentStepIndex < nodes.length
          ? nodes[currentStepIndex]
          : null;

  NodeModel? get destinationNode => nodes.isNotEmpty ? nodes.last : null;

  RouteStep? get currentStep =>
      steps.isNotEmpty && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null;

  RouteStep? get nextStep {
    final nextIndex = currentStepIndex + 1;
    return nextIndex < steps.length ? steps[nextIndex] : null;
  }

  double get progress =>
      nodes.length > 1 ? currentStepIndex / (nodes.length - 1) : 0;

  int get remainingSteps => nodes.length - currentStepIndex - 1;

  String get progressText =>
      '${currentStepIndex + 1} / ${nodes.length}';

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      startNodeId: json['startNodeId'] as String,
      endNodeId: json['endNodeId'] as String,
      nodeIds: List<String>.from(json['nodeIds'] ?? []),
      nodes: (json['nodes'] as List?)
              ?.map((e) => NodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List?)
              ?.map((e) => RouteStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0,
      estimatedTimeSeconds: json['estimatedTimeSeconds'] as int? ?? 0,
      mode: RouteMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => RouteMode.guidedWalk,
      ),
      status: RouteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RouteStatus.idle,
      ),
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      isWrongDirection: json['isWrongDirection'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startNodeId': startNodeId,
      'endNodeId': endNodeId,
      'nodeIds': nodeIds,
      'nodes': nodes.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
      'totalDistance': totalDistance,
      'estimatedTimeSeconds': estimatedTimeSeconds,
      'mode': mode.name,
      'status': status.name,
      'currentStepIndex': currentStepIndex,
      'isWrongDirection': isWrongDirection,
      'errorMessage': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
        id, name, startNodeId, endNodeId, nodeIds, nodes, steps,
        totalDistance, estimatedTimeSeconds, mode, status,
        currentStepIndex, isWrongDirection, errorMessage,
      ];
}
