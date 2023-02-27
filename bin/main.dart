import 'lex.dart';

/// Path to tree data
const dataPath = "res/test.tr";

void main() async {

  tree("A <- B [D [<- A] E] -> C + D <- F");

}
