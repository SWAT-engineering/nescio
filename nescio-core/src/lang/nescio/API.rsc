module lang::nescio::API

alias Fields = rel[str typeName, str field, str fieldType];

data StructuredGraph = graph(str name, Fields definedFields);

data PathConfig = pathConfig(list[loc] srcs = []);

alias GraphCalculator = StructuredGraph(str moduleName, PathConfig cfg);

data Path
    = field(str fieldName)
    | derefField(str fieldName, Path child)
    | rootType(str typeName, Path child)
    | deepMatchType(str typeName)
    | deepMatchType(str typeName, Path child)
    ;

Fields getValidPath(field(str fieldName), Fields fields)
	= {row | row:<typeName, field, fieldType> <- fields, field == fieldName};
	
Fields getValidPath(derefField(fieldName, child), Fields fields)
	= {row | row:<typeName, field, fieldType> <- getValidPath(child, fields), field == fieldName};
	
Fields getValidPath(rootType(typeName, child), Fields fields)
	= {row | row:<typeName, _, _> <- getValidPath(child, fields)}; 

bool isValidPath(Path path, Fields fields) = getValidPath(path, fields) != {};