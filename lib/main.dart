import 'dart:async';

import 'package:flutter/material.dart';
import 'current_location.dart';
import 'near_restaurants.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double lat = 0, lng = 0;
  String address = '';

  setAddr(String recvdAddr) {
    setState(() {
      address = recvdAddr;
    });
  }

  @override
  void initState() {
    Future<Position> currPos = _determinePosition();
    currPos.then((value) {
      print('메인화면 - 현재위치 : ${value.latitude} ${value.longitude}');
      setState(() {
        lat = value.latitude;
        lng = value.longitude;
      });
    }).catchError((error) {
      print(error);
    });

    //현재위치 계속 받아오는 함수
    /*
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 100,
    );
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      print(DateFormat("HH:mm:ss").format(DateTime.now()) +
          ' -------------- ' +
          (position == null
              ? 'Unknown'
              : '${position.latitude.toString()}, ${position.longitude.toString()}'));
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('뭐먹지?', style: TextStyle(fontSize: 40)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(address, style: TextStyle(fontSize: 20))),

              // IconButton(
              //   icon: Icon(Icons.pin_drop_outlined),
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => CurrentLocation(lat: widget.lat, lng: widget.lng)),
              //     );
              //   },
              // )
              SelectionButton(lat: lat, lng: lng, setAddr: setAddr)
            ],
          ),
          OutlinedButton(
            child: const Text('땡기는 음식 찾아보기',
                style: TextStyle(color: Colors.black)),
            onPressed: () {},
            style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(Size(200, 50))),
          ),
          Center(
            child: OutlinedButton(
              child:
                  const Text('내 주변 음식점', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NearRestaurants()),
                );
              },
              style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all(Size(200, 50))),
            ),
          ),
          Center(
            child: OutlinedButton(
              child:
                  const Text('나만의 리스트', style: TextStyle(color: Colors.black)),
              onPressed: () {},
              style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all(Size(200, 50))),
            ),
          )
        ],
      ),
    );
  }
}

class SelectionButton extends StatelessWidget {
  double lat = 0, lng = 0;
  String address = '';
  final setAddr;

  SelectionButton(
      {required this.lat, required this.lng, this.setAddr, super.key});

  @override
  Widget build(BuildContext context) {
    print('GPS버튼 : ${lat} ${lng}');

    // return RaisedButton(
    //   onPressed: () {
    //     _navigateAndDisplaySelection(context);
    //   },
    //   child: Text('Pick an option, any option!'),
    // );

    return IconButton(
      icon: Icon(Icons.pin_drop_outlined),
      onPressed: () {
        Future<BoxedReturns> recvdBox = _navigateAndDisplaySelection(context);
        recvdBox
            .then((value) => setAddr(value.address))
            .catchError((error) {
              print(error);
            });

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => CurrentLocation(lat: widget.lat, lng: widget.lng)),
        // );
      },
    );
  }

  // SelectionScreen을 띄우고 navigator.pop으로부터 결과를 기다리는 메서드
  Future<BoxedReturns> _navigateAndDisplaySelection(
      BuildContext context) async {
    // Navigator.push는 Future를 반환합니다. Future는 선택 창에서
    // Navigator.pop이 호출된 이후 완료될 것입니다.
    final BoxedReturns result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CurrentLocation(lat: lat, lng: lng)),
    );
    // if (!context.mounted) return;
    // if (!context.mounted) return;

    print(result.address);

    return result;

    // 선택 창으로부터 결과 값을 받은 후, 이전에 있던 snackbar는 숨기고 새로운 결과 값을
    // 보여줍니다.
    // ScaffoldMessenger.of(context).widget.child();

    // ..removeCurrentSnackBar()
    // ..showSnackBar(SnackBar(content: Text("${result.lng}")));
  }
}

//현재위치 받아오는 함수
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
