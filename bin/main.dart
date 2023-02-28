import 'lex.dart';

/// Path to tree data
const dataPath = "res/test.tr";

void main() async {
  Tree tr = await Tree.fromFile(dataPath);
  print(tr);
}
