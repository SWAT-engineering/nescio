module lang::nescio::API

import Relation;

alias Fields = rel[str typeName, str field, str fieldType];

alias Types = set[str typeName];

data StructuredGraph = graph(str name, Fields definedFields);

data PathConfig = pathConfig(list[loc] srcs = []);

alias GraphCalculator = StructuredGraph(str moduleName, PathConfig cfg);

data Path
    = field(Path src, str fieldName)
    | rootType(str typeName)
    | fieldType(Path src, str typeName)
    | deepMatchType(Path src, str typeName)
    ;

Types getTypes(field(Path src, str fieldName), Fields fields)
	= {fieldType | <typeName, fieldName, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(fieldType(Path src, str fieldType), Fields fields)
	= {fieldType | <typeName, _, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(deepMatchType(Path src, str typeName), Fields fields)
	= typeName in range(graph*) ? {typeName} : {}  
	when graph := {<typeName, fieldType> | <typeName, _, fieldType> <- fields};
		
Types getTypes(rootType(typeName), Fields fields)
	= {typeName | <typeName, _, _> <- fields};
		
bool isValidPath(Path p, Fields fields) =
	_ <- [t | t <- types, t in leaves] 
	when leaves := {fieldType | row:<_, _, fieldType> <- fields, fieldType notin domain(fields)},
		 types := getTypes(p, fields); 

