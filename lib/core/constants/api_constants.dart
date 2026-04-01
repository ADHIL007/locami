class ApiConstants {
  // Map Basemaps
  static const String esriSatelliteUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  
  static const String cartoDbDarkUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String cartoDbLightUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String cartoDbLabelsUrl = 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png';

  // APIs
  static const String photonSearchDomain = 'photon.komoot.io';
  static const String photonSearchPath = '/api/';
  static const String nominatimDomain = 'nominatim.openstreetmap.org';
  static const String nominatimSearchPath = '/search';
  static const String osrmRouteUrl = 'https://router.project-osrm.org/route/v1/';
}
