import 'dart:io';

import 'package:fraction/fraction.dart';
import 'package:linear_logic/enums/extremum_type.dart';
import 'package:linear_logic/enums/priority.dart';
import 'package:linear_logic/enums/solution_type.dart';
import 'package:linear_logic/enums/step_type.dart';
import 'package:linear_logic/models/matrix.dart';
import 'package:linear_logic/models/step.dart';
import 'package:linear_logic/models/support_element.dart';
import 'package:linear_logic/models/task.dart';

abstract class LinearLogic {
  /// Create a task. To create it, you need [initialConditions] (a task in the form of text).
  ///
  /// Example for [initialConditions] :
  ///
  /// -1,3,5,1,min (target function)
  ///
  /// 1,4,4,1,5 (1 limitation)
  ///
  /// 1,7,8,2,9 (2 limitation)
  ///
  /// 4 (amount vars)
  ///
  /// 0,2 (indexes for the basis, if not ("/"), an artificial basis solution will be used.)
  static Task createTask(String initialConditions) {
    final initialConditionsList = initialConditions.split('\n');

    /// Input basis.
    final basisText = initialConditionsList.last;
    final stringBasis = basisText == '/' ? null : basisText.split(',');
    final basis = stringBasis?.map((v) => int.parse(v)).toList();

    /// Input function and extremum type.
    final functionList = initialConditionsList[0].split(',');

    final stringFunction = functionList.sublist(0, functionList.length - 1);
    final function = convertListToFractionList(stringFunction);

    final extremumType = ExtremumType.values.firstWhere((e) => e.name == functionList.last);

    /// Input amountVars.
    final amountVars = int.parse(initialConditionsList[initialConditionsList.length - 2]);

    /// Input amount limitations and limitations.
    final amountLimitations = initialConditionsList.length - 3;
    final stringLimitations = initialConditionsList.sublist(1, amountLimitations + 1).map((e) => e.split(',')).toList();
    final limitations = stringLimitations.map((e) => convertListToFractionList(e)).toList();

    /// Create task.
    final task = Task(
      amountVars: amountVars,
      function: function,
      extremumType: extremumType,
      amountLimitations: amountLimitations,
      limitations: limitations,
      solutionType: SolutionType.stepByStep,
      basis: basis,
    );

    return task;
  }

  /// Converts a list of values in string format to a list of fractions.
  static List<Fraction> convertListToFractionList(List<String> stringList) {
    final fractionList = <Fraction>[];
    for (final value in stringList) {
      /// Fraction.fromString("2/4") == 2/4
      if (value.contains('/')) {
        fractionList.add(Fraction.fromString(value));
      }

      /// Fraction.fromDouble(-8.5) == -17/2
      else {
        fractionList.add(Fraction.fromDouble(double.parse(value)));
      }
    }

    return fractionList;
  }

  static String getFile(String path) {
    //! Warning
    //! If the target function is x1-x3 -> min,
    //! then it is correct to specify it as: "1,0,-1,min".
    //! But not so "1,,-1,min".

    final fileText = File(path);

    if (fileText.existsSync()) {
      try {
        final fileContent = fileText.readAsStringSync();
        return fileContent;
      } on Exception catch (_) {
        print("возникли проблемы при чтении информации из файла!");
      }
    }

    return '';
  }

  /// Create a matrix for the simplex method using the basis.
  static Matrix createMatrixForSimplexMethodWithBasis(
    List<int> indexesNecessaryColumns,
    List<List<Fraction>> gaussValues,
    List<Fraction> reducedFunction,
  ) {
    final List<List<Fraction>> newValues = [];

    final indexesRemainingColumns = [
      for (int i = 0; i < gaussValues.first.length; i++)
        if (!indexesNecessaryColumns.contains(i)) i
    ];

    /// We go through the remaining rows.
    for (int i = 0; i < gaussValues.length; i++) {
      final List<Fraction> newRow = [];

      /// We go through the remaining columns.
      for (int j = indexesNecessaryColumns.length; j < gaussValues.first.length; j++) {
        if (j == gaussValues.first.length - 1) {
          newRow.add(gaussValues[i][j]);
        } else {
          newRow.add(gaussValues[i][j]);
        }
      }

      newValues.add(newRow);
    }

    final List<Fraction> lastRow = [];

    for (int i in indexesRemainingColumns) {
      if (i == indexesRemainingColumns.last) {
        lastRow.add(reducedFunction[i] * Fraction(-1));
      } else {
        lastRow.add(reducedFunction[i]);
      }
    }

    newValues.add(lastRow);

    final upperVariables =
        indexesRemainingColumns.sublist(0, indexesRemainingColumns.length - 1).map((i) => 'x${i + 1}').toList();
    final sideVariables = indexesNecessaryColumns.map((i) => 'x${i + 1}').toList();

    return Matrix(
      upperVariables: upperVariables,
      sideVariables: sideVariables,
      values: newValues,
    );
  }

