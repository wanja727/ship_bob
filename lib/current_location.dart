import 'dart:convert';
import 'dart:html';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'main.dart';

class CurrentLocation extends StatefulWidget {

  double lat = 0, lng = 0;
  String address = '';

  CurrentLocation({Key? key, required this.lat, required this.lng}) : super(key: key);

  @override
  State<CurrentLocation> createState() => _CurrentLocationState();
}

class _CurrentLocationState extends State<CurrentLocation> {

  IFrameElement _iFrameElement = IFrameElement();

  @override
  void initState() {

    _iFrameElement.src = 'assets/map.html';
    _iFrameElement.style.width = '100%';
    _iFrameElement.style.height = '100%';
    _iFrameElement.style.border = 'none';

    // iframe으로 postMessage 보내기
    _iFrameElement.onLoad.listen((event) {
      _iFrameElement.contentWindow?.postMessage({'lat':widget.lat,'lng':widget.lng}, "*");
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('naver-map',(int viewId) => _iFrameElement,);

    // iframe에서 message 받아오기
    window.addEventListener("message", (event) {
      var data = (event as MessageEvent).data ?? '-';
      if (data != '-') {
        if(this.mounted){
          setState(() {
            widget.lat = jsonDecode(data)['lat'];
            widget.lng = jsonDecode(data)['lng'];
            widget.address = jsonDecode(data)['address'];
          });
        }
      }
    });

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
            height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.70,
            width: double.infinity,
            child: HtmlElementView(viewType: 'naver-map'),
          ),
          OutlinedButton(
            child:
                const Text('이 위치로 변경', style: TextStyle(color: Colors.black)),
            onPressed: () {Navigator.pop(
              context,
              BoxedReturns(widget.lat, widget.lng, widget.address)
            );},
            style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(Size(200, 50))),
          )
        ],
      ),
    );
  }
}

class BoxedReturns{
  final double lat;
  final double lng;
  final String address;

  BoxedReturns(this.lat, this.lng, this.address);
}