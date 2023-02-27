
import 'dart:math';

const List<String> escapes    = [' ', '\n', '\t', '\r'];
const List<String> delimeters = [',', '+', '-', '<-', '->', '[', ']'];

const Map<String, Tok> d = {
  ',': Tok.comma,
  '+': Tok.join,
  '-': Tok.doubleArrow,
  '<-': Tok.leftArrow,
  '->': Tok.rightArrow,
  '[': Tok.openBrckt,
  ']': Tok.closeBrckt,
  '(': Tok.openPrnth,
  ')': Tok.closePrnth
};

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
  openPrnth,
  closePrnth,
}

class Tree {
  Tree(Map<String, Node> nodes);
}

class Node {
  List<Node> nodes;
  double x = -1;
  double y = -1;
  List<double> distances;

  Node() : 
    nodes     = [], 
    distances = [];

  void addNode(Node node) {
    if (!nodes.contains(node)) nodes.add(node);
  }

  void updateDistances() {
    for (Node node in nodes) {
      double dist = sqrt(pow(node.x + x, 2) + pow(node.y + y, 2));
      distances.add(dist);
    }
  }
}

Tok tokType(String source) {
  switch (source) {
    case '+': return Tok.join;
    case '[': return Tok.openBrckt;
    case ']': return Tok.closeBrckt;
    case '(': return Tok.openPrnth;
    case ')': return Tok.closePrnth;
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
  List<double> xy = [];
  int prnthDepth = 0;
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

      case Tok.openPrnth:
        assert(head.last.isNotEmpty);
        assert(prnthDepth == 0);
        xy.clear();
        prnthDepth++;
        break;

      case Tok.num:
        assert(prnthDepth == 1);
        xy.add(double.parse(toks[i]));
        break;

      case Tok.closePrnth:
        assert(xy.length == 2);
        assert(prnthDepth == 1);
        nodes[head.last]!.x = xy[0];
        nodes[head.last]!.y = xy[1];
        head.last = '';
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
