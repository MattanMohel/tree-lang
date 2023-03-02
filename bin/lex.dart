
import 'dart:async';
import 'dart:io';
import 'dart:math';

const List<String> escapes    = [' ', '\n', '\t', '\r'];
const List<String> delimeters = [',', '+', '-', '--', '<-', '->', '[', ']', ':'];

enum Tok {
  sym,
  num,
  join,
  comma,
  arrow,
  leftArrow,
  rightArrow,
  openBrckt,
  closeBrckt,
  colon
}

class Edge {
  String end;
  double weight;
  Edge(this.end, this.weight);
}

class Vertex {
  Set<Edge> edges;
  Vertex() : edges = {};

  void addEdge(String name, double weight) {
    assert(edges.every((edge) => edge.end != name));
    edges.add(Edge(name, weight));
  }
}

class Tree {
  Map<String, Vertex> vertices;
  Tree(this.vertices);

  static Tree fromString(String source) {
    return tree(source);
  }

  static Future<Tree> fromFile(String path) async {
    String source = await File(path).readAsString();
    return fromString(source);
  }

  List<String> shortestPath(String beg, String end) {
    Set<String> unvisited = vertices.keys.toSet();
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

      for (Edge edge in vertex.edges) {
        if (edge.weight + distances[key]! < distances[edge.end]!) {
          distances[edge.end] = edge.weight + distances[key]!;
          previous[edge.end] = key;
        }
      }      
    }

    List<String> path = [end];
    print("traveled ${distances[end]}");
    while (path.last != beg) {
      path.add(previous[path.last]!);
    }


    return path.reversed.toList();
  }
}

Tok tokType(String source) {
  switch (source) {
    case '+': return Tok.join;
    case '[': return Tok.openBrckt;
    case ']': return Tok.closeBrckt;
    case ':': return Tok.colon;
    case ',': return Tok.comma;
    case '--': return Tok.arrow;
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
  Tok edgeType = Tok.arrow;
  List<String> head = [''];
  int brcktDepth = 0;

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

      case Tok.sym:
        vertices.putIfAbsent(toks[i], () => Vertex());
        String lhs = '';

        if (head.last.isEmpty && brcktDepth > 0) {
          lhs = head[head.length - 2];
        } else if (head.isNotEmpty) {
          lhs = head.last;
        }

        double weight = 1;
        if (toks.length > i + 1 && tokType(toks[i+1]) == Tok.colon) {
          assert(tokType(toks[i+2]) == Tok.num);
          weight = double.parse(toks[i+2]);
        }

        if (lhs.isNotEmpty) {
          switch (edgeType) {
            case Tok.arrow:
              vertices[lhs]!.addEdge(toks[i], weight);
              vertices[toks[i]]!.addEdge(lhs, weight);
              break;

            case Tok.leftArrow:
              vertices[toks[i]]!.addEdge(lhs, weight);
              break;

            case Tok.rightArrow:
              vertices[lhs]!.addEdge(toks[i], weight);
              break;

            default: throw Exception('unreachable!');
          }
        }

        head.last = toks[i];
        edgeType = Tok.arrow;
        break;

      case Tok.colon:
        assert(tokType(toks[i+1]) == Tok.num);
        break;

      case Tok.num:
        assert(tokType(toks[i-1]) == Tok.colon);
        break;

      case Tok.arrow: 
      case Tok.leftArrow: 
      case Tok.rightArrow: 
        assert(tokType(toks[i + 1]) == Tok.sym);
        edgeType = tokType(toks[i]);
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
