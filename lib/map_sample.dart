import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:maps_test/maps_api.dart' as api;

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
  List<String> addresses = [
    'Piazza Pitagora',
    'Piazza Statuto',
    'Le Gru',
    'Piazza Castello',
    'Porta Susa'
  ];
  late List<geo.Location> locations;
  List<LatLng> coordinates = [
    const LatLng(45.038050, 7.636810),
    const LatLng(45.076099, 7.658133),
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
    _createPolyLines(
        coordinates[0].latitude, coordinates[0].longitude,
        coordinates[1].latitude, coordinates[1].longitude
    );
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
            onTap: (LatLng latlng) {
              latitude = latlng.latitude;
              longitude = latlng.longitude;
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
                    coordinates[0].latitude, coordinates[0].longitude,
                    coordinates[1].latitude, coordinates[1].longitude
                );
              });
            },
          ),
        ),
        Positioned(
          left: 20,
          bottom: 10,
          child: currentLocationButton(),
        ),
      ]),
    );
  }

  Widget currentLocationButton() {
    return ClipOval(
      child: Material(
        color: Colors.orange.shade100, // button color
        child: InkWell(
          splashColor: Colors.orange, // inkwell color
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
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(latitude, longitude), zoom: 18, tilt: 90.0),
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
    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for
    // drawing the polyLines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      api.key, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      print('Found ${result.points.length} points');
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print('Points Empty');
    }

    // Defining an ID
    PolylineId id = const PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    polyLines[id] = polyline;
  }
}
