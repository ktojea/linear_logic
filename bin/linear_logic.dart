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

  LinearLogic.solveTask(task);
  for (final s in task.solutionSteps) {
    print(s.stepType);
    print(s.matrix.toString());
    print('\n');
  }
  print('answer: ${task.answer}');
  print('answer details: ${task.answerDetails}');
}
