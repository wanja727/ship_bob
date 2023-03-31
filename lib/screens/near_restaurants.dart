import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_bob/main.dart';
import 'package:ship_bob/service/kakaomap_api.dart';
import 'package:ship_bob/models/category_response.dart';
import 'package:clickable_list_wheel_view/clickable_list_wheel_widget.dart';
import 'package:webviewx/webviewx.dart';
import 'package:ship_bob/widgets/iframe_elements.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

final scrollController = FixedExtentScrollController();
late NearRestaurantsState parent; // AlertDialog에서 NearRestaurantsState의 setState() 함수를 호출하기 위해서 전달해주는 값
late int itemCount; // 목록에 표기되는 건수 (카카오맵API 최대 45건 제한하고 있음)

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

  static late int totalCount; // 실제 검색결과 총건수
  int currSelctedItem = 0; // 현재 선택된(화면 중앙에 있는) 아이템의 인덱스

  Size get screenSize => MediaQuery.of(context).size;

  // 골라줘! 버튼 호출 이벤트 재사용 하기위해 함수로 분리
  void rngBtnOnClick (snapshot){
    // 랜덤으로 음식점 선택하는 로직
    int rngNum = currSelctedItem + Random().nextInt(itemCount) + 45;
    int index = rngNum % itemCount; // 몇번째 음식점 정보인지 계산

    // 선택된 음식점으로 스크롤
    Future<void> animationEnd = scrollController.animateToItem(rngNum, duration: const Duration(seconds: 5), curve: Curves.easeInOutExpo);

    // 애니메이션 끝나면
    animationEnd.then((value) {
      // 음식점 정보 팝업 호출
      showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context)
          {
            return ShowRestaurantInfo(index: index, screenSize: screenSize, snapshot: snapshot, fromRngBtn: true);
          }
      );
    });
  }

  @override
  void initState() {

    print("현재 접속중인 기기 : $defaultTargetPlatform");

    UserPos pos = ref.read(userPosProvider);

    // 주변 검색 카카오맵 API호출
    KakaoMapApi kakaoMapApi = KakaoMapApi();
    futureList = kakaoMapApi.getNearRestaurants(ref, pos.lat, pos.lng, 500);

    futureList.then((value) {

      // 검색 결과 건수 세팅
      totalCount = value.meta!.totalCount!;
      if(value.meta!.totalCount! > 45){
        itemCount = 45;
      }else{
        itemCount = value.meta!.totalCount!;
      }

    // API 에러 발생시 확인창
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
                                    '반경 500m이내  \'음식점\'  검색결과\n전체 $totalCount건 중 $itemCount건 (MAX 45건 표기)',
                                    style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 106, 47, 14))),

                                OutlinedButton(
                                  onPressed: () {
                                    parent = context.findAncestorStateOfType<NearRestaurantsState>()!;
                                    rngBtnOnClick(snapshot);



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
                              itemCount: itemCount,
                              onItemTapCallback: (index) {
                                // print("onItemTapCallback index: $index");
                                index = index % itemCount;
                                // print("보정후에 index: $index");

                                parent = context.findAncestorStateOfType<NearRestaurantsState>()!;

                                // 음식점 정보 팝업 호출
                                showDialog<String>(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context)
                                  {
                                    return ShowRestaurantInfo(index: index, screenSize: screenSize, snapshot: snapshot, fromRngBtn: false);
                                  }
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
                                            color: snapshot.data!.documents?.indexOf(e) == currSelctedItem % itemCount ? const Color.fromARGB(255, 243, 194, 165) : Colors.white,
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
                                                      e.categoryName!,
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
// PC일 경우 webview를 띄워주고
// 모바일일 경우 AlertDialog를 띄워준다
class ShowRestaurantInfo extends ConsumerStatefulWidget {
  const ShowRestaurantInfo({Key? key, required this.snapshot, required this.index, required this.screenSize, required this.fromRngBtn}) : super(key: key);

  final AsyncSnapshot<CategoryResponse> snapshot;
  final int index;
  final Size screenSize;
  final bool fromRngBtn;

  @override
  ShowRestaurantInfoState createState() => ShowRestaurantInfoState();
}

class ShowRestaurantInfoState extends ConsumerState<ShowRestaurantInfo> {

  late WebViewXController webviewController;

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: AlertDialog(
          titlePadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: (
              // defaultTargetPlatform == TargetPlatform.windows
              defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
          )
              ? Text('${widget.snapshot.data?.documents?.elementAt(widget.index).placeName} 어때?',textAlign: TextAlign.center)
              : WebViewX(
                  initialContent: 'https://place.map.kakao.com/${widget.snapshot.data!.documents?.elementAt(widget.index).id}',
                  initialSourceType: SourceType.url,
                  onWebViewCreated: (controller) =>
                      webviewController = controller,
                  height: widget.screenSize.height / 1.1,
                  width: min(widget.screenSize.width * 0.9, 1024),
                ),
          actions: <Widget>[
            if (
            // defaultTargetPlatform == TargetPlatform.windows
            defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
            ) ...[
              TextButton(
                onPressed: () {
                  html.window.open(
                      'https://place.map.kakao.com/m/${widget.snapshot.data!.documents?.elementAt(widget.index).id}',
                      'new tab');
                },
                child: const Text('가게정보'),
              ),
              if(widget.fromRngBtn)...[
                TextButton(
                onPressed: widget.snapshot.data!.documents?.length == 1? null : () {
                  parent.setState(() {
                    itemCount--;
                    widget.snapshot.data!.documents?.removeAt(widget.index);

                  });
                  Navigator.pop(context);
                  parent.rngBtnOnClick(widget.snapshot);
                },

                child: const Text('다시 골라줘!'),
              ),
              ] else ...[
                TextButton(
                  onPressed: widget.snapshot.data!.documents?.length == 1? null : () {
                    parent.setState(() {
                      itemCount--;
                      widget.snapshot.data!.documents?.removeAt(widget.index);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('목록에서 지우기'),
                ),
              ],

              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('닫기'),
              ),
            ] else ...[

              if(widget.fromRngBtn)...[
                TextButton(
                  onPressed: widget.snapshot.data!.documents?.length == 1? null : () {
                    parent.setState(() {
                      itemCount--;
                      widget.snapshot.data!.documents?.removeAt(widget.index);

                    });
                    Navigator.pop(context);
                    parent.rngBtnOnClick(widget.snapshot);
                  },

                  child: const Text('다시 골라줘!'),
                ),
              ] else ...[
                TextButton(
                  onPressed: widget.snapshot.data!.documents?.length == 1? null : () {
                    parent.setState(() {
                      itemCount--;
                      widget.snapshot.data!.documents?.removeAt(widget.index);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('목록에서 지우기'),
                ),
              ],


              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('닫기'),
              ),
            ],
          ]),
    );
  }
}