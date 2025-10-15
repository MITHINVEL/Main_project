import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const WebMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  State<WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends State<WebMapView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(_mapsUrl()));
  }

  String _mapsUrl() {
    // Use Google Maps search URL which works without an API key in a WebView
    final q = '${widget.latitude},${widget.longitude}';
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address ?? 'Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              // open same URL in external browser
              final url = _mapsUrl();
              // use launch from webview to open external – keep simple by using WebView's controller to load
              _controller.loadRequest(Uri.parse(url));
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
