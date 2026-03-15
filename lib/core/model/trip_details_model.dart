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
  final String? tripId;

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
    this.tripId,
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
    'trip_id': tripId,
  };

  factory TripDetailsModel.fromJson(Map<String, dynamic> json) =>
      TripDetailsModel(
        id: json['id'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp']),
        speed: (json['speed'] as num? ?? 0.0).toDouble(),
        heading: (json['heading'] as num? ?? 0.0).toDouble(),
        accuracy: (json['accuracy'] as num? ?? 0.0).toDouble(),
        altitude: (json['altitude'] as num? ?? 0.0).toDouble(),
        distanceTraveled: (json['distance_traveled'] as num? ?? 0.0).toDouble(),
        country: json['country'],
        street: json['street'],
        acceleration: (json['acceleration'] as num? ?? 0.0).toDouble(),
        destination: json['destination'],
        remainingDistance: (json['remaining_distance'] as num?)?.toDouble(),
        totalDistance: (json['total_distance'] as num?)?.toDouble(),
        totalDuration: (json['total_duration'] as num?)?.toDouble(),
        destinationLatitude: (json['destination_latitude'] as num?)?.toDouble(),
        destinationLongitude: (json['destination_longitude'] as num?)?.toDouble(),
        tripId: json['trip_id'],
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
    String? tripId,
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
      tripId: tripId ?? this.tripId,
    );
  }
}
