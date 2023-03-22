import 'dart:convert';
import 'dart:html';
import 'dart:js_util';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart';

// IFrameElement _iFrameElement = IFrameElement();
var clickListener;

class CurrentLocation extends ConsumerStatefulWidget {
  // double lat = 0, lng = 0;
  // String address = '';

  CurrentLocation({Key? key}) : super(key: key);

  @override
  CurrentLocationState createState() => CurrentLocationState();
}

class CurrentLocationState extends ConsumerState<CurrentLocation> {
  // IFrameElement _iFrameElement = IFrameElement();

  @override
  void initState() {
    IFrameElement _iFrameElement = IFrameElement();
    print('init!!!!!!!!');

    UserPos pos = ref.read(userPosProvider);
    print('객체비교3-1 : ${identityHashCode(pos)}');

    _iFrameElement.src = 'assets/map.html';
    _iFrameElement.style.width = '100%';
    _iFrameElement.style.height = '100%';
    _iFrameElement.style.border = 'none';

    onData(event) {
      // pos = ref.read(userPosProvider);
      print('객체비교3-2s : ${identityHashCode(pos)}');
      print('객체비교3-2 : ${pos.toString()}');
      _iFrameElement.contentWindow?.postMessage({'lat': pos.lat, 'lng': pos.lng}, "*");
    }

    // iframe으로 postMessage 보내기
    _iFrameElement.onLoad.listen(onData);

    // iframe으로 postMessage 보내기
    // _iFrameElement.onLoad.listen((event) {
    //   pos = ref.read(userPosProvider);
    //   print('객체비교3-2 : ${identityHashCode(pos)}');
    //   _iFrameElement.contentWindow?.postMessage({'lat': pos.lat, 'lng': pos.lng}, "*");
    // });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'naver-map',
      (int viewId) => _iFrameElement,
    );

    clickListener = (event) {
      var data = (event as MessageEvent).data ?? '-';
      if (data != '-') {
        pos.setUserPos(jsonDecode(data)['lat'], jsonDecode(data)['lng'], jsonDecode(data)['address']);
        print(pos.toString());
      }
    };

    // iframe에서 message 받아오기
    window.addEventListener("message", clickListener);

    // // iframe에서 message 받아오기
    // window.addEventListener("message", (event) {
    //   var data = (event as MessageEvent).data ?? '-';
    //   if (data != '-') {
    //     // if(this.mounted){
    //     //   setState(() {
    //     //     widget.lat = jsonDecode(data)['lat'];
    //     //     widget.lng = jsonDecode(data)['lng'];
    //     //     widget.address = jsonDecode(data)['address'];
    //     //   });
    //     // }
    //     pos.setUserPos(jsonDecode(data)['lat'], jsonDecode(data)['lng'], jsonDecode(data)['address']);
    //     print(pos.toString());
    //   }
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {





    return Scaffold(
      appBar: AppBar(
        title: Text('지금 계신곳을 알려주세요'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: (MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top) *
                0.70,
            width: double.infinity,
            child: HtmlElementView(key: UniqueKey(),viewType: 'naver-map'),
          ),
          OutlinedButton(
            child:
                const Text('이 위치로 변경', style: TextStyle(color: Colors.black)),
            onPressed: () {
              // _iFrameElement.onLoad.listen((event) {},);
              window.removeEventListener("message", clickListener);

              UserPos pos = ref.read(userPosProvider);
              print('객체비교4 : ${identityHashCode(pos)}');

              UserPos newPos = UserPos();
              newPos.setUserPos(pos.lat, pos.lng, pos.address);
              print('객체비교5 : ${identityHashCode(newPos)}');

              ref.read(userPosProvider.notifier).update(
                  (state) => newPos);
              Navigator.pop(
                context,
                // BoxedReturns(widget.lat, widget.lng, widget.address)
              );
            },
            style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(Size(200, 50))),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("_iframeWidget is disposed?");
    super.dispose();
  }
}

class BoxedReturns{
  final double lat;
  final double lng;
  final String address;

  BoxedReturns(this.lat, this.lng, this.address);
}
