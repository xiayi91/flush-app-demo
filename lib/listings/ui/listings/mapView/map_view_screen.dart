import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';

class MapViewScreen extends StatefulWidget {
  final List<ListingModel> listings;
  final bool fromHome;
  final ListingsUser currentUser;

  const MapViewScreen(
      {Key? key,
      required this.listings,
      required this.fromHome,
      required this.currentUser})
      : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  Position? locationData;
  final Future _mapFuture =
      Future.delayed(const Duration(milliseconds: 500), () => true);
  GoogleMapController? _mapController;
  late ListingsUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.5),
        title: Text(
          widget.fromHome
              ? 'Map View'.tr()
              : widget.listings.isNotEmpty
                  ? widget.listings.first.categoryTitle
                  : 'Map View'.tr(),
        ),
      ),
      body: FutureBuilder(
          future: _mapFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
            return GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: List.generate(
                  widget.listings.length,
                  (index) => Marker(
                      markerId: MarkerId('marker_$index'),
                      position: LatLng(widget.listings[index].latitude,
                          widget.listings[index].longitude),
                      infoWindow: InfoWindow(
                          onTap: () {
                            push(
                                context,
                                ListingDetailsWrappingWidget(
                                  listing: widget.listings[index],
                                  currentUser: currentUser,
                                ));
                          },
                          title: widget.listings[index].title))).toSet(),
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: locationData == null
                    ? widget.listings.isNotEmpty
                        ? LatLng(widget.listings.first.latitude,
                            widget.listings.first.longitude)
                        : const LatLng(0, 0)
                    : LatLng(locationData!.latitude, locationData!.longitude),
                zoom: 14.4746,
              ),
              onMapCreated: _onMapCreated,
            );
          }),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (isDarkMode(context)) {
      _mapController!.setMapStyle(
        '[{"featureType": "all","'
        'elementType": "'
        'geo'
        'met'
        'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]',
      );
    }

    if (locationData != null) {
      _mapController!.moveCamera(CameraUpdate.newLatLng(
          LatLng(locationData!.latitude, locationData!.longitude)));
    }
  }

  void _getLocation() async {
    locationData = await getCurrentLocation();
    if (_mapController != null) {
      _mapController!.moveCamera(CameraUpdate.newLatLng(LatLng(
          locationData?.latitude ?? 0.01, locationData?.longitude ?? 0.01)));
    }
  }
}
