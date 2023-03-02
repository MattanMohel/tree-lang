import 'lex.dart';

/// Path to tree data
const dataPath = "res/test.tr";

void main() async {
  Tree tree = Tree.fromString(
  '''
    A B C E D [-> A, B]
  ''');

  print(tree.shortestPath('A', 'E').reversed);
}
