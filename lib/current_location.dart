import 'dart:ui' as ui;
import 'dart:html';
import 'package:flutter/material.dart';
import 'main.dart';

class CurrentLocation extends StatefulWidget {
  CurrentLocation({Key? key}) : super(key: key);

  @override
  State<CurrentLocation> createState() => _CurrentLocationState();
}

class _CurrentLocationState extends State<CurrentLocation> {
  @override
  void initState() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'naver-map',
      (int viewId) => IFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..src = 'assets/map.html'
        ..style.border = 'none',
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('현재위치'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.50,
            width: double.infinity,
            child: HtmlElementView(viewType: 'naver-map'),
          ),
          OutlinedButton(
            child:
                const Text('이 위치로 변경', style: TextStyle(color: Colors.black)),
            onPressed: () {Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );},
            style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(Size(200, 50))),
          )
        ],
      ),
    );
  }
}
