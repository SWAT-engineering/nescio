module lang::nescio::Syntax

extend lang::std::Layout;

start syntax Program =
	"module" ModuleId
	Import* imports
	Decl* declarations;
	
keyword Reserved = "import" | "from" | "rule" |  "=\>" | "**" | "algorithm" | "int" | "str" | "bool" | "true" | "false";
	
lexical JavaId 
	= [a-z A-Z 0-9 _] !<< [a-z A-Z][a-z A-Z 0-9 _ .]* !>> [a-z A-Z 0-9 _]
	;

lexical Id 
	=  (([a-z A-Z 0-9 _]) !<< ([a-z A-Z])[a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _]) \ Reserved 
	;

lexical ModuleId
    = {Id "::"}+ moduleName
    ;

syntax Import
	= "import" ModuleId moduleId "from" Id langId
	;
	
syntax Prog
	= Import* Decl*
	;
	
syntax Decl
	= Rule
	| Trafo
	| ConstantDecl
	;
	
syntax ConstantDecl
	= Type Id "=" Expr;	
	
syntax Rule
	= "rule" Id ":" Pattern "=\>" Id Args?
	;	

syntax Pattern
	= ModuleId
	| Pattern "\a2F" Id
	| Pattern "\a2F" "[" ModuleId "]"
	| Pattern "\a2F" "**" "\a2F"  ModuleId
	;
	
syntax Trafo
	= "@" "(" JavaId ")" "algorithm" Id Formals?
	;

syntax Formals
	= "(" {Formal "," }* formals  ")"
	;
	
syntax Args
	= "(" {Expr "," }* args  ")"
	;
	
syntax Formal = Type typ Id id;

syntax Type
	= "int"
	| "str"
	| "bool"
	;
	
syntax Expr 
	= NatLiteral
	| BoolLiteral
	| HexIntegerLiteral
	| BitLiteral
	| StringLiteral
	| Id
	;	
	
	
lexical BoolLiteral = "true" | "false";
	
lexical NatLiteral
	=  @category="Constant" [0-9 _]+ !>> [0-9 _]
	;

lexical HexIntegerLiteral
	=  [0] [X x] [0-9 A-F a-f _]+ !>> [0-9 A-F a-f _] ;

lexical BitLiteral 
	= "0b" [0 1 _]+ !>> [0 1 _];
	
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


