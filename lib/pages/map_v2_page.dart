import 'package:flutter/material.dart';
import 'package:flutter_gmaps/models/gmap_types.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapV2Page extends StatefulWidget {
  const MapV2Page({Key? key}) : super(key: key);

  @override
  State<MapV2Page> createState() => _MapV2PageState();
}

class _MapV2PageState extends State<MapV2Page> {
  var mapType = MapType.normal;

  double latitude = -7.764742717059524;
  double longitude = 109.41236584261921;

  Position? devicePosition;

  late GoogleMapController _controller;

  String? addrress;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GMAPS V2",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          PopupMenuButton(
              onSelected: onSelectedMapType,
              itemBuilder: (context) => gmapTypes
                  .map((type) => PopupMenuItem(
                        value: type.title,
                        child: Text(type.title),
                      ))
                  .toList())
        ],
      ),
      body: Stack(children: [_buildMaps(), _buildSearchCard()]),
    );
  }

  void onSelectedMapType(String value) {
    setState(() {
      switch (value) {
        case "Normal":
          mapType = MapType.normal;
          break;
        case "Hybrid":
          mapType = MapType.hybrid;
          break;
        case "Terrain":
          mapType = MapType.terrain;
          break;
        case "Satellite":
          mapType = MapType.satellite;
          break;
      }
    });
  }

  _buildMaps() => GoogleMap(
        mapType: mapType,
        initialCameraPosition:
            CameraPosition(target: LatLng(latitude, longitude), zoom: 17),
        myLocationEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      );

  _buildSearchCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          child: Column(children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 4),
              child: TextField(
                decoration: InputDecoration(
                    hintText: 'Masukkan alamat...',
                    contentPadding: const EdgeInsets.only(top: 15, left: 15),
                    suffixIcon: IconButton(
                      onPressed: () {
                        searchLocation();
                      },
                      icon: const Icon(Icons.search),
                    )),
                onChanged: (value) {
                  addrress = value;
                },
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  getLocation().then((value) {
                    setState(() {
                      devicePosition = value;
                    });

                    final deviceLat = devicePosition?.latitude;
                    final deviceLng = devicePosition?.longitude;

                    final cameraPosition = CameraPosition(
                        target: LatLng(deviceLat!, deviceLng!), zoom: 17);
                    final camearaUpdate =
                        CameraUpdate.newCameraPosition(cameraPosition);
                    _controller.animateCamera(camearaUpdate);
                  });
                },
                child: const Text("Get My Location")),
            const SizedBox(
              height: 8,
            ),
            devicePosition == null
                ? const Text("Lokasi belum terdeteksi")
                : Text(
                    "Latitude: ${devicePosition?.latitude} and Longitude: ${devicePosition?.longitude}")
          ]),
        ),
      ),
    );
  }

  Future requestPermission() async {
    await Permission.location.request();
  }

  Future<Position?> getLocation() async {
    Position? currentPosition;

    try {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentPosition = null;
      rethrow;
    }

    return currentPosition;
  }

  Future searchLocation() async {
    try {
      await GeocodingPlatform.instance
          .locationFromAddress(addrress!)
          .then((value) {
        final lat = value[0].latitude;
        final lng = value[0].longitude;
        final target = LatLng(lat, lng);
        final cameraPosition = CameraPosition(target: (target), zoom: 17);

        final cameraUpdate = CameraUpdate.newCameraPosition(cameraPosition);

        return _controller.animateCamera(cameraUpdate);
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Alamat tidak ditemukan",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16);
    }
  }
}
