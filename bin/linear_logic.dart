import "package:linear_logic/models/linear_logic_functions.dart";

// / ex
// -2,-1,-3,-1,min
// 1,2,5,-1,4
// 1,-1,-1,2,1
// 4
// /

void main(List<String> arguments) {
  final fileContent = LinearLogic.getFile('assets/input.txt');
  final task = LinearLogic.createTask(fileContent);

  /// An example of an step by step solution to a task.
  task.solutionSteps.add(LinearLogic.nextStep(task, null)!);

  while (true) {
    final lastStep = task.solutionSteps.last;

    /// Selecting a new reference element from the available ones.
    final supportElement =
        lastStep.availableSupportElements.isNotEmpty ? lastStep.availableSupportElements.first : null;

    final nextStep = LinearLogic.nextStep(task, supportElement);

    /// We check whether there are further steps to solve this problem.
    if (nextStep == null) break;

    task.solutionSteps.add(nextStep);
  }

  /// An example of an automatic solution to a task.
  // LinearLogic.solveTask(task);

  for (final s in task.solutionSteps) {
    print(s.stepType);
    print(s.matrix.toString());
    print('\n');
  }
  print('answer: ${task.answer}');
  print('answer details: ${task.answerDetails}');
}
