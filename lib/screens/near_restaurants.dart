import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map/main.dart';
import 'package:kakao_map/service/kakaomap_api.dart';
import 'package:kakao_map/models/category_response.dart';
import 'package:clickable_list_wheel_view/clickable_list_wheel_widget.dart';
import 'package:webviewx/webviewx.dart';
import 'package:kakao_map/widgets/iframe_elements.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

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
    print("현재 접속중인 기기 : $defaultTargetPlatform");

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
        body: Column(
          children: [
            FutureBuilder<CategoryResponse>(
                future: futureList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Center(
                          child: Container(
                            width: 600,
                            margin: const EdgeInsets.all(10),
                            child:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '반경 500m이내  \'음식점\'  검색결과\n전체 $totalCount건 (MAX 45건 표기)',
                                    style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 106, 47, 14))),

                                OutlinedButton(
                                  onPressed: () {

                                    // 랜덤으로 음식점 선택하는 로직
                                    int rngNum = currSelctedItem + Random().nextInt(_itemCount) + 45;
                                    int index = rngNum % _itemCount; // 몇번째 음식점 정보인지 계산

                                    // 선택된 음식점으로 스크롤
                                    Future<void> animationEnd = scrollController
                                        .animateToItem(
                                        rngNum, duration: const Duration(seconds: 5),
                                        curve: Curves.easeInOutExpo);

                                    // 애니메이션 끝나면
                                    animationEnd.then((value) {
                                      // 음식점 정보 팝업 호출
                                      if(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS){
                                        html.window.open('https://place.map.kakao.com/${snapshot.data!.documents?.elementAt(index).id}', 'new tab');
                                      }else {
                                        showDialog<String>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return ShowRestaurantInfo(index: index, screenSize: screenSize, snapshot: snapshot);
                                          },
                                        );
                                      }

                                    });
                                  },
                                  style:
                                  // OutlinedButton.styleFrom(side: BorderSide(width: 1, color: Color.fromARGB(255, 106, 47, 14))),
                                  ButtonStyle(
                                      fixedSize: MaterialStateProperty.all(const Size(100, 50)), side: MaterialStateProperty.all(const BorderSide(width: 1, color: Color.fromARGB(255, 106, 47, 14)))),
                                  child: const Text('골라줘!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                                      color: Color.fromARGB(255, 106, 47, 14))),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: (MediaQuery.of(context).size.height - 190),
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

                                // 음식점 정보 팝업 호출
                                if(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS){
                                  html.window.open('https://place.map.kakao.com/${snapshot.data!.documents?.elementAt(index).id}', 'new tab');
                                }else{
                                  showDialog<String>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return ShowRestaurantInfo(index: index, screenSize: screenSize, snapshot: snapshot);
                                    },
                                  );
                                }

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
                                              title:
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,

                                                    children: [
                                                      Container(
                                                        // alignment: Alignment.centerLeft,
                                                        width: 200,
                                                        margin: const EdgeInsets.only(right: 5),
                                                        child: Flex(
                                                            direction: Axis.horizontal,
                                                            children: [
                                                              Flexible(child: Text(
                                                                  e.placeName!,
                                                                  style: const TextStyle(
                                                                      fontSize: 18,
                                                                      fontWeight: FontWeight
                                                                          .bold,
                                                                      color: Color
                                                                          .fromARGB(
                                                                          255, 106, 47,
                                                                          14))))
                                                            ]
                                                        ),
                                                      ),
                                                      Text('${e.distance!}m',
                                                          style: const TextStyle(
                                                              color: Color.fromARGB(
                                                                  255, 106, 47, 14)))
                                                    ],
                                                  ),
                                                  Flexible(child: Text(
                                                      e.categoryName!.replaceAll(
                                                          "음식점 > ", ""),
                                                      style: const TextStyle(fontSize: 14,
                                                          color: Color.fromARGB(
                                                              255, 106, 47, 14))))
                                                ],
                                              ),
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
                }),
          ],
        ),
        bottomNavigationBar: Container(margin: const EdgeInsets.only(top: 10), child: const KakaoAdfitWebviewx()),
    );
  }
}

// 음식점 정보 팝업 위젯
class ShowRestaurantInfo extends StatefulWidget {
  const ShowRestaurantInfo({Key? key, required this.snapshot, required this.index, required this.screenSize}) : super(key: key);

  final AsyncSnapshot<CategoryResponse> snapshot;
  final int index;
  final Size screenSize;

  @override
  State<ShowRestaurantInfo> createState() => _ShowRestaurantInfoState();
}

class _ShowRestaurantInfoState extends State<ShowRestaurantInfo> {

  late WebViewXController webviewController;

  @override
  Widget build(BuildContext context) {

    return
      PointerInterceptor(
      child: AlertDialog(
        titlePadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        content: WebViewX(
          initialContent: 'https://place.map.kakao.com/${widget.snapshot.data!.documents?.elementAt(widget.index).id}',
          initialSourceType: SourceType.url,
          onWebViewCreated: (controller) => webviewController = controller,
          height: widget.screenSize.height / 1.1,
          width: min(widget.screenSize.width * 0.9, 1024),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
