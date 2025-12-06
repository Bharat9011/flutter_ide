class ProjectModel {
  final String name;
  final String path;
  final String? isCreated;

  final String? platform;
  final String? projectType;

  ProjectModel({
    required this.name,
    required this.path,
    this.isCreated,
    this.platform,
    this.projectType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'isCreated': isCreated,
      'platform': platform,
      'projectType': projectType,
    };
  }

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
