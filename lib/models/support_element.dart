import 'package:fraction/fraction.dart';
import 'package:linear_logic/enums/priority.dart';

class SupportElement {
  SupportElement({
    required this.value,
    required this.position,
    required this.priority,
  });

  final Fraction value;

  final (int, int) position;

  final Priority priority;

  @override
  String toString() {
    return '${'\n'}row: ${position.$1}${'\n'}column: ${position.$2}${'\n'}priority: ${priority.name}${'\n'}';
  }
}
