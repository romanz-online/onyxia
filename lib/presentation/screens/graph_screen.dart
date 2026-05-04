import 'package:onyxia/constellation/constellation.dart';
import 'package:onyxia/export.dart';

class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
        ),
      ),
      child: const Constellation(),
    );
  }
}
