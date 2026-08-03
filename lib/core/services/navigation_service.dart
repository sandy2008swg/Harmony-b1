import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_pages.dart';

final navigationProvider =
    StateProvider<AppPage>((ref) => AppPage.home);