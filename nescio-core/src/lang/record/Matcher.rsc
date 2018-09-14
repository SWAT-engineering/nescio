module lang::record::Matcher

import lang::record::Syntax;
import lang::nescio::NamedGraph;
import ParseTree;

Graph match((Records) `<Record* rs> <Instance* is>`){
	//map[str, Record] recordsMap = ("<id>": r  | r <- rs, (Record) `record <Id id> { <Field* fs> }` := r);
	set[Node] nodes = {};
	rel[str, str] edges = {};
	for (Instance i <- is){
		tuple[set[Node], rel[str,str]] result = match(i);
		nodes += result[0];
		edges += result[1];
	};	
	return graph(nodes, edges);
}


tuple[set[Node], rel[str,str]] match ((Instance) `instance <Id iid> ofrecord <Id rid> [ <FieldAssignment* fas>]`) =
	<{ labeledNode("<iid>", "<rid>", -1, -1, "")} + calculateNodes("<iid>", fas), calculateEdges("<iid>", fas)>;
	
rel[str,str] calculateEdges(str instanceId, FieldAssignment* fas) =
	{<instanceId, fieldName> | fieldName <- fieldNames}
	when set[str] fieldNames := {buildNodeId("<instanceId>","<id>") | (FieldAssignment) `<Id id> : <Expr epr>` <- fas}; 

set[Node] calculateNodes(str instanceId, FieldAssignment* fas) =
	{labeledNode(buildNodeId("<instanceId>","<id>"), "<id>", (expr@\loc).offset, (expr@\loc).length, "<expr>") | (FieldAssignment) `<Id id> : <Expr expr>` <- fas}; 	
	
str buildNodeId(str containerId, str fieldId) = "<containerId>::<fieldId>";