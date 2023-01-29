void main() {
  var toks = extractToks("A(1 2 3) B(2 4 5) | A B");
  print(toks);

  try {
    var nodes = parseToks(toks);
    print(nodes);
  } catch (err) {
    print(err);
  }
}

const List<String> ESCAPE = ['\n', '\t', '\r'];

enum TokType {
  pipe,
  space,
  symbol,
  number,
  l_parenth,
  r_parenth,
  l_bracket,
  r_bracket,
  none
}

extension Into on TokType {
  Tok into({String? sym, int? val}) {
    return Tok(this, symbol: sym, value: val);
  }

  String asString() {
    switch (this) {
      case TokType.pipe:
        return '|';
      case TokType.space:
        return ' ';
      case TokType.l_parenth:
        return '(';
      case TokType.r_parenth:
        return ')';
      case TokType.l_bracket:
        return '[';
      case TokType.r_bracket:
        return ']';
      default:
        return 'other';
    }
  }
}

class Tok {
  const Tok(this.type, {this.symbol, this.value});
  final TokType type;
  final String? symbol;
  final int? value;

  TokType get getType {
    return type;
  }

  String get getName {
    return symbol!;
  }

  int get getNumber {
    return value!;
  }

  @override
  String toString() {
    return type.name;
  }
}

class Node {
  Node(this.nameHash, this.connections, [this.pos]);

  List<Node> connections = List.empty(growable: true);
  final int nameHash;
  final List<int>? pos;

  int get hash {
    return nameHash;
  }

  void addConnection(Node other) {
    connections.add(other);
  }

  @override
  String toString() {
    return "$nameHash, $pos, connections: $connections";
  }
}

enum PatCount {
  variable,
  one;
}

int validateToks(List<Tok> toks) {
  int pipeIndex = toks.indexWhere((tok) => tok.getType == TokType.pipe);

  if (pipeIndex == -1) {
    pipeIndex = toks.length;
  }

  const List<TokType> pats = [
    TokType.symbol,
    TokType.l_parenth,
    TokType.number,
    TokType.r_parenth
  ];

  int patIndex = 0;

  for (int i = 0; i < pipeIndex; i++) {
    if (pats[patIndex] == TokType.number &&
        toks[i].getType == TokType.r_parenth) {
      patIndex++;
    }

    if (toks[i].getType != pats[patIndex]) {
      throw Exception("expected ${pats[patIndex]}, found ${toks[i].getType}");
    }

    if (pats[patIndex] != TokType.number) {
      patIndex = (patIndex + 1) % pats.length;
    }
  }

  return pipeIndex;
}

List<Node>? parseToks(List<Tok> toks) {
  List<Node> nodes = [];
  List<int> pos = [];
  int? nodeHash;

  int pipeIndex = validateToks(toks);

  for (int i = 0; i < pipeIndex; i++) {
    switch (toks[i].getType) {
      case TokType.symbol:
        nodeHash = toks[i].getName.hashCode;
        break;

      case TokType.number:
        pos.add(toks[i].getNumber);
        break;

      case TokType.r_parenth:
        Node node = Node(nodeHash!, [], pos.toList());
        nodes.add(node);

        nodeHash = null;
        pos = [];
        break;

      default:
    }
  }

  Node? node;
  for (int i = pipeIndex; i < toks.length; i++) {
    switch (toks[i].getType) {
      case TokType.pipe: 
        node = null;
        break;

      case TokType.symbol:
        print("here");
        int nodeIndex = nodes.indexWhere((node) => node.nameHash == toks[i].getName.hashCode);
        Node newNode = nodes[nodeIndex];

        if (node == null) {
          node = newNode;
        }
        else {
          node.addConnection(newNode);
          newNode.addConnection(node);
        }

        break;

      default:
    }
  }

  print(nodes);

  return nodes;
}

TokType matchTokType(String ch) {
  switch (ch) {
    case '|':
      return TokType.pipe;
    case '(':
      return TokType.l_parenth;
    case ')':
      return TokType.r_parenth;
    case '[':
      return TokType.l_bracket;
    case ']':
      return TokType.r_bracket;
    case ' ':
      return TokType.space;
    default:
      return TokType.none;
  }
}

List<Tok> extractToks(String str) {
  List<Tok> toks = [];
  String lex = "";

  for (int i = 0; i < str.length; i++) {
    if (ESCAPE.contains(str[i])) {
      continue;
    }

    TokType type = matchTokType(str[i]);

    if (type == TokType.none) {
      lex += str[i];
    } else {
      if (lex.isNotEmpty) {
        int? pos = int.tryParse(lex);

        if (pos == null) {
          toks.add(TokType.symbol.into(sym: lex));
        } else {
          toks.add(TokType.number.into(val: pos));
        }

        lex = "";
      }

      if (type != TokType.space) {
        toks.add(type.into());
      }
    }
  }

  if (lex.isNotEmpty) {
    toks.add(TokType.symbol.into(sym: lex));
  }

  return toks;
}
