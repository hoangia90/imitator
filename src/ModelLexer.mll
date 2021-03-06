(*****************************************************************
 *
 *                       IMITATOR
 * 
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Universite Paris 13, Sorbonne Paris Cite, LIPN (France)
 * 
 * Author:        Etienne Andre
 * 
 * Created       : 2009/09/07
 * Last modified : 2013/03/11
*****************************************************************)

{
open ModelParser

(* OCaml style comments *)
let comment_depth = ref 0;;

let line=ref 1;;

}

rule token = parse
	  ['\n']             { line := !line + 1 ; token lexbuf }     (* skip new lines *)
	| [' ' '\t']         { token lexbuf }     (* skip blanks *)
	| "--" [^'\n']* '\n' { line := !line + 1 ; token lexbuf }     (* skip Hytech-style comments *)

	(* C style comments *)
	| "/*"
		{ comment_depth := 1;
		comment_c lexbuf;
		token lexbuf }
	(* OCaml style comments *)
	| "(*"
		{ comment_depth := 1;
		comment_ocaml lexbuf;
		token lexbuf }

(* 	| "all"            { CT_ALL } *)
 	| "always"         { CT_ALWAYS }
(* 	| "analog"         { CT_ANALOG } *)
	| "and"            { CT_AND }
(* 	| "asap"           { CT_ASAP } *)
	| "automaton"      { CT_AUTOMATON }
(* 	| "backward"       { CT_BACKWARD } *)
	| "bad"            { CT_BAD }
 	| "before"         { CT_BEFORE }
	| "carto"          { CT_CARTO }
	| "clock"          { CT_CLOCK }
	| "discrete"       { CT_DISCRETE }
	| "do"             { CT_DO }
(* 	| "else"           { CT_ELSE } *)
(* 	| "empty"          { CT_EMPTY } *)
	| "end"            { CT_END }
(* 	| "endhide"        { CT_ENDHIDE } *)
(* 	| "endif"          { CT_ENDIF } *)
(* 	| "endreach"       { CT_ENDREACH } *)
(* 	| "endwhile"       { CT_ENDWHILE } *)
 	| "eventually"     { CT_EVENTUALLY }
 	| "everytime"      { CT_EVERYTIME }
	| "False"          { CT_FALSE }
(* 	| "forward"        { CT_FORWARD } *)
(* 	| "free"           { CT_FREE } *)
(* 	| "from"           { CT_FROM } *)
(* 	| "good"           { CT_GOOD } *)
	| "goto"           { CT_GOTO }
 	| "happened"       { CT_HAPPENED }
 	| "has"            { CT_HAS }
(* 	| "hide"           { CT_HIDE } *)
(* 	| "hull"           { CT_HULL } *)
	| "if"             { CT_IF }
(* 	| "in"             { CT_IN } *)
	| "init"           { CT_INIT }
	| "initially"      { CT_INITIALLY }
(* 	| "integrator"     { CT_INTEGRATOR } *)
(* 	| "iterate"        { CT_ITERATE } *)
	| "loc"            { CT_LOC }
	| "locations"      { CT_LOCATIONS }
	| "next"           { CT_NEXT }
(* 	| "non_parameters" { CT_NON_PARAMETERS } *)
	| "not"            { CT_NOT }
(* 	| "omit"           { CT_OMIT } *)
 	| "once"           { CT_ONCE }
	| "or"             { CT_OR }
	| "parameter"      { CT_PARAMETER }
(* 	| "post"           { CT_POST } *)
(* 	| "pre"            { CT_PRE } *)
(* 	| "print"          { CT_PRINT } *)
(* 	| "prints"         { CT_PRINTS } *)
 	| "property"       { CT_PROPERTY }
(* 	| "printsize"      { CT_PRINTSIZE } *)
(* 	| "reach"          { CT_REACH } *)
	| "region"         { CT_REGION }
	| "sequence"       { CT_SEQUENCE }
	| "stop"           { CT_STOP }
(* 	| "stopwatch"      { CT_STOPWATCH } *)
	| "sync"           { CT_SYNC }
	| "synclabs"       { CT_SYNCLABS }
 	| "then"           { CT_THEN }
(* 	| "to"             { CT_TO } *)
(* 	| "trace"          { CT_TRACE } *)
	| "True"           { CT_TRUE }
(* 	| "unknown"        { CT_UNKNOWN } *)
 	| "unreachable"    { CT_UNREACHABLE }
(* 	| "using"          { CT_USING } *)
	| "var"            { CT_VAR }
	| "wait"           { CT_WAIT }
(* 	| "weakdiff"       { CT_WEAKDIFF } *)
(* 	| "weakeq"         { CT_WEAKEQ } *)
(* 	| "weakge"         { CT_WEAKGE } *)
(* 	| "weakle"         { CT_WEAKLE } *)
	| "when"           { CT_WHEN }
	| "while"          { CT_WHILE }
	| "within"         { CT_WITHIN }

	| ['a'-'z''A'-'Z']['a'-'z''A'-'Z''_''0'-'9']* as lxm { NAME lxm }
	| ['0'-'9']*'.'['0'-'9']+ as lxm { FLOAT lxm } 
	| ['0'-'9']+ as lxm { INT(NumConst.numconst_of_string lxm) }
	| '"' [^'"']* '"' as lxm { STRING lxm } (* a string between double quotes *)

	| "<="             { OP_LEQ }
	| ">="             { OP_GEQ }
	| '<'              { OP_L }
	| '='              { OP_EQ }
	| '>'              { OP_G }
	| ":="             { OP_ASSIGN }

	| '+'              { OP_PLUS }
	| '-'              { OP_MINUS }
	| '*'              { OP_MUL }
	| '/'              { OP_DIV }

	| '('              { LPAREN }
	| ')'              { RPAREN }
	| '{'              { LBRACE }
	| '}'              { RBRACE }
	| '['              { LSQBRA }
	| ']'              { RSQBRA }

	| '&'              { AMPERSAND }
	| ','              { COMMA }
	| '\''             { APOSTROPHE }
	| '|'              { PIPE }
	| ':'              { COLON }
	| ';'              { SEMICOLON }

	| eof              { EOF}
	| _ { failwith("Unexpected symbol '" ^ (Lexing.lexeme lexbuf) ^ "' at line " ^ string_of_int !line)}



(* C style comments *)
and comment_c = parse
    "/*"  { incr comment_depth; comment_c lexbuf }
  | "*/"  { decr comment_depth;
            if !comment_depth == 0 then () else comment_c lexbuf }
  | eof
    { failwith "End of file inside a comment." }
	
  | '\n'  { line := !line + 1 ; comment_c lexbuf }
  | _     { comment_c lexbuf }
  
(* OCaml style comments *)
and comment_ocaml = parse
    "(*"  { incr comment_depth; comment_ocaml lexbuf }
  | "*)"  { decr comment_depth;
            if !comment_depth == 0 then () else comment_ocaml lexbuf }
  | eof
    { failwith "End of file inside a comment." }
  | '\n'  { line := !line + 1 ; comment_ocaml lexbuf }
  | _     { comment_ocaml lexbuf }
