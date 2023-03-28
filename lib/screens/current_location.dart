import 'dart:convert';
import 'dart:html';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map/main.dart';

var clickListener;
double lat = 0, lng = 0;

class CurrentLocation extends ConsumerStatefulWidget {
  CurrentLocation({Key? key}) : super(key: key);

  @override
  CurrentLocationState createState() => CurrentLocationState();
}

class CurrentLocationState extends ConsumerState<CurrentLocation> {
  IFrameElement _iFrameElement = IFrameElement();

  @override
  void initState() {
    // 위치정보 객체 read
    UserPos pos = ref.read(userPosProvider);

    // iframe 설정값
    _iFrameElement.src = 'assets/assets/map.html';
    _iFrameElement.style.width = '100%';
    _iFrameElement.style.height = '100%';
    _iFrameElement.style.border = 'none';

    // 전역변수에 옮겨준다
    lat = pos.lat;
    lng = pos.lng;

    // iframe으로 postMessage 보내기
    _iFrameElement.onLoad.listen((event) {
      _iFrameElement.contentWindow?.postMessage({'lat': lat, 'lng': lng}, "*");
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'naver-map',
      (int viewId) => _iFrameElement,
    );

    clickListener = (event) {
      var data = (event as MessageEvent).data ?? '-';
      if (data != '-') {
        pos.setUserPos(jsonDecode(data)['lat'], jsonDecode(data)['lng'], jsonDecode(data)['address']);
      }
    };

    // iframe에서 message 받아오기
    window.addEventListener("message", clickListener);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 106, 47, 14),
        title: const Text('지금 계신곳을 알려주세요'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.7,
            width: double.infinity,
            child: HtmlElementView(key: UniqueKey(), viewType: 'naver-map'),
          ),
          Container(margin: EdgeInsets.only(top: 10),
            child: OutlinedButton(
              child:
                  const Text('이 위치로 변경', style: TextStyle(color: Colors.black)),
              onPressed: () {

                // iframe에서 값 받아오는 리스너 삭제 (안하면 계속 쌓임)
                window.removeEventListener("message", clickListener);

                // 기존 객체
                UserPos pos = ref.read(userPosProvider);

                // 신규 객체
                UserPos newPos = UserPos();
                // 기존 객체의 값을 받아서 동일하게 세팅한다
                newPos.setUserPos(pos.lat, pos.lng, pos.address);

                // state 값을 신규 객체로 바꿔줌으로서 변경사항 반영되도록 한다
                ref.read(userPosProvider.notifier).update((state) => newPos);
                Navigator.pop(
                  context,
                );
              },
              style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all(Size(200, 50))),
            ),
          )
        ],
      ),
    );
  }

}