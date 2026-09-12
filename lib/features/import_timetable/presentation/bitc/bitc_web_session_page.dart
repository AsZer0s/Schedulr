import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BitcWebSessionPage extends StatefulWidget {
  const BitcWebSessionPage({required this.request, super.key});

  final BitcTimetableWebRequest request;

  @override
  State<BitcWebSessionPage> createState() => _BitcWebSessionPageState();
}

class BitcTimetableWebRequest {
  const BitcTimetableWebRequest({
    required this.academicYearStart,
    required this.termCode,
  });

  final String academicYearStart;
  final String termCode;
}

class _BitcWebSessionPageState extends State<BitcWebSessionPage> {
  static final _entryUri = Uri.parse(
    'https://jwxt.vpn.bitc.edu.cn/kbcx/'
    'xskbcx_cxXskbcxIndex.html?gnmkdm=N2151&layout=default',
  );

  late final WebViewController _controller;
  Completer<String>? _payloadCompleter;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _canFetch = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SchedulrBridge',
        onMessageReceived: (message) {
          final completer = _payloadCompleter;
          if (completer == null || completer.isCompleted) return;
          final envelope = jsonDecode(message.message);
          if (envelope is! Map<String, Object?>) {
            completer.completeError(
              const FormatException('Invalid bridge response.'),
            );
            return;
          }
          final error = envelope['error'];
          final payload = envelope['payload'];
          if (error is String && error.isNotEmpty) {
            completer.completeError(StateError(error));
          } else if (payload is String) {
            completer.complete(payload);
          } else {
            completer.completeError(
              const FormatException('Missing timetable payload.'),
            );
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _message = null;
          }),
          onPageFinished: (url) {
            final uri = Uri.tryParse(url);
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _canFetch =
                  uri?.host == 'jwxt.vpn.bitc.edu.cn' &&
                  uri?.path.contains('xskbcx_cxXskbcxIndex.html') == true;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null ||
                uri.scheme != 'https' ||
                !_isAllowedHost(uri.host)) {
              setState(() => _message = '已阻止离开北京信息职业技术学院域名的跳转。');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            setState(() {
              _isLoading = false;
              _message = '学校登录页面加载失败，请检查网络或 VPN 服务状态。';
            });
          },
        ),
      )
      ..loadRequest(_entryUri);
  }

  bool _isAllowedHost(String host) {
    return host == 'bitc.edu.cn' || host.endsWith('.bitc.edu.cn');
  }

  Future<void> _fetchTimetable() async {
    setState(() {
      _isFetching = true;
      _message = null;
    });
    try {
      final completer = Completer<String>();
      _payloadCompleter = completer;
      await _controller.runJavaScript(
        _fetchScript(
          academicYearStart: widget.request.academicYearStart,
          termCode: widget.request.termCode,
        ),
      );
      final payload = await completer.future.timeout(
        const Duration(seconds: 20),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?> ||
          decoded['kbList'] is! List<Object?>) {
        throw const FormatException('Response is not a timetable payload.');
      }
      if (!mounted) return;
      Navigator.of(context).pop(payload);
    } on Object {
      if (!mounted) return;
      setState(() {
        _message = '无法读取课表。请确认页面已经显示“个人课表查询”，然后重试。';
      });
    } finally {
      _payloadCompleter = null;
      if (mounted) setState(() => _isFetching = false);
    }
  }

  String _fetchScript({
    required String academicYearStart,
    required String termCode,
  }) {
    final year = jsonEncode(academicYearStart);
    final term = jsonEncode(termCode);
    return '''
      (async function () {
        if (location.hostname !== 'jwxt.vpn.bitc.edu.cn') {
          throw new Error('Not on the timetable host');
        }
        const body = new URLSearchParams({
          xnm: $year,
          xqm: $term,
          kzlx: 'ck',
          xsdm: ''
        });
        const response = await fetch('/kbcx/xskbcx_cxXsgrkb.html', {
          method: 'POST',
          credentials: 'same-origin',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
          },
          body: body.toString()
        });
        if (!response.ok) throw new Error('HTTP ' + response.status);
        const rawPayload = await response.json();
        const allowedKeys = [
          'jxb_id', 'kch', 'kcmc', 'xm', 'xqj', 'jcs', 'jcor', 'zcd',
          'xqmc', 'cdmc', 'jxbmc', 'khfsmc', 'xf', 'jxbsftkbj'
        ];
        const courses = Array.isArray(rawPayload.kbList)
          ? rawPayload.kbList.map(function (item) {
              const course = {};
              allowedKeys.forEach(function (key) {
                if (Object.prototype.hasOwnProperty.call(item, key)) {
                  course[key] = item[key];
                }
              });
              return course;
            })
          : [];
        const minimizedPayload = JSON.stringify({
          kbList: courses,
          sjkList: Array.isArray(rawPayload.sjkList)
            ? rawPayload.sjkList.map(function () { return {}; })
            : []
        });
        SchedulrBridge.postMessage(JSON.stringify({
          payload: minimizedPayload
        }));
      })().catch(function (error) {
        SchedulrBridge.postMessage(JSON.stringify({
          error: String(error && error.message ? error.message : error)
        }));
      });
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录 BITC 教务'),
        actions: [
          IconButton(
            tooltip: '重新加载',
            onPressed: _isFetching ? null : _controller.reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            MaterialBanner(
              content: Text(
                _canFetch
                    ? '已进入个人课表页面。应用只读取课表接口，不读取或保存登录密码。'
                    : '请在学校 VPN/IAM 页面完成登录。页面仅允许访问 bitc.edu.cn 域名。',
              ),
              actions: const [SizedBox.shrink()],
            ),
            if (_message case final message?)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: _canFetch && !_isFetching ? _fetchTimetable : null,
          icon: _isFetching
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
          label: Text(_isFetching ? '正在读取课表…' : '读取当前学期课表'),
        ),
      ),
    );
  }
}
