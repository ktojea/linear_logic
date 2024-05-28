import "package:linear_logic/enums/priority.dart";
import "package:linear_logic/models/linear_logic_functions.dart";
import "package:linear_logic/models/step.dart";

// / ex
// -2,-1,-3,-1,min
// 1,2,5,-1,4
// 1,-1,-1,2,1
// 4
// /

void main(List<String> arguments) {
  final fileContent = LinearLogic.getFile('assets/input.txt');
  final task = LinearLogic.createTask(fileContent);

  print(task.basis);

  final firstMatrix = task.getInitialMatrix;

  /// An example of a solution when the basis is given.
  //! The basis must be given.
  final indexesNecessaryColumns = task.basis!;
  final matrixWithNecessaryColumnsInFront = firstMatrix.putNecessaryColumnsInFront(indexesNecessaryColumns);
  final gaussValues = matrixWithNecessaryColumnsInFront.useGaussMethod!;
  final reducedFunction = LinearLogic.getReducedFunctionToSmallerAmountVariables(
    indexesNecessaryColumns,
    gaussValues,
    task.function,
    task.extremumType,
  );

  final matrixForSimplex = LinearLogic.createMatrixForSimplexMethodWithBasis(
    indexesNecessaryColumns,
    gaussValues,
    reducedFunction,
  );

  print(matrixForSimplex.toString());

  task.solutionSteps.add(Step(
    matrix: matrixForSimplex,
    availableSupportElements: matrixForSimplex.availableSupportElements,
  ));

  while (true) {
    if (task.solutionSteps.last.availableSupportElements.isEmpty) {
      print('Решено!');
      break;
    } else {
      final availableSupportElements = task.solutionSteps.last.matrix.availableSupportElements;

      final supportElement = availableSupportElements.firstWhere((e) => e.priority == Priority.high);

      final newMatrix = task.solutionSteps.last.matrix.calculateNewMatrixForNewSupportElement(supportElement);

      task.solutionSteps.add(
        Step(
          matrix: newMatrix,
          availableSupportElements: newMatrix.availableSupportElements,
        ),
      );
      print(task.solutionSteps.last.matrix.toString());
    }
  }
}
