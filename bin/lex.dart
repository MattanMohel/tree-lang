import 'dart:io';

/// List of escaper characters
const List<String> escape = ['\n', '\t', '\r'];

/// Represents possible [Tok] states
enum TokType {
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

extension Into on TokType {
  /// Converts [TokType] to [Tok]
  Tok into([dynamic value]) {
    return Tok(this, value);
  }
}

/// Converts [char] to [TokType]
TokType matchTokType(String ch) {
  switch (ch) {
    case '|':
      return TokType.pipe;
    case '(':
      return TokType.lParenth;
    case ')':
      return TokType.rParenth;
    case '[':
      return TokType.lBracket;
    case ']':
      return TokType.rBracket;
    case ' ':
      return TokType.space;
    default:
      return TokType.none;
  }
}

/// Represents a token
class Tok {
  const Tok(this.type, [this.value]);
  final TokType type;
  final dynamic value;

  TokType get getType => type;
  String  get getName => value;
  int     get getNumber => value;

  @override
  String toString() => type.name;
}

/// Represents a node connection
class Node {
  Node(this.name, this.connections, this.pos) 
    : nameHash = name.hashCode;

  List<Node> connections = [];
  final String   name;
  final List<int> pos;
  final int  nameHash;

  void addConnection(Node other) {
    if (!connections.contains(other)) {
      connections.add(other);
    }
  }

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  int get hashCode => nameHash;
  
  @override
  String toString() => name;
}

/// Represents tree of nodes
class Tree {
  Tree(this.nodes);

  static Tree fromString(String str) {
    List<Tok> toks = extractToks(str);
    return Tree(parseToks(toks));
  }

  static Future<Tree> fromFile(String path) async {
    String str = await File(path).readAsString();
    List<Tok> toks = extractToks(str);
    return Tree(parseToks(toks));
  }

  List<Node> nodes;

  List<Node> get getNodes => nodes;

  List<Node> computeOptimalPath(String beg, String end) {
    throw UnimplementedError();
  }
}

int validateToks(List<Tok> toks) {
  // pattern A(x, y, z)
  const List<TokType> pats = [
    TokType.symbol,
    TokType.lParenth,
    TokType.number,
    TokType.rParenth
  ];

  int pipeIndex = toks.indexWhere((tok) => tok.getType == TokType.pipe);
  if (pipeIndex == -1) {
    pipeIndex = toks.length;
  }

  int patIndex = 0;

  for (int i = 0; i < pipeIndex; i++) {
    if (pats[patIndex] == TokType.number && toks[i].getType == TokType.rParenth) {
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
      case TokType.lBracket: 
        bracketDepth++;
        break;
      
      case TokType.rBracket: 
        bracketDepth--;
        break;
      
      case TokType.symbol:
      case TokType.pipe: break;
      
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

List<Node> parseToks(List<Tok> toks) {
  String nodeHash  = "";
  List<Node> nodes = [];
  List<int> pos    = [];

  final int pipeIndex = validateToks(toks);

  for (int i = 0; i < pipeIndex; i++) {
    switch (toks[i].getType) {
      case TokType.symbol: 
        nodeHash = toks[i].getName;
        break;
      
      case TokType.number: 
        pos.add(toks[i].getNumber);
        break;
      
      case TokType.rParenth: 
        Node node = Node(nodeHash, [], pos.toList());
        nodes.add(node);
        
        nodeHash = "";
        pos      = [];
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

      case TokType.lBracket:
        inBrackets = true;
        break;

      case TokType.rBracket:
        inBrackets = false;
        break;

      case TokType.symbol:
        int nodeIndex = nodes.indexWhere((node) => node.hashCode == toks[i].getName.hashCode);
        // create node if it doesn't exist
        if (nodeIndex == -1) {
          Node newNode = Node(toks[i].getName, [], []);
          nodes.add(newNode);

          nodeIndex = nodes.length - 1;
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
    if (escape.contains(str[i])) {
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
          toks.add(TokType.symbol.into(lex));
        } else {
          toks.add(TokType.number.into(pos));
        }

        lex = "";
      }

      if (type != TokType.space) {
        toks.add(type.into());
      }
    }
  }

  if (lex.isNotEmpty) {
    toks.add(TokType.symbol.into(lex));
  }

  return toks;
}
