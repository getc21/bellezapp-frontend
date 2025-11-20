import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Utils {
  static Color colorBotonesForContext(BuildContext context) {
    try {
      return Theme.of(context).colorScheme.primary;
    } catch (e) {
      return const Color(0xFFEC407A);
    }
  }
  
  static Color get colorBotones {
    return const Color(0xFFEC407A);
  }

  static Color get yes => const Color(0xFF66BB6A);
  static Color get no => const Color(0xFFEF5350);
  static Color get edit => const Color(0xFF64B5F6);

  static get espacio10 => const Gap(10.0);
  static get espacio20 => const Gap(20.0);

  static Widget loadingProgress() {
    return Center(
      child: SpinKitSpinningLines(
        color: colorBotones,
        size: 60.0,
      ),
    );
  }
}
