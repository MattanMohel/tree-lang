
import 'dart:async';
import 'dart:io';
import 'dart:math';

const List<String> escapes    = [' ', '\n', '\t', '\r'];
const List<String> delimeters = [',', '+', '-', '<-', '->', '[', ']', '(', ')'];

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
  late Map<String, Node> nodes;

  Tree(this.nodes);
  static Tree fromString(String source) {
    return tree(source);
  }
  static Future<Tree> fromFile(String path) async {
    String source = await File(path).readAsString();
    return fromString(source);
  }

  List<Node> shortestPath(String beg, String end) {
    return [];
  }

  Node? getNode(String name) {
    return nodes[name];
  }

  @override 
  String toString() {
    String buf = '';

    for (Node node in nodes.values) {
      buf += 'node $node has connections ';
      for (Node connection in node.nodes) {
        buf += '${connection.name}:${node.distance(connection)} ';
      }
      buf += '\n';
    }

    return buf;
  }
}

class Node {
  String name;
  List<Node> nodes;
  double x = 0;
  double y = 0;

  Node(this.name) : 
    nodes     = [];

  void addNode(Node node) {
    if (!nodes.contains(node)) nodes.add(node);
  }

  double distance(Node rhs) {
    return sqrt(pow(x - rhs.x, 2) + pow(y - rhs.y, 2));
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
        prnthDepth++;
        xy.clear();
        break;

      case Tok.closePrnth:
        assert(xy.length == 2);
        assert(prnthDepth == 1);
        prnthDepth--;
        nodes[head.last]!.x = xy[0];
        nodes[head.last]!.y = xy[1];
        head.last = '';
        break;

      case Tok.num:
        assert(prnthDepth == 1);
        xy.add(double.parse(toks[i]));
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

List<String> extractToks(String source) {
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

Tree tree(String source) {
  List<String> syms = extractToks(source);
  Map<String, Node> nodes = parseToks(syms); 
  return Tree(nodes);
}
