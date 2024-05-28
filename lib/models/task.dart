import 'package:fraction/fraction.dart';
import 'package:linear_logic/enums/extremum_type.dart';
import 'package:linear_logic/enums/solution_type.dart';
import 'package:linear_logic/models/matrix.dart';
import 'package:linear_logic/models/step.dart';

class Task {
  /// Amount of variables.
  final int amountVars;

  /// The target function.
  final List<Fraction> function;

  /// The type of extremum (optimization problem).
  final ExtremumType extremumType;

  /// The amount of limitations on the task.
  final int amountLimitations;

  /// Given limitations.
  final List<List<Fraction>> limitations;

  /// The way to solve the problem.
  final SolutionType solutionType;

  /// Solving the problem.
  final List<Step> solutionSteps = [];

  /// If the basis is not specified, then first you need to find an artificial basis.
  final List<int>? basis;

  Matrix get getInitialMatrix {
    /// Counting the last row (the sum of the constraints).
    final limitationsSum = List.generate(amountVars + 1, (index) => Fraction(0));

    for (int i = 0; i < limitationsSum.length; i++) {
      for (final line in limitations) {
        limitationsSum[i] -= line[i];
      }
    }

    /// The initial matrix for the search for an artificial basis.
    final matrix = [...limitations, limitationsSum];

    /// Generation for the name of the matrix variables.
    final upperVariables = List.generate(amountVars, (i) => 'x${i + 1}');
    final sideVariables = List.generate(amountLimitations, (i) => 'x${i + amountVars + 1}');

    return Matrix(
      upperVariables: upperVariables,
      sideVariables: sideVariables,
      values: matrix,
    );
  }

  Task({
    required this.amountVars,
    required this.function,
    required this.extremumType,
    required this.amountLimitations,
    required this.limitations,
    required this.solutionType,
    this.basis,
  });

  @override
  String toString() {
    final text = '''
    amountVars:
    $amountVars

    function:
    $function

    extremumType:
    $extremumType

    amountLimitations:
    $amountLimitations

    limitations:
    $limitations

    solutionType:
    $solutionType

    basis:
    $basis
                  ''';

    return text;
  }
}
