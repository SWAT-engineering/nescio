module lang::record::Syntax

extend lang::std::Layout;

// TODO check what happens with example-record.nescio if we add "record" here, since that coincides with the name
// of the language being imported
keyword Reserved =  "int" | "str" ;

start syntax Records =
	Record* record;
	
lexical Id 
	=  (([a-z A-Z 0-9 _]) !<< ([a-z A-Z])[a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _]) \ Reserved 
	;

	
syntax Record
	= "record" Id "["
		Field*
	  "]"
	  
	;
	
syntax Field
	= Type Id
	;	

syntax Type
	= "int"
	| "str"
	| Id
	;
	