  /// To get a function reduced to a smaller number of variables through a given basis.
  static List<Fraction> getReducedFunctionToSmallerAmountVariablesFromGauss(
    List<int> indexesNecessaryColumns,
    List<List<Fraction>> gaussValues,
    List<Fraction> function,
    ExtremumType extremumType,
  ) {
    List<Fraction> newFunction = [
      ...List.generate(function.length, (i) => indexesNecessaryColumns.contains(i) ? Fraction(0) : function[i]),
      Fraction(0)
    ];

    final indexesRemainingColumns = [
      for (int i = 0; i < gaussValues.first.length; i++)
        if (!indexesNecessaryColumns.contains(i)) i
    ];

    /// We go through the remaining columns.
    for (int i = 0; i < indexesRemainingColumns.length; i++) {
      /// We go through the basic columns (Gauss rows).

      for (int j = 0; j < indexesNecessaryColumns.length; j++) {
        final value = gaussValues[j][i + indexesNecessaryColumns.length] * function[indexesNecessaryColumns[j]];

        /// The value of the original function.
        if (indexesRemainingColumns[i] == function.length) {
          newFunction[indexesRemainingColumns[i]] += value;
        }

        /// For the rest of the columns, the sign changes.
        else {
          newFunction[indexesRemainingColumns[i]] += value * Fraction(-1);
        }
      }
    }

    if (extremumType == ExtremumType.max) {
      newFunction = newFunction.map((v) => v * Fraction(-1)).toList();
    }

    /// We got a function reduced to fewer variables.
    return newFunction;
  }

  /// Get a function reduced to fewer variables from an auxiliary task.
  static List<Fraction> getReducedFunctionToSmallerAmountVariablesFromAuxiliaryMatrix(
    Matrix auxiliaryMatrix,
    List<Fraction> function,
    ExtremumType extremumType,
  ) {
    final List<Fraction> reducedFunction = [];

    for (int i = 0; i < auxiliaryMatrix.values.first.length; i++) {
      var coeffsSum = Fraction(0);

      int? currentBasicVarIndex;
      if (i != auxiliaryMatrix.values.first.length - 1) {
        currentBasicVarIndex = int.parse(auxiliaryMatrix.upperVariables[i].substring(1)) - 1;
      }
      final currentBasicVarValue = currentBasicVarIndex == null ? Fraction(0) : function[currentBasicVarIndex];

      for (int j = 0; j < auxiliaryMatrix.sideVariables.length; j++) {
        final currentExpressedVarIndexInFunc = int.parse(auxiliaryMatrix.sideVariables[j].substring(1)) - 1;
        final currentMultiplier = function[currentExpressedVarIndexInFunc];
        coeffsSum += auxiliaryMatrix.values[j][i] * currentMultiplier;
      }

      coeffsSum *= Fraction(-1);

      Fraction newValue = currentBasicVarValue + coeffsSum;

      if (extremumType == ExtremumType.max) newValue *= Fraction(-1);

      reducedFunction.add(newValue);
    }

    /// Simplify fractions.
    for (int i = 0; i < reducedFunction.length; i++) {
      if (reducedFunction[i].numerator % reducedFunction[i].denominator == 0) {
        reducedFunction[i] = Fraction(reducedFunction[i].numerator ~/ reducedFunction[i].denominator);
      } else {
        reducedFunction[i] = reducedFunction[i].reduce();
      }
    }

    return reducedFunction;
  }

