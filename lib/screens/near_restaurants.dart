import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map/screens/main.dart';
import 'package:kakao_map/kakaomap_api.dart';
import 'package:kakao_map/models/category_response.dart';
import 'package:clickable_list_wheel_view/clickable_list_wheel_widget.dart';
import 'package:webviewx/webviewx.dart';

final scrollController = FixedExtentScrollController();
late int listIndex;

class NearRestaurants extends ConsumerStatefulWidget {
  const NearRestaurants({Key? key}) : super(key: key);

  @override
  NearRestaurantsState createState() => NearRestaurantsState();
}

class NearRestaurantsState extends ConsumerState<NearRestaurants> {

  late Future<CategoryResponse> futureList;
  late WebViewXController webviewController;

  // ClickableListWheelScrollView 설정값
  static const double _itemHeight = 150;
  static late int _itemCount; // 목록에 표기되는 건수 (카카오맵API 최대 45건 제한하고 있음)
  static late int totalCount; // 실제 검색결과 총건수
  int currSelctedItem = 0; // 현재 선택된(화면 중앙에 있는) 아이템의 인덱스

  Size get screenSize => MediaQuery.of(context).size;

  @override
  void initState() {
    UserPos pos = ref.read(userPosProvider);

    // 가게 이름 앞에 붙일 숫자 초기화
    listIndex = 0;
    // 좌표->주소 변환 카카오맵 API호출
    KakaoMapApi kakaoMapApi = KakaoMapApi();

    futureList = kakaoMapApi.getNearRestaurants(ref, pos.lat, pos.lng, 500);

    futureList.then((value) {

      totalCount = value.meta!.totalCount!;
      if(value.meta!.totalCount! > 45){
        _itemCount = 45;
      }else{
        _itemCount = value.meta!.totalCount!;
      }

    }).catchError((error) {
      print(error);

      showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(error.toString()),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            );
          });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 106, 47, 14),
          title: const Text('내 주변 음식점'),
        ),
        body: FutureBuilder<CategoryResponse>(
            future: futureList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              margin: const EdgeInsets.only(right: 200),
                              child: Text(
                                  '반경 500m이내  \'음식점\'  검색결과\n전체 $totalCount건 (MAX 45건 표기)',
                                  style: const TextStyle(fontSize: 15,
                                      color: Color.fromARGB(
                                          255, 106, 47, 14)))),
                          OutlinedButton(
                            onPressed: () {
                              // startController();
                              int rngNum = currSelctedItem +
                                  Random().nextInt(_itemCount) + 45;

                              Future<void> animationEnd = scrollController
                                  .animateToItem(
                                  rngNum, duration: const Duration(seconds: 5),
                                  curve: Curves.easeInOutExpo);

                              animationEnd.then((value) {
                                showDialog<String>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                        insetPadding: const EdgeInsets.all(0),
                                        child: WebViewX(
                                          initialContent: 'https://place.map.kakao.com/${snapshot
                                              .data!
                                              .documents
                                              ?.elementAt(rngNum % _itemCount)
                                              .id}',
                                          initialSourceType: SourceType.url,
                                          onWebViewCreated: (controller) =>
                                          webviewController = controller,
                                          height: screenSize.height / 1.2,
                                          width: min(
                                              screenSize.width * 0.8, 1024),
                                        )
                                    );
                                  },
                                );
                              });
                            },
                            style: ButtonStyle(
                                fixedSize: MaterialStateProperty.all(const Size(
                                    100, 50))),
                            child: const Text('골라줘!', style: TextStyle(
                                color: Color.fromARGB(255, 106, 47, 14))),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: (MediaQuery
                          .of(context)
                          .size
                          .height - 126),
                      width: 600,
                      child: ClickableListWheelScrollView(
                          loop: true,
                          scrollController: scrollController,
                          itemHeight: _itemHeight,
                          itemCount: _itemCount,
                          onItemTapCallback: (index) {
                            // print("onItemTapCallback index: $index");
                            index = index % _itemCount;
                            // print("보정후에 index: $index");

                            // 추후 삭제 기능 구현시 사용
                            // setState(() {
                            //   snapshot.data!.documents?.removeAt(index);
                            // });

                            showDialog<String>(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return Dialog(
                                    insetPadding: const EdgeInsets.all(0),
                                    child: WebViewX(
                                      initialContent: 'https://place.map.kakao.com/${snapshot
                                          .data!
                                          .documents
                                          ?.elementAt(index)
                                          .id}',
                                      initialSourceType: SourceType.url,
                                      onWebViewCreated: (controller) =>
                                      webviewController = controller,
                                      height: screenSize.height / 1.2,
                                      width: min(screenSize.width * 0.8, 1024),
                                    )
                                );
                              },
                            );
                          },
                          child: ListWheelScrollView.useDelegate(
                            onSelectedItemChanged: (value) {
                              // print('value : $value');
                              // print('scrollController.selectedItem : ${scrollController.selectedItem}');
                              setState(() {
                                currSelctedItem = scrollController.selectedItem;
                              });
                            },
                            controller: scrollController,
                            itemExtent: _itemHeight,
                            diameterRatio: 5,
                            // useMagnifier: true,
                            // magnification: 1.1,
                            physics: const FixedExtentScrollPhysics(),
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: <Widget>[
                                ...?snapshot.data!.documents?.map((e) =>
                                    Container(
                                      width: 600,
                                      margin: const EdgeInsets.all(10),
                                      child: Material(
                                        color: snapshot.data!.documents
                                            ?.indexOf(e) ==
                                            currSelctedItem % _itemCount
                                            ? const Color.fromARGB(
                                            255, 243, 194, 165)
                                            : Colors.white,
                                        child: ListTile(
                                          shape: Border.all(width: 1,
                                              color: const Color.fromARGB(
                                                  255, 106, 47, 14)),
                                          title: Row(
                                            // crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 280,
                                                margin: const EdgeInsets.only(
                                                    right: 5),
                                                child: Flex(
                                                    direction: Axis.horizontal,
                                                    children: [
                                                      Flexible(child: Text(
                                                          e.placeName!,
                                                          style: const TextStyle(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight
                                                                  .bold,
                                                              color: Color
                                                                  .fromARGB(
                                                                  255, 106, 47,
                                                                  14))))
                                                    ]
                                                ),
                                              ),
                                              Flexible(child: Text(
                                                  e.categoryName!.replaceAll(
                                                      "음식점 > ", ""),
                                                  style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 106, 47, 14))))
                                            ],
                                          ),
                                          subtitle: Text('${e.distance!}m',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 106, 47, 14))),
                                          // isThreeLine: true,
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
            })
    );
  }
}
