
const List<String> escapes    = [' ', '\n', '\t', '\r'];
const List<String> delimeters = [',', '+', '-', '<-', '->', '[', ']'];

enum Tok {
  sym,
  num,
  join,
  comma,
  doubleArrow,
  leftArrow,
  rightArrow,
  openBrckt,
  closeBrckt,
}

class Tree {
  Tree(Map<String, Node> nodes);
}

class Node {
  // global node id indexer
  static int index = 0;

  int id;
  String name;
  List<Node> nodes;
  List<double> position;

  Node(this.name) : 
    nodes = [], 
    position = [], 
    id = index++;

  void addPosition(double coord) {
    position.add(coord);
  }

  void addNode(Node node) {
    if (!nodes.contains(node)) nodes.add(node);
  }

  @override
  String toString() {
    return name;
  }
}

Tok tokType(String source) {
  switch (source) {
    case '+': return Tok.join;
    case '[': return Tok.openBrckt;
    case ']': return Tok.closeBrckt;
    case ',': return Tok.comma;
    case '-': return Tok.doubleArrow;
    case '->': return Tok.rightArrow;
    case '<-': return Tok.leftArrow;
    default:
      if (isNumeric(source)) return Tok.num;
      return Tok.sym;
  }
}

bool isNumeric(String source) {
  return double.tryParse(source) != null;
}

Map<String, Node> parseToks(List<String> toks) {
  Map<String, Node> nodes = {};
  List<String> head = [''];
  int brcktDepth = 0;
  Tok connection = Tok.doubleArrow;

  for (int i = 0; i < toks.length; i++) {
    Tok type = tokType(toks[i]);
    switch (type) {
      case Tok.join:
        head = [''];
        break;

      case Tok.comma:
        assert(brcktDepth > 0);
        head.last = '';
        break;

      case Tok.openBrckt:
        brcktDepth++;
        head.add('');
        break;

      case Tok.closeBrckt:
        assert(brcktDepth > -1);
        brcktDepth--;
        head.removeLast();
        break;

      case Tok.sym:
        nodes.putIfAbsent(toks[i], () => Node(toks[i]));
        Node  rhs = nodes[toks[i]]!;
        Node? lhs;

        if (head.last.isEmpty && brcktDepth > 0) {
          lhs = nodes[head[head.length - 2]];
        } else if (head.isNotEmpty) {
          lhs = nodes[head.last];
        }

        if (lhs != null) {
          switch (connection) {
            case Tok.doubleArrow:
              lhs.addNode(rhs);
              rhs.addNode(lhs);
              break;

            case Tok.leftArrow:
              rhs.addNode(lhs);
              break;

            case Tok.rightArrow:
              lhs.addNode(rhs);
              break;

            default: throw Exception('unreachable!');
          }
        }

        head.last = toks[i];
        connection = Tok.doubleArrow;
        break;

      case Tok.leftArrow:
      case Tok.rightArrow:
      case Tok.doubleArrow: 
        assert(tokType(toks[i + 1]) == Tok.sym);
        connection = type;
        break;

      default: break;
    }
  }

  return nodes;
}

List<String> parseSyms(String source) {
  List<String> syms = []; 
  String lex = "";

  for (int i = 0; i < source.length; i++) {
    String delimeter = '';
    for (String elem in delimeters) {
      if (elem.length < delimeter.length || i + elem.length >= source.length) continue;
      if (elem == source.substring(i, i + elem.length)) delimeter = elem;
    }

    if (escapes.contains(source[i]) || delimeter.isNotEmpty) {
      if (lex.isNotEmpty) syms.add(lex);
      if (delimeter.isNotEmpty) {
        syms.add(delimeter);
        i += delimeter.length - 1;
      }

      lex = "";
      continue;
    }

    lex += source[i];
  }

  if (lex.isNotEmpty) syms.add(lex);

  return syms;
}

void tree(String source) {
  List<String> syms = parseSyms(source);
  Map<String, Node> nodes = parseToks(syms); 

  for (Node n in nodes.values) {
    print("node $n has connections ${n.nodes}");
  }
}
