import 'package:onyxia/export.dart';

final usersProvider = FutureProvider<List<User>>(
  (ref) => UsersRepository().query(),
);
