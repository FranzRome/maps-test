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
  final Completer<GoogleMapController> _controller = Completer();

  //late final GoogleMapController _controller;
  List<LatLng> coordinates = [
    const LatLng(45.038050, 7.636810),
    const LatLng(45.076099, 7.658133),
  ];
  double markerLatitude = 0;
  double markerLongitude = 0;
  double myLatitude = 0;
  double myLongitude = 0;
  loc.LocationData? currentLocation;
  BitmapDescriptor myPositionIcon = BitmapDescriptor.defaultMarker;

  final List<String> addresses = [
    //'Corso Cosenza 81, Torino',
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
    'Via Rieti, Pronda',
    'Via Mongolia, Settimo Torinese',
    'Via Frejus, Orbassano',
    /*'Strada del Drosso, Torino',
    'Via Moncenisio, Collegno',
    'Via Vagliè, Settimo Torinese',
    'Via Amendola, Nichelino',*/
  ];

  // Only 9/30 waypoints are shown in Maps
  final List<PolylineWayPoint> _waypoints = [];
  final Map<String, Marker> _markers = {};

  // Object for PolylinePoints
  late PolylinePoints polylinePoints;

// List of coordinates to join
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polyLines = {};
  late final CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _loadMyPositionIcon();

    initOriginDestination();
    fillMarkersFromAddresses(addresses);
    getCurrentLocation();

    for (String address in addresses) {
      _waypoints.add(PolylineWayPoint(location: address));
    }

    _initialCameraPosition = CameraPosition(
      //target: coordinates[0],
      target: _markers['origin']!.position,
      zoom: 15,
      tilt: 90,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          width: double.infinity,
          height: double.infinity,
          child: GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _initialCameraPosition,
            markers: Set<Marker>.of(_markers.values),
            /*FutureBuilder<Set<Marker>>(
              initialData: Set<Marker>(),
              future: markersFromAddresses(addresses),
              builder: (context, snapshot){
                return Set<Marker>.of(snapshot.data);
              },
            ),*/
            polylines: Set<Polyline>.of(polyLines.values),
            //onTap: (LatLng latLng) => setCurrentLocationMarker(latLng),
            onMapCreated: (GoogleMapController controller) {
              //_controller = controller;
              _controller.complete(controller);
              setState(() {
                /*  _createPolyLines(
                  coordinates[0].latitude,
                  coordinates[0].longitude,
                  coordinates[1].latitude,
                  coordinates[1].longitude,
                );*/
                _createPolyLines(
                  _markers['origin']!.position.latitude,
                  _markers['origin']!.position.longitude,
                  _markers['destination']!.position.latitude,
                  _markers['destination']!.position.longitude,
                );
              });
            },
          ),
        ),
        Positioned(
          right: 20,
          top: 10,
          child: currentLocationButton(),
        ),
        Positioned(
          left: 20,
          bottom: 30,
          child: openNavigationButton(),
        ),
      ]),
    );
  }

  Widget currentLocationButton() {
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
            getCurrentLocation();
          },
        ),
      ),
    );
  }

  Widget openNavigationButton() {
    return IconButton(
      icon: const Icon(Icons.navigation),
      color: Colors.blue.shade300,
      onPressed: () async {
        /* String origin =
            '${coordinates[0].latitude} ${coordinates[0].longitude}';
        String destination =
            '${coordinates[1].latitude} ${coordinates[1].longitude}';*/
        String origin = '${_markers['origin']!.position.latitude}'
            '${_markers['origin']!.position.longitude}';
        String destination = '${_markers['destination']!.position.latitude}'
            '${_markers['destination']!.position.longitude}';
        String mode = 'driving';
        String waypoints = '';

        for (PolylineWayPoint w in _waypoints) {
          waypoints += '${w.location}%7C';
        }
        waypoints.substring(0, waypoints.length - 3);

        await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api='
            '1&origin=$origin'
            '&destination=$destination'
            '&travelmode=$mode'
            '&waypoints=$waypoints'));
      },
    );
  }

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

  void setTapLocationMarker(LatLng latLng) {
    markerLatitude = latLng.latitude;
    markerLongitude = latLng.longitude;
    final marker = Marker(
      markerId: const MarkerId('myLocation'),
      position: LatLng(markerLatitude, markerLongitude),
      infoWindow: const InfoWindow(
        title: '',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
    });
  }

  void getCurrentLocation() async {
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
    myLatitude = currentPosition.latitude!;
    myLongitude = currentPosition.longitude!;
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
            target: LatLng(myLatitude, myLongitude),
            zoom: 18,
            tilt: 90.0,
          ),
        ),
      );
    });
  }

  void initOriginDestination() {
    _markers['origin'] = Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(
        coordinates[0].latitude,
        coordinates[0].longitude,
      ),
    );
    _markers['destination'] = Marker(
      markerId: const MarkerId('destination'),
      position: LatLng(
        coordinates[1].latitude,
        coordinates[1].longitude,
      ),
    );
  }

  void fillMarkersFromAddresses(List<String> addresses) async {
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

  Future<List<Marker>> markersFromAddresses(List<String> addresses) async {
    List<Marker> result = [];

    for (String address in addresses) {
      geo.Location loc = (await geo.locationFromAddress(address))[0];
      result.add(
        Marker(
          position: LatLng(
            loc.latitude,
            loc.longitude,
          ),
          markerId: MarkerId(address),
        ),
      );
    }

    return result;
  }

  /*List<Marker> markersFromFuture(Future<List<Marker>> markers){
    return markers;
  }*/

  void _createPolyLines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    /*_markers['origin'] = Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(startLatitude, startLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(90),
    );
    _markers['destination'] = Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(destinationLatitude, destinationLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(50),
    );*/

    polylinePoints = PolylinePoints();

    try {
      /*
       * Generating the list of coordinates to be
       * used for drawing the polyLines
       */
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        api.key, // Google Maps API Key
        PointLatLng(startLatitude, startLongitude),
        PointLatLng(destinationLatitude, destinationLongitude),
        wayPoints: _waypoints,
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
    } on Exception catch (e) {
      print('Exception: ${e.toString()}');
    }
    // Defining an ID
    PolylineId id = const PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue.shade300,
      points: polylineCoordinates,
      width: 6,
    );

    // Adding the polyline to the map and updating the UI
    setState(() {
      polyLines[id] = polyline;
    });
  }

  void _loadMyPositionIcon() {
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        devicePixelRatio: 20,
        size: Size(1, 1),
      ),
      'assets/images/person.png',
    ).then((icon) => {
          setState(() {
            myPositionIcon = icon;
          })
        });
  }
}
