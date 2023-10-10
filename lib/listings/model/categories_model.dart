class CategoriesModel {
  String id;

  String order;

  String photo;

  String title;

  CategoriesModel(
      {this.id = '', this.order = '', this.photo = '', this.title = ''});

  factory CategoriesModel.fromJson(Map<String, dynamic> parsedJson) {
    return CategoriesModel(
        id: parsedJson['id'] ?? '',
        order: parsedJson['order'] ?? '',
        photo: parsedJson['photo'] ?? '',
        title: parsedJson['title'] ?? parsedJson['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'order': order, 'photo': photo, 'title': title};
  }
}
