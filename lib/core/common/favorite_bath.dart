class FavoriteBath {
  final String value;

  const FavoriteBath._(this.value);

  static const FavoriteBath option1 = FavoriteBath._('ducky');
  static const FavoriteBath option2 = FavoriteBath._('concert');
  static const FavoriteBath option3 = FavoriteBath._('gym');

  FavoriteBath.custom(String customValue) : value = customValue;

  @override
  String toString() => value;
}
