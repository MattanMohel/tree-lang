
enum Tok {
  pipe,
  space,
  symbol,
  number,
  lParenth,
  rParenth,
  lBracket,
  rBracket,
  none
}

class Node {
  String name;
  List<String> nodes;
  Node(this.name, this.nodes);
}

class Tree {
  String source;
  late List<Tok> tokens;
  late List<int> tokenIndices;
  late List<Node> nodes;

  Tree(this.source) {
    // parse tokens & indices
  }
}