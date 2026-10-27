/// Ruta de la pantalla del viaje. El nombre del conductor viaja en la URL porque el viaje no lo trae.
String tripLocation(String tripId, String driverName) =>
    Uri(path: '/trip/$tripId', queryParameters: {'name': driverName}).toString();
