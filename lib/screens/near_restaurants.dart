import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map/screens/main.dart';
import 'package:kakao_map/kakaomap_api.dart';
import 'package:kakao_map/models/category_response.dart';
import 'package:clickable_list_wheel_view/clickable_list_wheel_widget.dart';
import 'package:webviewx/webviewx.dart';

late Timer upperSliderTimer;
final _scrollController = TrackingScrollController(); //FixedExtentScrollController(initialItem: 0);
late int lastRngNum;

class NearRestaurants extends ConsumerStatefulWidget {
  const NearRestaurants({Key? key}) : super(key: key);

  @override
  NearRestaurantsState createState() => NearRestaurantsState();
}

class NearRestaurantsState extends ConsumerState<NearRestaurants> {
  // late Future<List<Documents>> futureList;
  late Future<CategoryResponse> futureList;
  late WebViewXController webviewController;

  static const double _itemHeight = 60;
  static const int _itemCount = 15;

  Size get screenSize => MediaQuery.of(context).size;

  @override
  void initState() {
    UserPos pos = ref.read(userPosProvider);

    // 좌표->주소 변환 카카오맵 API호출
    KakaoMapApi kakaoMapApi = KakaoMapApi();
    // Future<String> futureAddr =
    futureList = kakaoMapApi.getNearRestaurants(pos.lat, pos.lng, 300);

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
          title: const Text('내 주변 음식점'),
        ),
        body: FutureBuilder<CategoryResponse>(
            future: futureList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            margin: const EdgeInsets.only(right: 300),
                            child: const Text(
                                '고덕동 반경 500m\n \'마라탕\' 검색결과\n 총 45건',
                                style: TextStyle(fontSize: 15))),
                        OutlinedButton(
                          onPressed: () {
                            startController();
                          },
                          style: ButtonStyle(
                              fixedSize: MaterialStateProperty.all(
                                  const Size(100, 50))),
                          child: const Text('골라줘!',
                              style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                    SizedBox(
                      height: (MediaQuery.of(context).size.height - 122),
                      child: ClickableListWheelScrollView(
                          loop: true,
                          scrollController: _scrollController,
                          itemHeight: 150,
                          itemCount: 15,
                          onItemTapCallback: (index) {
                            print("onItemTapCallback index: $index");

                            showDialog<String>(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return Dialog(
                                  insetPadding: const EdgeInsets.all(0),
                                  child:WebViewX(
                                    initialContent: 'http://place.map.kakao.com/m/14935600',
                                    initialSourceType: SourceType.url,
                                    onWebViewCreated: (controller) => webviewController = controller,
                                    height: screenSize.height / 1.2,
                                    width: min(screenSize.width * 0.8, 1024),
                                  )

                                  // Positioned(
                                  //   right: -40.0,
                                  //   top: -40.0,
                                  //   child: InkResponse(
                                  //     onTap: () {
                                  //       Navigator.of(context).pop();
                                  //     },
                                  //     child: CircleAvatar(
                                  //       child: Icon(
                                  //         Icons.close,
                                  //         color: Colors.white,
                                  //       ),
                                  //       backgroundColor: Colors.red,
                                  //       maxRadius: 20.0,
                                  //     ),
                                  //   ),
                                  // ),

                                  // Align(
                                  //   alignment: Alignment.topRight,
                                  //   child: IconButton(
                                  //     icon: Icon(
                                  //       Icons.close,
                                  //       color: Colors.black,
                                  //       size: 25,
                                  //     ),
                                  //     onPressed: () {
                                  //       Navigator.pop(context);
                                  //     },
                                  //   ),
                                  // ),
                                  // const Text('AlertDialog Title'),
                                );
                              },
                            );
                          },
                          child: ListWheelScrollView.useDelegate(
                            controller: _scrollController,
                            itemExtent: 150,
                            diameterRatio: 5,
                            useMagnifier: true,
                            magnification: 1,
                            // physics: const FixedExtentScrollPhysics(),
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: <Widget>[
                                ...?snapshot.data!.documents?.map((e) => Container(
                                      width: 600,
                                      margin: const EdgeInsets.all(20),
                                      child: Material(
                                        color: Colors.white,
                                        child: ListTile(
                                          shape: Border.all(width: 1, color: Colors.black12),
                                          title: Row(
                                            children: [
                                              Container(
                                                width: 300,
                                                margin: const EdgeInsets.only(right: 5),
                                                child: Text(e.placeName!,style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                              ),
                                              Text(e.categoryName!.replaceAll("음식점 > ", ""))
                                            ],
                                          ),
                                          subtitle: Text('${e.distance!}m'),
                                          isThreeLine: true,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          )),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.hasError}');
              }
              return const CircularProgressIndicator();
            }));
  }
}

// 골라줘! 버튼 호출시 랜덤한 가게로 이동
void startController() async {
  int totalitems = 15; //total length of items
  int counter = 0;

  int rngNum = Random().nextInt(15) + 100;
  print(rngNum);

  // _scrollController.animateToItem(rngNum,
  //     duration: Duration(seconds: 5), curve: Curves.easeInOutExpo);

  //rngNum as double
  _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(seconds: 5), curve: Curves.easeInOutExpo);

  // if (counter <= totalitems) {
  //   upperSliderTimer = Timer.periodic(Duration(seconds: 3), (timer) {
  //     _scrollController.animateToItem(counter,
  //         duration: Duration(seconds: 1), curve: Curves.easeInCubic);
  //     counter++;
  //     if (counter == totalitems) counter = 0;
  //   });
  // }
}
