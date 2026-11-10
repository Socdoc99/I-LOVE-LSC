import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'analytics_service.dart';

final analyticsProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(firebaseAnalyticsProvider)),
);
