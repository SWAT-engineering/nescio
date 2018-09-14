module lang::nescio::Transformer

import lang::nescio::Syntax;
import lang::nescio::NamedGraph;
import IO;
import List;

map[tuple[int,int], str] transform((Program) `module <Id moduleId> <Import* imports> <Decl* decls>`, Graph ng)
	= transform(decls, ng);
	
map[tuple[int,int], str] transform(Decl* decls, Graph ng)
	= toMap([transform(d, ng, trafos) | d <- rules])
	when rules := [r | Rule r <- decls],
		 trafos := [t | Trafo t <- decls],
		 bprintln([transform(d, ng, trafos) | d <- rules]);
	
	
tuple[tuple[int,int], str] transform((Rule) `rule <Id rId> : <Pattern p> =\> <Id tId>`, Graph ng, list[Trafo] ts)
	= <<n.offset, n.length>, transformed>
	when Trafo t0 := getOneFrom([t | Trafo t <- ts, (Trafo) `@ (<JavaId jId>) trafo <Id id> <Formals? fs>` := t, id == tId]),
		 Node n := findNode(p, ng),
		 str transformed := transform(n.content, t0);
		 
str transform(str content, (Trafo) `@ (<JavaId jId>) trafo <Id id> <Formals? fs>` )
	= stringChars([stringChar(48) |_ <- chars(content)]);
	
Node findNode(Pattern p, g:graph(nodes,edges)) = findNode(p, g, rootIds)
	when rootIds := findRootIds(g);
	
set[str] findRootIds(g:graph(nodes,edges)) = {};
	
Node findNode(Id tyId, graph(nodes,edges), set[str] currentRoots){
	if ("<id>" in currentRoots)
		return getOneFrom([n | n <- nodes, labeledNode(_, id, _, _, _, _) := n, id == "<tyId>"]);
	else
		throw "Not found node";
}
	
Node findNode((Pattern) `<Id id>.<Pattern p>`, graph(nodes,edges), set[str] currentRoots){
	if ("id" in currentRoots){
	   labeledNode(uid, _, _, _, _, _) = getOneFrom([n | n <- nodes, labeledNode(uid, _, _, _, _, _) := n, uid == "<id>"]);
	   return findNode(p, graph(nodes,edges), edges[uid]);
	}
	else
		throw "Not found node";
}