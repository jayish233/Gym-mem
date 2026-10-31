import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: PresenceColors.hairline);
}

/// Border for a row or block that sits under a hairline.
const hairlineTop = Border(top: BorderSide(color: PresenceColors.hairline));
