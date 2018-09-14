module lang::nescio::NamedGraph

data Graph = graph(set[Node] nodes, rel[str, str] edges);

data Node = labeledNode(str uid, str \type, int offset, int length, str content, bool isStart = false);