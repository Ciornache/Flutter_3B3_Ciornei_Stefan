class Venue {
  final int id;
  final String name;
  final String city;
  final String country;

  Venue({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      country: json['country'],
    );
  }
}