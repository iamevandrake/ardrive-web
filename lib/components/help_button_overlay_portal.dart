import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:url_launcher/link.dart';

/// A link help button which floats over the provided child widget.
class FloatingHelpButtonPortalEntry extends StatelessWidget {
  const FloatingHelpButtonPortalEntry({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => PortalEntry(
        portal: Link(
          uri: Uri.parse('https://ardrive.typeform.com/to/pGeAVvtg'),
          target: LinkTarget.blank,
          builder: (context, onPressed) => Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 16),
            child: FloatingActionButton(
              tooltip: 'Help',
              onPressed: onPressed,
              child: const Icon(Icons.help_outline),
            ),
          ),
        ),
        portalAnchor: Alignment.bottomRight,
        childAnchor: Alignment.bottomRight,
        child: child,
      );
}
