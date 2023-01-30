import 'lex.dart';

/// Path to tree data
const dataPath = "res/test.tr";

void main() async {
  Tree tree = await Tree.fromFile(dataPath);
  
  for (var node in tree.getNodes) {
    print("node $node is connected to ${node.connections}");
  }
}
