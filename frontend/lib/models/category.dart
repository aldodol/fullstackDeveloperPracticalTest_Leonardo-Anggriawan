class Category {
  final int id;
  final String code;
  final String name;
  final String? description;
  final int totalMaterials;

  Category({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.totalMaterials = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      totalMaterials: json['total_materials'] != null
          ? int.tryParse(json['total_materials'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
  };
}
