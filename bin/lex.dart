
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

class Vertex {
  final String name;
  bool init = false;

  double x;
  double y;
  List<Vertex> points;

  Vertex(this.name) : x = 0, y = 0, points = [];

  void addPoint(Vertex point) {
    if (!points.contains(point)) {
      points.add(point);
    }
  }

  void setXY(double x, double y) {
    this.x = x;
    this.y = y;
    init = true;
  }

  double magnitude() {
    return sqrt(pow(x, 2) + pow(y, 2));
  }

  double distance(Vertex other) {
    if (!init || !other.init) {
      return 1;
    }

    return sqrt(pow(other.x - x, 2) + pow(other.y - y, 2));
  }
}

class Tree {
  late Map<String, Vertex> vertices;

  Tree(this.vertices);

  static Tree fromString(String source) {
    return tree(source);
  }

  static Future<Tree> fromFile(String path) async {
    String source = await File(path).readAsString();
    return fromString(source);
  }

  List<String> shortestPath(String beg, String end) {
    List<String> unvisited = vertices.keys.toList();
    Map<String, String> previous = vertices.map((key, _) => MapEntry(key, ''));
    Map<String, double> distances = vertices.map((key, _) => MapEntry(key, double.infinity));
    distances[beg] = 0;

    while (unvisited.isNotEmpty) {
      String key = unvisited.reduce((lhs, rhs) => distances[lhs]! < distances[rhs]!? lhs : rhs);
      unvisited.remove(key);

      if (distances[key] == double.infinity) {
        break;
      }
      
      Vertex vertex = vertices[key]!;

      for (Vertex point in vertex.points) {
        double distance = vertex.distance(point) + distances[key]!;
        if (distance < distances[point.name]!) {
          distances[point.name] = distance;
          previous[point.name] = key;
        }
      }      
    }

    List<String> path = [end];
    while (path.last != beg) {
      path.add(previous[path.last]!);
    }

    return path;
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

Map<String, Vertex> parseToks(List<String> toks) {
  Map<String, Vertex> vertices = {};
  List<String> head = [''];
  List<double> pose = [];
  int prnthDepth = 0;
  int brcktDepth = 0;
  Tok connection = Tok.doubleArrow;

  for (int i = 0; i < toks.length; i++) {
    switch (tokType(toks[i])) {
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
        pose.clear();
        break;

      case Tok.closePrnth:
        assert(pose.length == 2);
        assert(prnthDepth == 1);
        prnthDepth--;
        vertices[head.last]!.setXY(pose[0], pose[1]);
        head.last = '';
        break;

      case Tok.num:
        assert(prnthDepth == 1);
        pose.add(double.parse(toks[i]));
        break;

      case Tok.sym:
        vertices.putIfAbsent(toks[i], () => Vertex(toks[i]));
        Vertex  rhs = vertices[toks[i]]!;
        Vertex? lhs;

        if (head.last.isEmpty && brcktDepth > 0) {
          lhs = vertices[head[head.length - 2]];
        } else if (head.isNotEmpty) {
          lhs = vertices[head.last];
        }

        if (lhs != null) {
          switch (connection) {
            case Tok.doubleArrow:
              lhs.addPoint(rhs);
              rhs.addPoint(lhs);
              break;

            case Tok.leftArrow:
              rhs.addPoint(lhs);
              break;

            case Tok.rightArrow:
              lhs.addPoint(rhs);
              break;

            default: throw Exception('unreachable!');
          }
        }

        head.last = toks[i];
        connection = Tok.doubleArrow;
        break;

      // arrow types: '-' or '->' or '<-'
      default: 
        assert(tokType(toks[i + 1]) == Tok.sym);
        connection = tokType(toks[i]);
    }
  }

  return vertices;
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
  Map<String, Vertex> nodes = parseToks(syms); 
  return Tree(nodes);
}
