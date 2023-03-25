import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:kakao_map/screens/current_location.dart';
import 'near_restaurants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map/kakaomap_api.dart';
import 'package:kakao_map/models/category_response.dart';

void main() {
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class UserPos {
  late double lat, lng;
  late String address;

  UserPos();

  setUserPos(double lat, double lng, String address) {
    this.lat = lat;
    this.lng = lng;
    this.address = address;
  }

  @override
  String toString() {
    return 'UserPos(lat: $lat, lng: $lng, address: $address)';
  }

  // UserPos._privateConstructor();
  // static final UserPos _instance = UserPos._privateConstructor();
  // factory UserPos() {
  //   return _instance;
  // }
}

// 프로바이더 최초 생성시에만 동작한다
// ref.read(userPosProvider) 할 때마다 아래의 코드를 호출하는게 아니다
// 최초로 생성한 객체를 계속 가져다 쓸수 있다 (싱글톤)
final userPosProvider = StateProvider((ref) {
  print('userPosProvider 프로바이더 생성');
  return UserPos();
});

final categoryResponseProvider = StateProvider((ref) {
  print('categoryResponseProvider 프로바이더 생성');
  return CategoryResponse();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {

  @override
  void initState() {

    UserPos pos = ref.read(userPosProvider);
    pos.setUserPos(0, 0, '');

    Future<Position> futurePos = _determinePosition();

    futurePos.then((futurePosResult) {
      // print('메인화면 - 현재위치 : ${futurePosResult.latitude} ${futurePosResult.longitude}');

      pos.setUserPos(futurePosResult.latitude, futurePosResult.longitude, '');

      // 좌표->주소 변환 카카오맵 API호출
      KakaoMapApi kakaoMapApi = KakaoMapApi();
      Future<String> futureAddr = kakaoMapApi.getAddress(futurePosResult.latitude, futurePosResult.longitude);
      // Future<String> futureAddr = kakaoMapApi.getAddress(37.55702771590781, 127.14952775554904);

      futureAddr.then((futureAddrResult) {
        // 신규 객체
        UserPos newPos = UserPos();
        // 기존 객체의 값을 받아서 동일하게 세팅한다
        newPos.setUserPos(futurePosResult.latitude, futurePosResult.longitude, futureAddrResult);
        // state 값을 신규 객체로 바꿔줌으로서 변경사항 반영되도록 한다
        ref.read(userPosProvider.notifier).update((state) => newPos);
      }).catchError((error) {
        print(error);
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
              Flexible(
                child: Consumer(
                  builder: (context, ref, _) {
                    UserPos pos = ref.watch(userPosProvider);
                    return Text(pos.address, style: TextStyle(fontSize: 20));
                  },
                ),
              ),

              IconButton(
                icon: Icon(Icons.pin_drop_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CurrentLocation()),
                  );
                },
              )
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