  /// Automatically solves the problem.
  /// All steps are added to the solution steps this problem.
  static void solveTask(Task task) {
    final firstMatrix = task.getInitialMatrix;

    task.solutionSteps.add(
      Step(
        matrix: firstMatrix,
        availableSupportElements: firstMatrix.availableSupportElements,
        stepType: task.basis == null ? StepType.artificialBasisMethod : StepType.simplexMethod,
      ),
    );

    // If the basis is not given, then we run the artificial basis method.
    if (task.basis == null) {
      while (true) {
        if (task.solutionSteps.last.availableSupportElements.isEmpty) {
          if (task.solutionSteps.last.matrix.values.last.where((e) => e != Fraction(0)).isEmpty) {
            print('Базис найден!');
            break;
          } else {
            task.answerDetails = 'Нет решений. Система противоречива или не ограничена.';
            return;
          }
        } else {
          final availableSupportElements = task.solutionSteps.last.matrix.availableSupportElements;

          final supportElement = availableSupportElements.firstWhere((e) => e.priority == Priority.high);

          final newMatrix = task.solutionSteps.last.matrix.calculateNewMatrixForNewSupportElement(supportElement, true);

          task.solutionSteps.add(
            Step(
              matrix: newMatrix,
              availableSupportElements: newMatrix.availableSupportElements,
              stepType: StepType.artificialBasisMethod,
            ),
          );
        }
      }

      final List<Fraction> reducedFunction = LinearLogic.getReducedFunctionToSmallerAmountVariablesFromAuxiliaryMatrix(
        task.solutionSteps.last.matrix,
        task.function,
        task.extremumType,
      );

      final newValues =
          task.solutionSteps.last.matrix.values.sublist(0, task.solutionSteps.last.matrix.values.length - 1);

      newValues.add(reducedFunction);

      final newMatrix = Matrix(
        upperVariables: task.solutionSteps.last.matrix.upperVariables,
        sideVariables: task.solutionSteps.last.matrix.sideVariables,
        values: newValues,
      );

      task.solutionSteps.add(Step(
        matrix: newMatrix,
        availableSupportElements: newMatrix.availableSupportElements,
        stepType: StepType.simplexMethod,
      ));
    }

    /// Let's move on to solving the problem using the simplex method.
    if (task.basis != null) {
      final indexesNecessaryColumns = task.basis!;
      final matrixWithNecessaryColumnsInFront = firstMatrix.putNecessaryColumnsInFront(indexesNecessaryColumns);
      final gaussValues = matrixWithNecessaryColumnsInFront.useGaussMethod!;
      final reducedFunction = LinearLogic.getReducedFunctionToSmallerAmountVariablesFromGauss(
        indexesNecessaryColumns,
        gaussValues,
        task.function,
        task.extremumType,
      );

      print(reducedFunction.map((e) => e.reduce()).toList());

      final newMatrix = LinearLogic.createMatrixForSimplexMethodWithBasis(
        indexesNecessaryColumns,
        gaussValues,
        reducedFunction,
      );

      task.solutionSteps.add(Step(
        matrix: newMatrix,
        availableSupportElements: newMatrix.availableSupportElements,
        stepType: StepType.simplexMethod,
      ));
    }

    while (true) {
      if (task.solutionSteps.last.availableSupportElements.isEmpty) {
        final lastRow = task.solutionSteps.last.matrix.values.last;
        final lastRowWithoutAnswer = lastRow.sublist(0, lastRow.length - 1);

        if (lastRowWithoutAnswer.where((v) => v < Fraction(0)).isEmpty) {
          task.answer = task.solutionSteps.last.matrix.values.last.last * Fraction(-1);
          task.answerDetails = 'Задача решена!';
          break;
        } else {
          task.answerDetails = 'Нет решений. Система не ограничена.';
          return;
        }
      } else {
        final availableSupportElements = task.solutionSteps.last.matrix.availableSupportElements;

        final supportElement = availableSupportElements.firstWhere((e) => e.priority == Priority.high);

        final newMatrix = task.solutionSteps.last.matrix.calculateNewMatrixForNewSupportElement(supportElement);

        task.solutionSteps.add(
          Step(
            matrix: newMatrix,
            availableSupportElements: newMatrix.availableSupportElements,
            stepType: StepType.simplexMethod,
          ),
        );
      }
    }
  }

