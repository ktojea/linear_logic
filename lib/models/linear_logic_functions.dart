import 'dart:io';

import 'package:fraction/fraction.dart';
import 'package:linear_logic/enums/extremum_type.dart';
import 'package:linear_logic/enums/solution_type.dart';
import 'package:linear_logic/models/matrix.dart';
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
  static List<Fraction> getReducedFunctionToSmallerAmountVariables(
    List<int> indexesNecessaryColumns,
    List<List<Fraction>> gaussValues,
    List<Fraction> function,
    ExtremumType extremumType,
  ) {
    final newFunction = [
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

    // TODO: Add check ExtremumType
    if (extremumType == ExtremumType.max) {}

    /// We got a function reduced to fewer variables.
    return newFunction;
  }
}
