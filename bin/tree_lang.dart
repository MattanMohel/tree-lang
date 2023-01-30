import 'dart:io';

import 'lex.dart';

/// Path to tree data
const dataPath = "res/test.tr";

void main() async {
  var str = await File(dataPath).readAsString();
  var toks = extractToks(str);
  var nodes = parseToks(toks);

  for (var node in nodes) {
    print("node $node is connected to ${node.connections}");
  }
}
