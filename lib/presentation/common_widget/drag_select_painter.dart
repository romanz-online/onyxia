import 'package:onyxia/export.dart';

/// A common painter widget for drawing drag selection rectangles.
///
/// This painter draws a semi-transparent filled rectangle with a colored border
/// to indicate the current drag selection area.
// class DragSelectPainter extends CustomPainter {
//   final Rect? dragSelect;

//   DragSelectPainter({
//     this.dragSelect,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (dragSelect == null) return;

//     // Draw filled rectangle with semi-transparent highlight color
//     canvas.drawRect(
//       Rect.fromPoints(dragSelect!.topLeft, dragSelect!.bottomRight),
//       Paint()
//         ..color = NarwhalColors.highlight.withAlpha(75)
//         ..style = .fill,
//     );

//     // Draw stroke rectangle with full highlight color
//     canvas.drawRect(
//       Rect.fromPoints(dragSelect!.topLeft, dragSelect!.bottomRight),
//       Paint()
//         ..color = NarwhalColors.highlight
//         ..style = .stroke
//         ..strokeWidth = 2.0,
//     );
//   }

//   @override
//   bool shouldRepaint(DragSelectPainter oldDelegate) {
//     return oldDelegate.dragSelect != dragSelect;
//   }
// }

/// A utility method for painting drag selection rectangles.
///
/// This is a helper method that can be used within other CustomPainter classes
/// to draw drag selection rectangles without needing a separate painter.
void paintDragSelect(BuildContext context, Canvas canvas, Rect? dragSelect) {
  if (dragSelect == null) return;

  // Draw filled rectangle with semi-transparent highlight color
  canvas.drawRect(
    Rect.fromPoints(dragSelect.topLeft, dragSelect.bottomRight),
    Paint()
      ..color = ThemeHelper.blue500(context).withValues(alpha: 0.5)
      ..style = .fill,
  );

  // Draw stroke rectangle with full highlight color
  canvas.drawRect(
    Rect.fromPoints(dragSelect.topLeft, dragSelect.bottomRight),
    Paint()
      ..color = ThemeHelper.blue500(context)
      ..style = .stroke
      ..strokeWidth = 2.0,
  );
}
