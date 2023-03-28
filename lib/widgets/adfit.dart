import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';

class Adfit extends StatefulWidget {
  const Adfit({Key? key}) : super(key: key);

  @override
  State<Adfit> createState() => _AdfitState();
}

class _AdfitState extends State<Adfit> {

  late WebViewXController webviewController;

  @override
  Widget build(BuildContext context) {
    return WebViewX(
      initialContent: """<ins class="kakao_ad_area" style="display:none;"
data-ad-unit = "DAN-5lYZKrazuaRPy4q9"
data-ad-width = "320"
data-ad-height = "50"></ins>
<script type="text/javascript" src="//t1.daumcdn.net/kas/static/ba.min.js" async></script>""",
      initialSourceType: SourceType.html,
      onWebViewCreated: (controller) => webviewController = controller,

      width: 320,
      height: 50,
    );
  }
}
