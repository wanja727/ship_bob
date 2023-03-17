import 'package:flutter/material.dart';
import 'package:http/http.dart';

class NearRestaurants extends StatefulWidget {
  const NearRestaurants({Key? key}) : super(key: key);

  @override
  State<NearRestaurants> createState() => _NearRestaurantsState();
}

class _NearRestaurantsState extends State<NearRestaurants> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 주변 음식점'),
      ),
      body: Column(
        children: [

        ],
      ),
    );
    ;
  }
}
