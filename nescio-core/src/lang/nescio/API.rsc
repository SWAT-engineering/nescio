module lang::nescio::API

import Relation;

alias StructuredGraph = rel[str typeName, str field, str fieldType];

alias Types = set[str typeName];

data PathConfig = pathConfig(list[loc] srcs = []);

alias GraphCalculator = StructuredGraph(str moduleName, PathConfig cfg);

data Path
    = field(Path src, str fieldName)
    | rootType(str typeName)
    | fieldType(Path src, str typeName)
    | deepMatchType(Path src, str typeName)
    ;

Types getTypes(field(Path src, str fieldName), StructuredGraph fields)
	= {fieldType | <typeName, fieldName, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(fieldType(Path src, str fieldType), StructuredGraph fields)
	= {fieldType | <typeName, _, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(deepMatchType(Path src, str typeName), StructuredGraph fields)
	= typeName in range(graph+) ? {typeName} : {}  
	when graph := {<tn, fieldType> | <tn, _, fieldType> <- fields}; 
		
Types getTypes(rootType(typeName), StructuredGraph fields)
	= {typeName | <typeName, _, _> <- fields};
		
bool isValidPath(Path p, StructuredGraph fields) =
	_ <- [t | t <- types, t in leaves] 
	when leaves := {fieldType | row:<_, _, fieldType> <- fields, fieldType notin domain(fields)},
		 types := getTypes(p, fields); 