  /// This method is needed to solve the problem step by step.
  /// The method returns 'null' when the task has no new solution steps.
  ///
  /// Specify the value of the reference element 'null',
  /// when switching from the artificial basis search to the simplex method.
  static Step? nextStep(Task task, SupportElement? supportElement) {
    /// If there are details of the answer, then the solution of the problem is completed.
    if (task.answerDetails != null) return null;

    if (task.solutionSteps.isEmpty) {
      final firstMatrix = task.getInitialMatrix;

      return Step(
        matrix: firstMatrix,
        availableSupportElements: firstMatrix.availableSupportElements,
        stepType: task.basis == null ? StepType.artificialBasisMethod : StepType.simplexMethod,
      );
    }

    final lastStep = task.solutionSteps.last;

    final currentStepType = lastStep.stepType;

    final lastRow = lastStep.matrix.values.last;

    /// The last step was the search for an artificial basis.
    if (currentStepType == StepType.artificialBasisMethod) {
      /// A situation where there are no available support elements
      /// at the stage of searching for an artificial basis.
      if (lastStep.availableSupportElements.isEmpty) {
        /// The situation when the basis is found.
        if (lastRow.where((e) => e != Fraction(0)).isEmpty) {
          task.artificialBasis = [Fraction(2), Fraction(2), Fraction(8)];

          final List<Fraction> reducedFunction =
              LinearLogic.getReducedFunctionToSmallerAmountVariablesFromAuxiliaryMatrix(
            task.solutionSteps.last.matrix,
            task.function,
            task.extremumType,
          );

          final newValues =
              task.solutionSteps.last.matrix.values.sublist(0, task.solutionSteps.last.matrix.values.length - 1);

          newValues.add(reducedFunction);

          final newMatrix = Matrix(
            upperVariables: task.solutionSteps.last.matrix.upperVariables,
            sideVariables: task.solutionSteps.last.matrix.sideVariables,
            values: newValues,
          );

          return Step(
            matrix: newMatrix,
            availableSupportElements: newMatrix.availableSupportElements,
            stepType: StepType.simplexMethod,
          );
        }

        /// The situation where the basis could not be found.
        else {
          task.answerDetails = 'Нет решений. Система противоречива или не ограничена.';
          return null;
        }
      } else {
        final availableSupportElements = task.solutionSteps.last.matrix.availableSupportElements;

        final supportElement = availableSupportElements.firstWhere((e) => e.priority == Priority.high);

        final newMatrix = task.solutionSteps.last.matrix.calculateNewMatrixForNewSupportElement(supportElement, true);

        return Step(
          matrix: newMatrix,
          availableSupportElements: newMatrix.availableSupportElements,
          stepType: StepType.artificialBasisMethod,
        );
      }
    }

    /// The last step was the simplex method.
    else {
      final lastRowWithoutAnswer = lastRow.sublist(0, lastRow.length - 1);

      /// A situation where there are no support elements available.
      if (lastStep.availableSupportElements.isEmpty) {
        if (lastRowWithoutAnswer.where((v) => v < Fraction(0)).isEmpty) {
          task.answer = task.solutionSteps.last.matrix.values.last.last * Fraction(-1);
          task.answerDetails = 'Задача решена!';
          return null;
        } else {
          task.answerDetails = 'Нет решений. Система не ограничена.';
          return null;
        }
      }

      /// A situation where a simplex table has available support elements.
      else {
        final availableSupportElements = task.solutionSteps.last.matrix.availableSupportElements;

        final supportElement = availableSupportElements.firstWhere((e) => e.priority == Priority.high);

        final newMatrix = task.solutionSteps.last.matrix.calculateNewMatrixForNewSupportElement(supportElement);

        return Step(
          matrix: newMatrix,
          availableSupportElements: newMatrix.availableSupportElements,
          stepType: StepType.simplexMethod,
        );
      }
    }
  }
}
