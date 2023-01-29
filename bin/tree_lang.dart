void main() {
  var toks = extractToks('''
A(0 0)
B(1 0)
C(0 1)
D(1 1)
E(0 -1)

| A [E] B C D 
''');

  try {
    var nodes = parseToks(toks);
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
}

/// Converts char to TokType
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

class Tok {
  const Tok(this.type, {this.symbol, this.value});

  final TokType type;
  final String? symbol;
  final int? value;

  TokType get getType => type;
  String get getName => symbol!;
  int get getNumber => value!;

  @override
  String toString() => type.name;
}

class Node {
  Node(String name, this.connections, [this.pos]) 
    : nameHash = name.hashCode;

  List<Node> connections = [];
  final List<int>? pos;
  final int nameHash;

  void addConnection(Node other) {
    if (connections.contains(other)) {
      return;
    }

    connections.add(other);
  }

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }
  
  @override
  int get hashCode => nameHash;

  @override
  String toString() => "$nameHash, $pos, connections: $connections";
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

  int bracketDepth = 0;
  for (int i = pipeIndex; i < toks.length; i++) {
    switch (toks[i].getType) {
      case TokType.l_bracket:
        bracketDepth++;
        break;

      case TokType.r_bracket:
        bracketDepth--;
        break;

      case TokType.symbol:
      case TokType.pipe:
        break;

      default:
        throw Exception("found ${toks[i]} in graph declaration!");
    }

    if (bracketDepth < 0) {
      throw Exception("too many ending brackets!");
    }
    if (bracketDepth > 1) {
      throw Exception("too many opening brackets!");
    }
  }

  if (bracketDepth != 0) {
    throw Exception("unbalanced brackets!");
  }

  return pipeIndex;
}

List<Node>? parseToks(List<Tok> toks) {
  List<Node> nodes = [];
  List<int> pos = [];
  String? nodeHash;

  final int pipeIndex = validateToks(toks);

  for (int i = 0; i < pipeIndex; i++) {
    switch (toks[i].getType) {
      case TokType.symbol:
        nodeHash = toks[i].getName;
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

  List<Node> head = [];
  bool inBrackets = false;

  for (int i = pipeIndex; i < toks.length; i++) {
    switch (toks[i].getType) {
      case TokType.pipe:
        head = [];
        break;

      case TokType.l_bracket:
        inBrackets = true;
        break;

      case TokType.r_bracket:
        inBrackets = false;
        break;

      case TokType.symbol:
        // find index of parsed node
        int nodeIndex = nodes.indexWhere((node) {
          return node.hashCode == toks[i].getName.hashCode;
        });

        // create node if it doesn't exist
        if (nodeIndex == -1) {
          Node newNode = Node(toks[i].getName, []);
          nodes.add(newNode);
        }

        Node newNode = nodes[nodeIndex];

        if (head.isEmpty) {
          head.add(newNode);
        } 
        else {
          head.last.addConnection(newNode);
          newNode.addConnection(head.last);

          // update head value if out of brackets
          if (!inBrackets) {
            head.last = newNode;
          }
        }

        break;

      default:
    }
  }

  return nodes;
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
    } 
    else {
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
