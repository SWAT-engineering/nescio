module lang::record::Syntax

extend lang::std::Layout;


keyword Reserved = "record" | "instance" | "int" | "str" ;
start syntax Records =
	Record* record
	Instance* instances;
	
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
	
syntax Instance = "instance" Id "ofrecord" Id "["
	FieldAssignment*
"]";

syntax FieldAssignment = Id ":" Expr;

syntax Type
	= "int"
	| "str"
	;
	
syntax Expr 
	= NatLiteral
	| StringLiteral
	;	
	
lexical NatLiteral
	=  @category="Constant" [0-9 _]+ !>> [0-9 _]
	;

lexical StringLiteral
	= @category="Constant" "\"" StringCharacter* chars "\"" ;	
	
lexical StringCharacter
	= "\\" [\" \\ b f n r t] 
	| ![\" \\]+ >> [\" \\]
	| UnicodeEscape 
	;
	
lexical UnicodeEscape
	= utf16: "\\" [u] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
	| utf32: "\\" [U] (("0" [0-9 A-F a-f]) | "10") [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] // 24 bits 
	| ascii: "\\" [a] [0-7] [0-9A-Fa-f]
	;


