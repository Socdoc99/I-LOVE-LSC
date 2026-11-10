import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/survey_repository.dart';

final surveyRepositoryProvider = Provider<SurveyRepository>(
  (ref) => SurveyRepository(ref.watch(firestoreProvider)),
);
