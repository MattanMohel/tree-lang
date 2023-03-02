import 'lex.dart';

/// Path to tree data
const dataPath = "res/test.tr";

void main() async {
  Tree tree = Tree.fromString(
  '''
    A -> B:5 C:10
  ''');

  print(tree.shortestPath('A', 'C'));
}
