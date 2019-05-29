module lang::nescio::API

import Relation;

data TypeName = typeName(list[str] modules, str name);

alias StructuredGraph = rel[TypeName typeName, str field, TypeName fieldType];

alias Types = set[TypeName typeName];

data PathConfig = pathConfig(list[loc] srcs = []);

alias GraphCalculator = StructuredGraph(str moduleName, PathConfig cfg);

data Path
    = field(Path src, str fieldName)
    | rootType(TypeName typeName)
    | fieldType(Path src, TypeName typeName)
    | deepMatchType(Path src, TypeName typeName)
    ;
    
data NamedPattern
	=  pattern(str name, Path path);

Types getTypes(field(Path src, str fieldName), StructuredGraph fields)
	= {fieldType | <typeName, fieldName, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(fieldType(Path src, TypeName fieldType), StructuredGraph fields)
	= {fieldType | <typeName, _, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(deepMatchType(Path src, TypeName typeName), StructuredGraph fields)
	= typeName in range(graph+) ? {typeName} : {}  
	when graph := {<tn, fieldType> | <tn, _, fieldType> <- fields}; 
		
Types getTypes(rootType(typeName), StructuredGraph fields)
	= {typeName | <typeName, _, _> <- fields};
		
bool isValidPath(Path p, StructuredGraph fields) =
	_ <- [t | t <- types, t in leaves] 
	when leaves := {fieldType | row:<_, _, fieldType> <- fields, fieldType notin domain(fields)},
		 types := getTypes(p, fields); 

