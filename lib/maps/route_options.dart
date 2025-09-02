class RouteOption {
  final String duration;
  final String summary;
  final bool isFastest;

  RouteOption({
    required this.duration,
    required this.summary,
    this.isFastest = false,
  });
}
