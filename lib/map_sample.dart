import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:maps_test/maps_api.dart' as api;
import 'package:url_launcher/url_Launcher.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  //region Fields

  final Completer<GoogleMapController> _controller = Completer();
  double _markerLatitude = 0;
  double _markerLongitude = 0;
  double _myLatitude = 0;
  double _myLongitude = 0;
  loc.LocationData? currentLocation;
  BitmapDescriptor _myPositionIcon = BitmapDescriptor.defaultMarker;

  final List<String> _addresses = [
    'Corso Cosenza 81, Torino',
    'Piazza Castello, Torino',
    'Le Gru, Grugliasco',
    'Mole Antonelliana, Torino',
    'Piazza Statuto, Torino',
    'Porta Susa, Torino',
    'Palazzo Reale, Torino',
    'Museo Egizio, Torino',
    'Piazza Castello, Torino',
    'Parco del Valentino, Torino',
    'Basilica di Superga, Superga',
    'Via Roma, Pino Torinese',
    'Via Costi, Pecetto Torinese',
    'Museo Nazionale dell\'Automobile, Torino',
    'Corso Piemonte, Settimo Torinese',
    'Parco Boschetto, Torino',
    'Via Sant\'Agnese, Candiolo',
    'Via Baretti, Moncaliri'
        'Via Piave, Pianezza',
    'Via Sandro Pertini, Tagliaferro',
    'Via Cuneo, Nichelino',
    'Via Montenero, Moncalieri',
    'Via Andrea Costa, Collegno',
    'Via Meucci, Reisina',
    //'Via Rieti, Pronda',
    //'Via Mongolia, Settimo Torinese',
    //'Via Frejus, Orbassano',
    /*'Strada del Drosso, Torino',
    'Via Moncenisio, Collegno',
    'Via Vagliè, Settimo Torinese',
    'Via Amendola, Nichelino',*/
  ];

  late PolylinePoints polylinePoints;

  final Map<String, Marker> _markers = {};
  final List<LatLng> _originDestination = [
    const LatLng(45.038050, 7.636810),
    const LatLng(45.076099, 7.658133),
  ];
  final Map<String, PolylineWayPoint> _waypoints = {};
  final Map<PolylineId, Polyline> _polyLines = {};
  late final CameraPosition _initialCameraPosition;

  //endregion

  //region Init

  @override
  void initState() {
    super.initState();
    _initPolylinePoints();
    _initOriginDestination();
    _fillMarkersFromAddresses(_addresses);
    _createWaypoints(_addresses);
    _createPolyLines(
      _originDestination[0].latitude,
      _originDestination[0].longitude,
      _originDestination[1].latitude,
      _originDestination[1].longitude,
      _waypoints,
    );
    _loadMyPositionIcon();
    _getCurrentLocation();
    _initialCameraPosition = CameraPosition(
      target: _originDestination[0],
      tilt: 90,
      zoom: 18,
      bearing: 0,
    );
  }

  //endregion

  //region Widgets

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _initialCameraPosition,
            markers: Set<Marker>.of(_markers.values),
            //Set<Marker>.of(_markers.values),
            polylines: Set<Polyline>.of(_polyLines.values),
            //onTap: (LatLng latLng) => setCurrentLocationMarker(latLng),
            onMapCreated: (GoogleMapController controller) {
              //_controller = controller;
              _controller.complete(controller);
              setState(() {
                /*_createPolyLines(
                        _markers['origin']!.position.latitude,
                        _markers['origin']!.position.longitude,
                        _markers['destination']!.position.latitude,
                        _markers['destination']!.position.longitude,
                        _waypointsFromAddresses(_addresses),
                      );*/
                _createPolyLines(
                  _originDestination[0].latitude,
                  _originDestination[0].longitude,
                  _originDestination[1].latitude,
                  _originDestination[1].longitude,
                  _waypointsFromAddresses(_addresses),
                );
              });
            },
            onTap: (latlng) {
              setState(() {

            });
            },
          ),
          Positioned(
            right: 20,
            top: 10,
            child: _currentLocationButton(),
          ),
          /*Positioned(
              left: 20,
              bottom: 30,
              child: _openNavigationButton(),
            ),*/
        ]),
    );
  }

  Widget _currentLocationButton() {
    return ClipOval(
      child: Material(
        color: Colors.blue.shade100, // button color
        child: InkWell(
          splashColor: Colors.blue, // inkwell color
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.my_location),
          ),
          onTap: () {
            _getCurrentLocation();
          },
        ),
      ),
    );
  }

  Widget _openNavigationButton(Map<String, PolylineWayPoint> waypoints) {
    return IconButton(
      icon: const Icon(Icons.navigation),
      color: Colors.blue.shade300,
      onPressed: () async {
        /* String origin =
            '${coordinates[0].latitude} ${coordinates[0].longitude}';
        String destination =
            '${coordinates[1].latitude} ${coordinates[1].longitude}';*/
        String origin =
            '${_markers['origin']!.position.latitude} ${_markers['origin']!
            .position.longitude}';
        String destination =
            '${_markers['destination']!.position
            .latitude} ${_markers['destination']!.position.longitude}';
        String mode = 'driving';
        String wp = '';

        for (PolylineWayPoint w in waypoints.values) {
          wp += '${w.location}%7C';
        }
        wp = wp.substring(0, waypoints.length - 3);

        await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api='
            '1&origin=$origin'
            '&destination=$destination'
            '&travelmode=$mode'
            '&waypoints=$waypoints'));
      },
    );
  }

  //endregion

  /*void getCurrentLocation() async {
    loc.Location location = loc.Location();
    location.getLocation().then(
          (location) {
        currentLocation = location;
      },
    );
    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen(
          (newLoc) {
        currentLocation = newLoc;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 13.5,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
        setState(() {});
      },
    );
  }*/

  //region Utilities

  void _initPolylinePoints() {
    polylinePoints = PolylinePoints();
  }

  Stream<Object> _getInformations() {
    late final StreamController<Object> controller;
    controller = StreamController<Object>(
      onListen: () async {
        Map<String, Marker> markers = await _markersFromAddresses(_addresses);
        controller.add(markers);

        LatLng origin = markers['origin']!.position,
            destination = markers['destination']!.position;
        Map<String, PolylineWayPoint> waypoints =
        _waypointsFromAddresses(_addresses);
        Polyline polyline = await _getPolyline(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
          waypoints,
        );
        controller.add(waypoints);

        await controller.close();
      },
    );
    return controller.stream;
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await loc.Location.instance.serviceEnabled();
    if (!serviceEnabled) {
      //check if the location service was enable or not
      serviceEnabled = await loc.Location.instance.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await loc.Location.instance.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await loc.Location.instance.requestPermission();
//if the location was denied it will ask next time the user enter the screen
      if (permissionGranted != loc.PermissionStatus.granted) {
//in case of denied you can add any thing here like error message or something else
        return;
      }
    }

    loc.LocationData currentPosition =
    await loc.Location.instance.getLocation();
    _myLatitude = currentPosition.latitude!;
    _myLongitude = currentPosition.longitude!;
    /*final marker = Marker(
      icon: myPositionIcon,
      markerId: const MarkerId('myLocation'),
      position: LatLng(myLatitude, myLongitude),
      infoWindow: const InfoWindow(
        title: 'Your location',
      ),
    );
    _markers['myLocation'] = marker;*/
    GoogleMapController googleMapController = await _controller.future;
    setState(() {
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_myLatitude, _myLongitude),
            zoom: 18,
            tilt: 90.0,
          ),
        ),
      );
    });
  }

  void _initOriginDestination() {
    _markers['origin'] = Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(
        _originDestination[0].latitude,
        _originDestination[0].longitude,
      ),
    );
    _markers['destination'] = Marker(
      markerId: const MarkerId('destination'),
      position: LatLng(
        _originDestination[1].latitude,
        _originDestination[1].longitude,
      ),
    );
  }

  void _fillMarkersFromAddresses(List<String> addresses) async {
    for (String address in addresses) {
      geo.Location loc = (await geo.locationFromAddress(address))[0];
      _markers[address] = Marker(
        position: LatLng(
          loc.latitude,
          loc.longitude,
        ),
        markerId: MarkerId(address),
      );
    }
  }

  void _setTapLocationMarker(LatLng latLng) {
    _markerLatitude = latLng.latitude;
    _markerLongitude = latLng.longitude;
    final marker = Marker(
      markerId: const MarkerId('myLocation'),
      position: LatLng(_markerLatitude, _markerLongitude),
      infoWindow: const InfoWindow(
        title: '',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
    });
  }

  void _createWaypoints(List<String> addresses) {
    for (var e in addresses) {
      _waypoints[e] = PolylineWayPoint(location: e);
    }
  }

  Map<String, PolylineWayPoint> _waypointsFromAddresses(
      List<String> addresses) {
    Map<String, PolylineWayPoint> result = {};

    for (var e in addresses) {
      result[e] = PolylineWayPoint(location: e);
    }

    return result;
  }

  Future<Map<String, Marker>> _markersFromAddresses(
      List<String> addresses) async {
    Map<String, Marker> result = {};

    for (final (int index, String address) in addresses.indexed) {
      geo.Location loc = (await geo.locationFromAddress(address))[0];
      String key = (index == addresses.length - 1
          ? 'destination'
          : (index == 0 ? 'origin' : address));
      result[key] = Marker(
        markerId: MarkerId(key),
        position: LatLng(
          loc.latitude,
          loc.longitude,
        ),
      );
    }

    return result;
  }

  /*List<Marker> markersFromFuture(Future<List<Marker>> markers){
    return markers;
  }*/


  Future<Polyline> _getPolyline(double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      Map<String, PolylineWayPoint> waypoints,) async {
    List<LatLng> polylineCoordinates = [];

    /*
       * Generating the list of coordinates to be
       * used for drawing the polyLines
       */
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      api.key, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      wayPoints: List<PolylineWayPoint>.of(waypoints.values),
      travelMode: TravelMode.driving,
      optimizeWaypoints: true,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      for (final PointLatLng point in result.points) {
        polylineCoordinates.add(LatLng(
          point.latitude,
          point.longitude,
        ));
      }
    }

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: const PolylineId('poly'),
      color: Colors.blue.shade300,
      points: polylineCoordinates,
      width: 6,
    );

    return polyline;
  }

  void _createPolyLines(double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      Map<String, PolylineWayPoint> waypoints,) async {
    List<LatLng> polylineCoordinates = [];

    /*
       * Generating the list of coordinates to be
       * used for drawing the polyLines
       */
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      api.key, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      wayPoints: List<PolylineWayPoint>.of(waypoints.values),
      travelMode: TravelMode.driving,
      optimizeWaypoints: true,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      for (final PointLatLng point in result.points) {
        polylineCoordinates.add(LatLng(
          point.latitude,
          point.longitude,
        ));
      }
    }

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: const PolylineId('poly'),
      color: Colors.blue.shade300,
      points: polylineCoordinates,
      width: 6,
    );

    // Adding the polyline to the map and updating the UI
    setState(() {
      _polyLines[polyline.mapsId] = polyline;
    });
  }

  void _loadMyPositionIcon() {
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        devicePixelRatio: 20,
        size: Size(1, 1),
      ),
      'assets/images/person.png',
    ).then((icon) =>
    {
      setState(() {
        _myPositionIcon = icon;
      })
    });
  }

//endregion

}
