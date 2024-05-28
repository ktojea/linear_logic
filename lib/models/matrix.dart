import 'package:fraction/fraction.dart';
import 'package:linear_logic/enums/priority.dart';
import 'package:linear_logic/models/support_element.dart';

class Matrix {
  Matrix({
    required this.upperVariables,
    required this.sideVariables,
    required this.values,
  });

  /// Top variables for the table.
  final List<String> upperVariables;

  /// Side (left) variables for the table.
  final List<String> sideVariables;

  final List<List<Fraction>> values;

  List<SupportElement> get availableSupportElements {
    List<(int, int)> availableSupportElementsPositions = [];

    List<int> availableColumnForSearchSupportElements = [];

    // We are looking for pillars where the value is negative.
    for (int i = 0; i < values.last.length - 1; i++) {
      if (values.last[i].isNegative) {
        availableColumnForSearchSupportElements.add(i);
      }
    }

    // We go through the available columns for search support elements.
    for (int i in availableColumnForSearchSupportElements) {
      // We go through the rows, but do not take the last one.
      for (int j = 0; j < values.length - 1; j++) {
        if (values[j][i] > Fraction(0)) {
          availableSupportElementsPositions.add((j, i));
        }
      }
    }

    // We are looking for the minimum ratio of the reference element to the value.

    Fraction? minimumRatio;

    for (final supportElementPosition in availableSupportElementsPositions) {
      final ratio =
          values[supportElementPosition.$1].last / values[supportElementPosition.$1][supportElementPosition.$2];

      if (minimumRatio == null || ratio < minimumRatio) {
        minimumRatio = ratio;
      }
    }

    // We fill in the supporting elements taking into account the priority.

    List<SupportElement> availableSupportElements = [];

    for (final supportElementPosition in availableSupportElementsPositions) {
      final ratio =
          values[supportElementPosition.$1].last / values[supportElementPosition.$1][supportElementPosition.$2];

      final priority = ratio == minimumRatio ? Priority.high : Priority.low;

      final supportElement = SupportElement(
        value: values[supportElementPosition.$1][supportElementPosition.$2],
        position: (
          supportElementPosition.$1,
          supportElementPosition.$2,
        ),
        priority: priority,
      );

      availableSupportElements.add(supportElement);
    }

    return availableSupportElements;
  }

  /// Generates a new matrix for a new support element.
  Matrix calculateNewMatrixForNewSupportElement(SupportElement supportElement) {
    List<List<Fraction>> newValues = [];

    // We are looking for new values for the support element,
    // the column of the support element and the row of the support element.

    for (int i = 0; i < values.length; i++) {
      final List<Fraction> newRow = [];

      for (int j = 0; j < values.first.length; j++) {
        if (supportElement.position.$1 == i && supportElement.position.$2 == j) {
          newRow.add(supportElement.value.inverse());
        } else if (i == supportElement.position.$1) {
          newRow.add(values[i][j] / supportElement.value);
        } else if (j == supportElement.position.$2) {
          newRow.add((values[i][j] / supportElement.value) * Fraction(-1));
        } else {
          newRow.add(values[i][j]);
        }
      }

      newValues.add(newRow);
    }

    /// We calculate the values for the remaining rows.
    for (int i = 0; i < values.length; i++) {
      for (int j = 0; j < values.first.length; j++) {
        if (i != supportElement.position.$1 && j != supportElement.position.$2) {
          final newValue =
              values[i][j] - values[i][supportElement.position.$2] * newValues[supportElement.position.$1][j];
          newValues[i][j] = newValue;
        }
      }
    }

    /// Swap the names of variables in the matrix by index.

    final sideIndex = supportElement.position.$1;
    final upperIndex = supportElement.position.$2;

    final newUpperNameVariable = sideVariables[sideIndex];
    final newSideNameVariable = upperVariables[upperIndex];

    /// Such an entry is necessary so that Dart does not refer to the old list and does not change it.
    final newUpperVariables = upperVariables.map((e) => e).toList();
    newUpperVariables[upperIndex] = newUpperNameVariable;

    /// Such an entry is necessary so that Dart does not refer to the old list and does not change it.
    final newSideVariables = sideVariables.map((e) => e).toList();
    newSideVariables[sideIndex] = newSideNameVariable;

    newValues = _simplifyFractions(newValues);

    return Matrix(
      upperVariables: newUpperVariables,
      sideVariables: newSideVariables,
      values: newValues,
    );
  }

