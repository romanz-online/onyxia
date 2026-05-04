import 'package:onyxia/export.dart';

class ExpandedPinNotifier extends StateNotifier<ExpandablePin?> {
  FocusNode? _focusNode;
  
  ExpandedPinNotifier() : super(null);
  
  void expandPin(ExpandablePin item) {
    state = item;
  }

  void collapsePin() {
    _focusNode = null;
    state = null;
  }

  bool isExpanded(String id) => state?.id == id;
  
  /// Set the focus node for the currently expanded pin
  void setFocusNode(FocusNode focusNode) {
    _focusNode = focusNode;
  }
  
  /// Remove the focus node for the currently expanded pin
  void removeFocusNode() {
    _focusNode = null;
  }
  
  /// Check if the currently expanded pin has focus
  bool get hasFocus => _focusNode?.hasFocus ?? false;
}

final expandedPinProvider = StateNotifierProvider.autoDispose<ExpandedPinNotifier, ExpandablePin?>(
  (ref) => ExpandedPinNotifier(),
);
