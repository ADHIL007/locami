class TripDetailsModel {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;
  final double heading;
  final double accuracy;
  final double altitude;
  final double?
  distanceTraveled; // Distance from previous point or cumulative? usually cumulative for a trip segment or delta. Let's store cumulative.
  final String? country;
  final String? street;
  final double? acceleration;
  final String? destination;

  const TripDetailsModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0.0,
    this.heading = 0.0,
    this.accuracy = 0.0,
    this.altitude = 0.0,
    this.distanceTraveled = 0.0,
    this.country,
    this.street,
    this.acceleration = 0.0,
    this.destination,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'altitude': altitude,
    'distance_traveled': distanceTraveled,
    'country': country,
    'street': street,
    'acceleration': acceleration,
    'destination': destination,
  };

  factory TripDetailsModel.fromJson(Map<String, dynamic> json) =>
      TripDetailsModel(
        id: json['id'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        timestamp: DateTime.parse(json['timestamp']),
        speed: json['speed'] ?? 0.0,
        heading: json['heading'] ?? 0.0,
        accuracy: json['accuracy'] ?? 0.0,
        altitude: json['altitude'] ?? 0.0,
        distanceTraveled: json['distance_traveled'] ?? 0.0,
        country: json['country'],
        street: json['street'],
        acceleration: json['acceleration'] ?? 0.0,
        destination: json['destination'],
      );

  TripDetailsModel copyWith({
    int? id,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? heading,
    double? accuracy,
    double? altitude,
    double? distanceTraveled,
    String? country,
    String? street,
    double? acceleration,
    String? destination,
  }) {
    return TripDetailsModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      country: country ?? this.country,
      street: street ?? this.street,
      acceleration: acceleration ?? this.acceleration,
      destination: destination ?? this.destination,
    );
  }
}
