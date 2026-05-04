import 'package:onyxia/export.dart';

final userDefinitionsProvider = FutureProvider<List<UserDefinition>>(
  (ref) => UserDefinitionsRepository(projectId: 'root').query(),
);
