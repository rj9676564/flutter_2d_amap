class InfoWindow {
  const InfoWindow({
    this.title,
    this.snippet,
  });

  /// The title of the info window.
  final String? title;

  /// The snippet of the info window.
  final String? snippet;

  static const InfoWindow noText = InfoWindow();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is InfoWindow &&
        title == other.title &&
        snippet == other.snippet;
  }

  @override
  int get hashCode => Object.hash(title, snippet);
}
