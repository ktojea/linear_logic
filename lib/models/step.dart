import 'package:linear_logic/enums/step_type.dart';
import 'package:linear_logic/models/matrix.dart';
import 'package:linear_logic/models/support_element.dart';

class Step {
  Step({
    required this.matrix,
    required this.availableSupportElements,
    required this.stepType,
  });

  /// The matrix at the current step of the task.
  final Matrix matrix;

  /// List of indexes of available support elements.
  final List<SupportElement> availableSupportElements;

  /// Type of solution step ("artificialBasisMethod" or "simplexMethod").
  final StepType stepType;
}
