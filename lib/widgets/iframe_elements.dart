import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:webviewx/webviewx.dart';
import 'package:flutter/material.dart';

// webviewx 패키지 사용하여 애드핏 연계
class KakaoAdfitWebviewx extends StatefulWidget {
  const KakaoAdfitWebviewx({Key? key}) : super(key: key);

  @override
  State<KakaoAdfitWebviewx> createState() => _KakaoAdfitWebviewx();
}

class _KakaoAdfitWebviewx extends State<KakaoAdfitWebviewx> {
  late WebViewXController webviewController;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 320,
      height: 54,
      child: WebViewX(
        initialContent:
"""
<style>
    body{margin: 0;}
</style>
<ins class="kakao_ad_area" style="display:none;"
  data-ad-unit = "DAN-5lYZKrazuaRPy4q9"
  data-ad-width = "320"
  data-ad-height = "50"></ins>
<script type="text/javascript" src="//t1.daumcdn.net/kas/static/ba.min.js" async></script>
""",
        initialSourceType: SourceType.html,
        onWebViewCreated: (controller) => webviewController = controller,
        width: 320,
        height: 54,
      ),
    );
  }
}

// html 패키지 사용하여 애드핏 연계
class KakaoAdfitHtml extends StatelessWidget {
  const KakaoAdfitHtml({Key? key}) : super(key: key);

  final String viewID = "kakao-adfit";

  @override
  Widget build(BuildContext context) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        viewID,
        (int id) => html.IFrameElement()
          ..style.width = '320'
          ..style.height = '50'
          ..style.border = 'none'
          ..srcdoc =
"""
<style>
    body{margin: 0;}
</style>
<ins class="kakao_ad_area" style="display:none;"
  data-ad-unit = "DAN-5lYZKrazuaRPy4q9"
  data-ad-width = "320"
  data-ad-height = "50"></ins>
<script type="text/javascript" src="//t1.daumcdn.net/kas/static/ba.min.js" async></script>
""");

    return Container(
      alignment: Alignment.center,
      width: 320,
      height: 54,
      child: SizedBox(
        width: 320,
        height: 54, // 54+8+8
        child: HtmlElementView(
          viewType: viewID,
        ),
      ),
    );
  }
}
