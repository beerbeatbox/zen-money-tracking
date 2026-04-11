enum BottomNavStyle {
  floating,
  standard;

  String toJson() => name;

  static BottomNavStyle fromJson(String? json) {
    if (json == null) return BottomNavStyle.floating;
    return BottomNavStyle.values.firstWhere(
      (e) => e.name == json,
      orElse: () => BottomNavStyle.floating,
    );
  }
}
