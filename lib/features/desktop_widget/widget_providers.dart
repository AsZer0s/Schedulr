import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widget_publisher.dart';

final widgetStorageBridgeProvider = Provider<WidgetStorageBridge>((ref) {
  return const HomeWidgetStorageBridge();
});
