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
  /*final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();*/
  late final GoogleMapController _controller;
  double latitude = 0;
  double longitude = 0;
  List<LatLng> coordinates = [
    const LatLng(45.038050, 7.636810),
    const LatLng(45.076099, 7.658133),
  ];

  // Only 9/30 waypoints are shown in Maps
  final List<PolylineWayPoint> _waypoints = [
    PolylineWayPoint(location: 'Piazza Castello, Torino'),
    PolylineWayPoint(location: 'Le Gru, Grugliasco'),
    PolylineWayPoint(location: 'Mole Antonelliana'),
    PolylineWayPoint(location: 'Piazza Statuto, Torino'),
    PolylineWayPoint(location: 'Porta Susa, Torino'),
    PolylineWayPoint(location: 'Palazzo Reale di Torino'),
    PolylineWayPoint(location: 'Museo Egizio'),
    PolylineWayPoint(location: 'Piazza Castello'),
    PolylineWayPoint(location: 'Parco del Valentino'),
    PolylineWayPoint(location: 'Basilica di Superga'),
    PolylineWayPoint(location: 'Reggia di Venaria Reale'),
    PolylineWayPoint(location: 'Parco della Mandria'),
    PolylineWayPoint(location: 'Museo Nazionale dell\'Automobile'),
    PolylineWayPoint(location: 'Giardini Reali'),
    PolylineWayPoint(location: 'Museo del Cinema'),
    PolylineWayPoint(location: 'Palazzo Madama'),
    PolylineWayPoint(location: 'Borgo Medievale'),
    PolylineWayPoint(location: 'Villa della Regina'),
    PolylineWayPoint(location: 'Parco Stupinigi'),
    PolylineWayPoint(location: 'Galleria Sabauda'),
    PolylineWayPoint(location: 'Palazzo Carignano'),
    PolylineWayPoint(location: 'Museo della Frutta'),
    PolylineWayPoint(location: 'Chiesa della Gran Madre di Dio'),
    PolylineWayPoint(location: 'Mercato di Porta Palazzo'),
    PolylineWayPoint(location: 'Palazzo Cavour'),
    PolylineWayPoint(location: 'Giardino Botanico Reale'),
    PolylineWayPoint(location: 'Piazza Vittorio Veneto'),
    PolylineWayPoint(location: 'Monte dei Cappuccini'),
    PolylineWayPoint(location: 'Piazza Pitagora, Torino'),
    PolylineWayPoint(location: 'Santuario di Maria Ausiliatrice'),
  ];

  // Object for PolylinePoints
  late PolylinePoints polylinePoints;

// List of coordinates to join
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polyLines = {};
  final Map<String, Marker> _markers = {};
  late final CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    //getCurrentLocation();
    _initialCameraPosition = CameraPosition(
      target: coordinates[0],
      zoom: 15,
      tilt: 90,
    );
    _createPolyLines(latitude, longitude,
        coordinates[1].latitude, coordinates[1].longitude);
    //print(Set<Polyline>.of(polyLines.values));
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
            markers: _markers.values.toSet(),
            polylines: Set<Polyline>.of(polyLines.values),
            onTap: (LatLng latLng) {
              latitude = latLng.latitude;
              longitude = latLng.longitude;
              final marker = Marker(
                markerId: const MarkerId('myLocation'),
                position: LatLng(latitude, longitude),
                infoWindow: const InfoWindow(
                  title: '',
                ),
              );
              setState(() {
                _markers['myLocation'] = marker;
              });
            },
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              setState(() {
                _createPolyLines(
                    coordinates[0].latitude,
                    coordinates[0].longitude,
                    coordinates[1].latitude,
                    coordinates[1].longitude);
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
          bottom: 10,
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
        String origin = '${coordinates[0].latitude} ${coordinates[0].longitude}';
        String destination = '${coordinates[1].latitude} ${coordinates[1].longitude}';
        String mode = 'driving';
        String waypoints = '';

        for(PolylineWayPoint w in _waypoints) {
          waypoints += '${w.location}%7C';
        }
        waypoints.substring(0, waypoints.length-3);

        await launchUrl(Uri.parse(
          'https://www.google.com/maps/dir/?api='
              '1&origin=$origin'
              '&destination=$destination'
              '&travelmode=$mode'
              '&waypoints=$waypoints'
        ));
      },
    );
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
    latitude = currentPosition.latitude!;
    longitude = currentPosition.longitude!;
    final marker = Marker(
      markerId: const MarkerId('myLocation'),
      position: LatLng(latitude, longitude),
      infoWindow: const InfoWindow(
        title: 'you can add any message here',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
      _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(latitude, longitude), zoom: 18, tilt: 90.0),
        ),
      );
    });
  }

  Future<List<geo.Location>> addressToLocation(String address) {
    //List<geo.Location> result;
    //geo.locationFromAddress(address).then((value) => result = value);
    return geo.locationFromAddress(address);
  }

  void _createPolyLines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    _markers['A'] = Marker(
      markerId: const MarkerId('A'),
      position: LatLng(startLatitude, startLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(90),
    );
    _markers['B'] = Marker(
      markerId: const MarkerId('B'),
      position: LatLng(destinationLatitude, destinationLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(50),
    );

    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();

    /*
    Generating the list of coordinates to be
    used for drawing the polyLines
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
      for (final (index, point) in result.points.indexed) {
        polylineCoordinates.add(LatLng(point.latitude,
          point.longitude,));
        // Create a marker
        /*String i = index.toString();
        _markers[i] = Marker(
          markerId: MarkerId(i),
          position: LatLng(point.latitude, point.longitude),
        );*/
      }
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

    // Adding the polyline to the map
    setState(() {
      polyLines[id] = polyline;
    });
  }
}
