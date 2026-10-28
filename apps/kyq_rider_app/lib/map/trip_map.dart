import 'package:flutter/widgets.dart';
import 'package:kyq_api/kyq_api.dart';

import 'maplibre_trip_map.dart';

/// Puntos que pinta el mapa: origen, destino y posición del conductor.
class TripMapMarkers {
  const TripMapMarkers({this.pickup, this.dropoff, this.driver, this.driverHeading, this.golden = const []});

  final GeoPoint? pickup;
  final GeoPoint? dropoff;
  final GeoPoint? driver;

  /// 010: rumbo del vehículo en grados (0 = norte) para girar su flecha.
  final double? driverHeading;

  /// 010: pines dorados de los Conductores Elegidos libres en su zona aproximada (FR-018).
  final List<GeoPoint> golden;
}

/// Construye el mapa. Las pruebas lo sustituyen porque MapLibre no se puede pintar en ellas.
typedef TripMapBuilder = Widget Function(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap);

/// Mapa real con MapLibre.
Widget maplibreTripMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) =>
    MaplibreTripMap(markers: markers, onTap: onTap);
