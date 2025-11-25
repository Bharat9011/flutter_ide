// class ProjectModel {
//   final String name;
//   final String path;
//   final String? isCreated;
//   // final DateTime createdAt;

//   ProjectModel({
//     required this.name,
//     required this.path,
//     this.isCreated = "false",
//     // required this.createdAt,
//   });

//   Map<String, dynamic> toJson() => {
//     'name': name,
//     'path': path,
//     'isCreated': isCreated,
//     // 'createdAt': createdAt.toIso8601String(),
//   };

//   factory ProjectModel.fromJson(Map<String, dynamic> json) {
//     return ProjectModel(
//       name: json['name'],
//       path: json['path'],
//       isCreated: json['isCreated'],
//       // createdAt: DateTime.parse(json['createdAt']),
//     );
//   }
// }

class ProjectModel {
  final String name; // Project Name
  final String path; // Folder Path
  final String? isCreated; // "true" or "false"

  final String? platform; // Flutter / Dart
  final String? projectType; // Flutter App, Dart CLI, etc.

  ProjectModel({
    required this.name,
    required this.path,
    this.isCreated,
    this.platform,
    this.projectType,
  });

  // Convert Model → Map (optional, useful for saving to storage)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'isCreated': isCreated,
      'platform': platform,
      'projectType': projectType,
    };
  }

  // Convert Map → Model (optional)
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      name: map['name'],
      path: map['path'],
      isCreated: map['isCreated'],
      platform: map['platform'],
      projectType: map['projectType'],
    );
  }
}
