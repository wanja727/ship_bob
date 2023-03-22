import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map/screens/main.dart';
import 'package:kakao_map/kakaomap_api.dart';
import 'package:kakao_map/models/category_response.dart';

class NearRestaurants extends ConsumerStatefulWidget {
  const NearRestaurants({Key? key}) : super(key: key);

  @override
  NearRestaurantsState createState() => NearRestaurantsState();
}

class NearRestaurantsState extends ConsumerState<NearRestaurants> {

  late Future<List<Documents>> futureList;

  @override
  void initState() {
    UserPos pos = ref.read(userPosProvider);

    // 좌표->주소 변환 카카오맵 API호출
    KakaoMapApi kakaoMapApi = KakaoMapApi();
    // Future<String> futureAddr =
    futureList = kakaoMapApi.getNearRestaurants(pos.lat, pos.lng, 500);

    // futureAddr.then((futureAddrResult) {
    //
    // }).catchError((error) {
    //   print(error);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 주변 음식점'),
      ),
      body: Column(
        children: [
          FutureBuilder<List<Documents>>(
              future: futureList,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: <Widget>[
                      ...snapshot.data!.map((e) => SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 4,
                          child: Text(e.placeName!),
                        ),
                      )),
                    ],
                  );
                } else if(snapshot.hasError) {
                  return Text('${snapshot.hasError}');
                }
                return const CircularProgressIndicator();
              }
          )

        ],
      ),
    );
  }

}
