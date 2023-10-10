class FilterModel {
  String id;

  String name;

  List<dynamic> options;

  FilterModel({this.id = '', this.name = '', this.options = const []});

  factory FilterModel.fromJson(Map<String, dynamic> parsedJson) {
    return FilterModel(
      id: parsedJson['id'] ?? '',
      name: parsedJson['name'] ?? '',
      options: parsedJson['options'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'options': options,
    };
  }
}
