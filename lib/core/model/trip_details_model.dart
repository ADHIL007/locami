class TripDetailsModel {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;
  final double heading;
  final double accuracy;
  final double altitude;
  final double? distanceTraveled;
  final String? country;
  final String? street;
  final double? acceleration;
  final String? destination;
  final double? remainingDistance;
  final double? totalDistance;
  final double? totalDuration;
  final double? destinationLatitude;
  final double? destinationLongitude;

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
    this.remainingDistance,
    this.totalDistance,
    this.totalDuration,
    this.destinationLatitude,
    this.destinationLongitude,
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
    'remaining_distance': remainingDistance,
    'total_distance': totalDistance,
    'total_duration': totalDuration,
    'destination_latitude': destinationLatitude,
    'destination_longitude': destinationLongitude,
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
        remainingDistance: json['remaining_distance'],
        totalDistance: json['total_distance'],
        totalDuration: json['total_duration'],
        destinationLatitude: json['destination_latitude'],
        destinationLongitude: json['destination_longitude'],
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
    double? remainingDistance,
    double? totalDistance,
    double? totalDuration,
    double? destinationLatitude,
    double? destinationLongitude,
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
      remainingDistance: remainingDistance ?? this.remainingDistance,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
    );
  }
}
