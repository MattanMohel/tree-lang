import 'dart:io';

// /// List of escaper characters
const List<String> escapers = [' ', '\n', '\t', '\r'];
const List<String> delimeters = ['[', ']', '(', ')'];

// /// Represents possible [Tok] states
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

// /// Represents tree of nodes
// class Tree {
//   Tree(this.nodes);

//   static Tree fromString(String str) {
//     List<Tok> toks = extractToks(str);
//     return Tree(parseToks(toks));
//   }

//   static Future<Tree> fromFile(String path) async {
//     String str = await File(path).readAsString();
//     List<Tok> toks = extractToks(str);
//     return Tree(parseToks(toks));
//   }

//   List<Node> nodes;

//   List<Node> get getNodes => nodes;

//   List<Node> computeOptimalPath(String beg, String end) {
//     throw UnimplementedError();
//   }
// }

// int validateToks(List<Tok> toks) {
//   // pattern A(x, y, z)
//   const List<TokType> pats = [
//     TokType.symbol,
//     TokType.lParenth,
//     TokType.number,
//     TokType.rParenth
//   ];

//   int pipeIndex = toks.indexWhere((tok) => tok.getType == TokType.pipe);
//   if (pipeIndex == -1) {
//     pipeIndex = toks.length;
//   }

//   int patIndex = 0;

//   for (int i = 0; i < pipeIndex; i++) {
//     if (pats[patIndex] == TokType.number && toks[i].getType == TokType.rParenth) {
//       patIndex++;
//     }
//     if (toks[i].getType != pats[patIndex]) {
//       throw Exception("expected ${pats[patIndex]}, found ${toks[i].getType}");
//     }
//     if (pats[patIndex] != TokType.number) {
//       patIndex = (patIndex + 1) % pats.length;
//     }
//   }

//   int bracketDepth = 0;
//   for (int i = pipeIndex; i < toks.length; i++) {
//     switch (toks[i].getType) {
//       case TokType.lBracket: 
//         bracketDepth++;
//         break;
      
//       case TokType.rBracket: 
//         bracketDepth--;
//         break;
      
//       case TokType.symbol:
//       case TokType.pipe: break;
      
//       default: 
//         throw Exception("found ${toks[i]} in graph declaration!");   
//     }

//     if (bracketDepth < 0) {
//       throw Exception("too many ending brackets!");
//     }
//     if (bracketDepth > 1) {
//       throw Exception("too many opening brackets!");
//     }
//   }

//   if (bracketDepth != 0) {
//     throw Exception("unbalanced brackets!");
//   }

//   return pipeIndex;
// }

List<Node> parseToks(String str) {
  List<String> toks = splitToks(str);
  List<Node> nodes = [];

  int nodeBeg = 0;
  int nodeEnd = 0;
  while (true) {
    if (toks[nodeBeg] == '|') {
      nodeEnd = nodeBeg;
      break;
    }

    List<int> pos = [];

    for (int i = nodeBeg + 2;; i++) {
      int? res = int.tryParse(toks[i]);

      if (res == null) {
        nodeEnd = i + 1;
        break;
      }

      pos.add(res);
    }

    nodes.add(Node(toks[nodeBeg], [], pos));
    nodeBeg = nodeEnd;
    break;
  }

  Node? head;
  bool inBrackets = false;

  for (int i = nodeEnd; i < toks.length; i++) {
    switch (toks[i]) {
      case '|': {
        head = null;
        break;
      }

      case '[': {
        inBrackets = true;
        break;
      }

      case ']': {
        inBrackets = false;
        break;
      }

      default: {
        int nodeIndex = nodes.indexWhere((node) => node.name == toks[i]);

        // create node if it doesn't exist
        if (nodeIndex == -1) {
          nodes.add(Node(toks[i], [], []));
          nodeIndex = nodes.length - 1;
        }

        Node newNode = nodes[nodeIndex];

        if (head == null) {
          head = newNode;
        } else {
          head.addConnection(newNode);
          newNode.addConnection(head);
          // update head value if out of brackets
          if (!inBrackets) {
            head = newNode;
          }
        }
      }
    }
  }

  return nodes;
}

List<String> splitToks(String str) {
  List<String> toks = [];

  int subBeg = 0;
  int subEnd = 0;
  for (int i = 0; i < str.length; i++) {
    bool isDelimeter = delimeters.contains(str[i]);
    bool isEscaper = escapers.contains(str[i]);
    subEnd = i;

    if (subBeg != subEnd && (isEscaper || isDelimeter)) {
      toks.add(str.substring(subBeg, i));
      subBeg = i + 1;
    }

    if (isEscaper) {
      subBeg = i + 1;
    } else if (isDelimeter) {
      toks.add(str[i]);
      subBeg = i + 1;
    } 
  }

  if (subBeg <= subEnd) {
    toks.add(str.substring(subBeg, subEnd+1));
  }

  return toks;
}