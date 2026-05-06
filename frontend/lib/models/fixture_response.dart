import 'fixture.dart';

class FixtureResponse {
  final int total;
  final int totalPages;
  final int page;
  final List<Fixture> fixtures;

  FixtureResponse({
    required this.total,
    required this.totalPages,
    required this.page,
    required this.fixtures,
  });

  factory FixtureResponse.fromJson(Map<String, dynamic> j) {
    final raw = j['fixtures'];
    final fixtures = raw is List
        ? raw.cast<Map<String, dynamic>>().map(Fixture.fromJson).toList()
        : const <Fixture>[];
    return FixtureResponse(
      total: j['total'] as int,
      totalPages: j['totalPages'] as int,
      page: j['page'] as int,
      fixtures: fixtures,
    );
  }
}