  /// Put the necessary columns in front.
  Matrix putNecessaryColumnsInFront(List<int> indexesNecessaryColumns) {
    final newValues = values.map((e) => e.toList()).toList();

    /// We go through the columns.
    for (int j = 0; j < indexesNecessaryColumns.length; j++) {
      /// We go through the rows.
      for (int i = 0; i < values.length - 1; i++) {
        newValues[i][j] = values[i][indexesNecessaryColumns[j]];
      }
    }

    final indexesRemainingColumns = [
      for (int i = 0; i < values.first.length; i++)
        if (!indexesNecessaryColumns.contains(i)) i
    ];

    /// We go through the columns.
    for (int j = 0; j < indexesRemainingColumns.length; j++) {
      /// We go through the rows.
      for (int i = 0; i < values.length - 1; i++) {
        newValues[i][j + indexesNecessaryColumns.length] = values[i][indexesRemainingColumns[j]];
      }
    }

    /// Changing the upper variables taking into account the column permutation.
    final List<String> upperVariables = [
      ...indexesNecessaryColumns.map((i) => i != values.first.length - 1 ? 'x${i + 1}' : ''),
      ...indexesRemainingColumns.map((i) => i != values.first.length - 1 ? 'x${i + 1}' : ''),
    ];

    return Matrix(
      upperVariables: upperVariables,
      sideVariables: [],
      values: newValues,
    );
  }

  // List<List<Fraction>> putColumnsToInitialPosition(List<int> indexesNecessaryColumns) {
  //   final newValues = values.map((e) => e.toList()).toList();

  //   return [];
  // }

  /// Simplify fractions.
  List<List<Fraction>> _simplifyFractions(List<List<Fraction>> listForSimplify) {
    for (int i = 0; i < listForSimplify.length; i++) {
      for (int j = 0; j < listForSimplify.first.length; j++) {
        if (listForSimplify[i][j].numerator % listForSimplify[i][j].denominator == 0) {
          listForSimplify[i][j] = Fraction(listForSimplify[i][j].numerator ~/ listForSimplify[i][j].denominator);
        } else {
          listForSimplify[i][j] = listForSimplify[i][j].reduce();
        }
      }
    }

    return listForSimplify;
  }

  /// Implementation of the Gauss method.
  /// WARNING!!! It does not take the last row in the matrix. WARNING!!!
  List<List<Fraction>>? get useGaussMethod {
    var gaussValues = values.sublist(0, values.length - 1).map((e) => e.toList()).toList();

    /// We go through the columns.
    for (int j = 0; j < gaussValues.length; j++) {
      /// The element that we will bring to 1.
      (int, int)? chosenElement;

      // We go through the rows.
      for (int i = j; i < gaussValues.first.length; i++) {
        if (gaussValues[i][j] != Fraction(0)) {
          /// The first non-zero element in the column.
          chosenElement = (i, j);

          final chosenElementValue = gaussValues[chosenElement.$1][chosenElement.$2];

          /// We reduce the selected element to 1, that is,
          /// we divide each element in the row by the selected element.
          for (int x = 0; x < gaussValues[chosenElement.$1].length; x++) {
            gaussValues[chosenElement.$1][x] /= chosenElementValue;
          }

          /// Swapping the rows.
          final buffer = gaussValues[i];
          gaussValues[i] = gaussValues[j];
          gaussValues[j] = buffer;

          /// We go through the rows.
          for (int x = j + 1; x < gaussValues.length; x++) {
            /// Multiplier for the row to be subtracted from.
            final value = gaussValues[x][j].reduce();

            /// We do not take the string element that was brought to 1.
            for (int y = 0; y < gaussValues.first.length; y++) {
              gaussValues[x][y] -= value * gaussValues[j][y].reduce();
            }
          }

          break;
        }
      }

      if (chosenElement == null) {
        print('Система не имеет решений!');
        return null;
      }
    }

    gaussValues = _simplifyFractions(gaussValues);

    /// Now let's perform the reverse of the Gauss method.
    for (int i = gaussValues.length - 1; i >= 0; i--) {
      for (int j = i - 1; j >= 0; j--) {
        /// Multiplier for the row to be subtracted from.
        final value = gaussValues[j][i].reduce();
        for (int y = 0; y < gaussValues.first.length; y++) {
          gaussValues[j][y] -= value * gaussValues[i][y].reduce();
        }
      }
    }

    gaussValues = _simplifyFractions(gaussValues);

    return gaussValues;
  }

  @override
  String toString() {
    final List<String> valuesForShow = [];

    valuesForShow.add('   ${upperVariables.join(' ')}');

    for (int i = 0; i < sideVariables.length; i++) {
      valuesForShow.add('${sideVariables[i]} ${values[i].join('  ')}');
    }

    valuesForShow.add('   ${values.last.join('  ')}');

    return valuesForShow.join('\n');
  }
}
