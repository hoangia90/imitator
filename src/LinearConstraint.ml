(*****************************************************************
 *
 *                     IMITATOR II
 * 
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Author:        Etienne Andre
 * Created:       2010/03/04
 * Last modified: 2010/03/16 TEST TOTO
 *
 ****************************************************************)

(**************************************************)
(* Modules *)
(**************************************************)
open Apron
open Lincons0

open Global

(**************************************************)
(* TYPES *)
(**************************************************)

type variable = int
type coef = NumConst.t

type linear_term = Linexpr0.t

type op =
	| Op_g
	| Op_ge
	| Op_eq

type linear_inequality = Lincons0.t

type linear_constraint = Polka.strict Polka.t Abstract0.t 



(**************************************************)
(** Global variables *)
(**************************************************)

(* The manager *)
let manager = Polka.manager_alloc_strict ()

(* The number of integer dimensions *)
let int_dim = ref 0

(* The number of real dimensions *)
let real_dim = ref 0



(**************************************************)
(* Useful Functions *)
(**************************************************)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(* Conversions to Apron *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(* Convert a variable into a Apron dim *)
let apron_dim_of_variable variable =
	variable

(* Convert a constant into a Apron coeff *)
let apron_coeff_of_constant constant =
	Coeff.s_of_mpq (NumConst.mpq_of_numconst constant)


(* Convert a constant into a Apron coeff option *)
let apron_coeff_option_of_constant constant =
	if NumConst.equal constant NumConst.zero then None
	else Some (apron_coeff_of_constant constant)


(* Convert a constant into a Apron (coeff, dim) *)
let apron_coeff_dim_of_member (coef, variable) =
	apron_coeff_of_constant coef, apron_dim_of_variable variable


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(* Conversion from Apron *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(* Convert a Apron coeff into a constant *)
let constant_of_apron_coeff coeff =
	match coeff with
	| Coeff.Scalar s -> let constant =
		match s with
			| Scalar.Mpqf m -> NumConst.numconst_of_mpq (Mpqf.mpq m)
			| Scalar.Float f -> NumConst.numconst_of_float f
			| Scalar.Mpfrf m -> raise (InternalError "Expecting Apron to use only Mpqf in Scalar, in 'constant_of_apron_coeff' function. Given: Mpfrf.")
			in constant
	| _ -> raise (InternalError "Expecting Apron to use only Scalar coeff in 'constant_of_apron_coeff' function.")


(* Convert a Apron dim into a variable  *)
let variable_of_apron_dim dim =
	dim



(**************************************************)
(** {2 Linear terms} *)
(**************************************************)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Create a linear term using a list of coef and variables, and a constant *)
let make_linear_term members coef =
	(* Convert the members *)
	let members = List.map apron_coeff_dim_of_member members in
	(* Convert the coef *)
	let coeff_option = apron_coeff_option_of_constant coef in
		Linexpr0.of_list None members coeff_option


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Functions} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(* Get the members from a linexpr *)
let members_of_linexpr linexpr =
	let members = ref [] in
		Linexpr0.iter (fun coeff dim ->
			(* Add the member only if not null *)
			let coef = constant_of_apron_coeff coeff in
			if NumConst.neq coef NumConst.zero then (
				(* Add the new member *)
				members := (coef, variable_of_apron_dim dim) :: !members;
			) else (
				(**** Exception to study the behavior of Apron ****)
(* 				raise (InternalError ("A null coef was found for variable " ^ (string_of_int dim) ^ " in an Apron linexpr0.")) *)
				(**** String to study the behavior of Apron ****)
(* 				print_string "$"; *)
				()
			);
		) linexpr;
		(* Return the list *)
		!members


(* Get the constant from a linexpr *)
let constant_of_linexpr linexpr =
	constant_of_apron_coeff (Linexpr0.get_cst linexpr) 


(** Add two linear terms *)
let add_linear_terms lt1 lt2 =
	(* Create an array of coef *)
	let coef_array = Array.make (!int_dim + !real_dim) NumConst.zero in
	(* Get the members *)
	let members1 = members_of_linexpr lt1 in
	let members2 = members_of_linexpr lt2 in
	(* Get the constants *)
	let constant1 = constant_of_linexpr lt1 in
	let constant2 = constant_of_linexpr lt2 in
	(* Update the array *)
	let update_array = List.iter (fun (coef, dim) ->
		coef_array.(dim) <- NumConst.add coef_array.(dim) coef;
	) in
	update_array members1;
	update_array members2;
	(* Convert the array to members *)
	let members = ref [] in
	Array.iteri (fun dim coef ->
		if NumConst.neq coef NumConst.zero
		then members := (coef, dim) :: !members
	) coef_array;
	(* Build the new linear term *)
	make_linear_term
		!members
		(NumConst.add constant1 constant2)


(*--------------------------------------------------*)
(* Evaluation *)
(*--------------------------------------------------*)

(* Evaluate a member w.r.t. pi0. (Raise InternalError if the value for the variable is not defined in pi0) *)
let evaluate_member pi0 (coef, variable) =
	let value =
		try pi0 variable
		with _ ->
			raise (InternalError ("No constant value was found for variable " ^ (string_of_int variable) ^ ", while trying to evaluate a linear term; this variable was probably not defined."));
	in
	NumConst.mul coef value


(* Evaluate a list of members and a constant w.r.t. pi0 *)
let evaluate_members_and_constant pi0 (members, constant) =
	(* Evaluate the members *)
	NumConst.add
	(List.fold_left (fun current_value member -> NumConst.add current_value (evaluate_member pi0 member)) NumConst.zero members)
	(* Add the constant *)
	constant


(** Evaluate a linear term with a function assigning a value to each variable. *)
let evaluate_linear_term valuation_function linear_term =
	(* Get the members *)
	let members = members_of_linexpr linear_term in
	(* Get the constant *)
	let constant = constant_of_linexpr linear_term in
	(* Evaluate *)
	evaluate_members_and_constant valuation_function (members, constant)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Conversion to string} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

let string_of_coef = NumConst.string_of_numconst
let string_of_constant = NumConst.string_of_numconst

(* Convert a member into a string using a name function *)
let string_of_member names (coef, variable) =
	(* Case coef 1 *)
	if NumConst.equal coef NumConst.one then (names variable)
	(* Case coef -1 *)
	else if NumConst.equal coef (NumConst.numconst_of_int (-1)) then ("- " ^ (names variable))
	(* Other case *)
	else ((string_of_coef coef) ^ " * " ^ (names variable))




(* Convert a list of members and a constant into a string *)
let string_of_members_and_constant names members constant =
	match members with
	(* Case: empty list *)
	| [] -> string_of_constant constant
	(* Case: non-empty list *)
	| first :: rest ->
		(* Convert the first *)
		(string_of_member names first)
		(* Convert the rest *)
		^ (List.fold_left (fun the_string (coef, variable) -> 
			the_string
			(* Add the +/- *)
			 ^ (if NumConst.g coef NumConst.zero then " + " else " ")
			(* Convert the member *)
			 ^ (string_of_member names (coef, variable))
		) "" rest)
		(* Convert the constant *)
		^ (if NumConst.neq constant NumConst.zero then(
			(* Add the +/- *)
			 (if NumConst.g constant NumConst.zero then " + " else " ")
			^ (string_of_constant constant)
			) else ""
		)


(** Convert a linear term into a string *)
let string_of_linear_term names linear_term =
(*	(* Old debug *)
	Linexpr0.print names Format.std_formatter linexpr;*)
	(* Get the constant *)
	let constant = constant_of_linexpr linear_term in
	(* Get the list of members *)
	let members = members_of_linexpr linear_term in
	(* Convert to string *)
	string_of_members_and_constant names members constant
	


(**************************************************)
(** {2 Linear inequalities} *)
(**************************************************)

(************** TO DO : minimize inequalities as soon as they have been created / changed *)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(* Functions *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(* Convert an 'op' into a string *)
let string_of_op = function
	| Op_g -> ">"
	| Op_ge -> ">="
	| Op_eq -> "="

(* Convert an Apron Lincons0.typ into a Constraint.op *)
let op_of_apron_typ = function
	| Lincons0.SUP -> Op_g
	| Lincons0.SUPEQ -> Op_ge
	| Lincons0.EQ -> Op_eq
	| _ -> raise (InternalError "Non standard operator in 'op_of_apron_typ' function.")

(* Convert a Constraint.op into a Apron Lincons0.typ *)
let apron_typ_of_op = function
	| Op_g -> Lincons0.SUP
	| Op_ge -> Lincons0.SUPEQ
	| Op_eq -> Lincons0.EQ

(* Convert an op into a NumConst comparison function *)
let numconst_op_of_op = function
	| Op_g -> NumConst.g
	| Op_ge -> NumConst.ge
	| Op_eq -> NumConst.equal


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Create a linear inequality using linear term and an operator *)
let make_linear_inequality linear_term op =
	(* Make the Lincons0 *)
	Lincons0.make linear_term (apron_typ_of_op op)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Functions} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)


(*--------------------------------------------------*)
(* Pi0-compatibility *)
(*--------------------------------------------------*)

(** Check if a linear inequality is pi0-compatible *)
let is_pi0_compatible_inequality pi0 linear_inequality =
	(* Get the linexpr *)
	let linexpr = linear_inequality.linexpr0 in
	(* Get the operator *)
	let op = op_of_apron_typ linear_inequality.typ in
	(* Evaluate the members and constant *)
	let value = evaluate_linear_term pi0 linexpr in
	(* Compare to the operator *)
	let op = numconst_op_of_op op in
	(* Compare *)
	op value NumConst.zero


(** Negate a linear inequality; for an equality, perform the pi0-compatible negation *)
(**** TO OPTIMIZE : should find proper Apron functions to do this (?) *)
let negate_wrt_pi0 pi0 linear_inequality =
	(* Negation function for members and constant *)
	let negate_linear_term members constant =
		make_linear_term
		(List.map (fun (coef, variable) -> NumConst.neg coef, variable) members)
		(NumConst.neg constant)
	in
	(* Get the linexpr *)
	let linexpr = linear_inequality.linexpr0 in
	(* Get the operator *)
	let op = op_of_apron_typ linear_inequality.typ in
	(* Get the members *)
	let members = members_of_linexpr linexpr in
	(* Get the constant *)
	let constant = constant_of_linexpr linexpr in
	(* Negation depends on the operator *)
	match op with
		(* Standard ops: easy *)
		| Op_ge -> make_linear_inequality (negate_linear_term members constant) Op_g
		| Op_g -> make_linear_inequality (negate_linear_term members constant) Op_ge
		(* Equality: consider two cases *)
		| Op_eq ->
			let value = evaluate_members_and_constant pi0 (members, constant) in
			(* Case value > 0 *)
			if NumConst.g value NumConst.zero then make_linear_inequality (make_linear_term members constant) Op_g
			(* Case value < 0 *)
			else if NumConst.l value NumConst.zero then make_linear_inequality (negate_linear_term members constant) Op_g
			else (
				raise (InternalError "Trying to negate an equality already true w.r.t. pi0")
			)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Conversion} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Convert a linear inequality into a string *)
let string_of_linear_inequality names linear_inequality =
	(* Old debug *)
(* 	Lincons0.print names Format.std_formatter linear_inequality; *)
	(* Get the linexpr *)
	let linexpr = linear_inequality.linexpr0 in
	(* Get the operator *)
	let op = op_of_apron_typ linear_inequality.typ in
	(* Get the members *)
	let members = members_of_linexpr linexpr in
	(* Get the constant *)
	let constant = constant_of_linexpr linexpr in
	(* Partition the positive and negative members *)
	let positive_members, negative_members =
		List.partition (fun (coef, variable) -> NumConst.g coef NumConst.zero) members in
	(* Invert the negatives *)
	let inverted_negative_members = List.map (fun (coef, variable) -> (NumConst.neg coef, variable)) negative_members in
	(* Create the constant *)
	let left_constant, right_constant =
		if NumConst.g constant NumConst.zero then constant, NumConst.zero else NumConst.zero, NumConst.neg constant in
	(* Left *)
	(string_of_members_and_constant names positive_members left_constant)
	(* op *)
	^ " " ^ (string_of_op op) ^ " "
	(* Right *)
	^ (string_of_members_and_constant names inverted_negative_members right_constant)



(**************************************************)
(** {2 Linear Constraints} *)
(**************************************************)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Create a linear constraint from a list of linear inequalities *)
let make inequalities =
	(* Call Apron *)
	let linear_constraint =
		Abstract0.of_lincons_array manager !int_dim !real_dim (Array.of_list inequalities)
	in
	(* Minimize it *)
(* 	Abstract0.minimize manager linear_constraint; *)
	(* Return it *)
	linear_constraint

(** Create a false constraint *)
let false_constraint () =
	Abstract0.bottom manager !int_dim !real_dim

(** Create a false constraint *)
let true_constraint () =
	Abstract0.top manager !int_dim !real_dim

(** Set the constraint manager *)
let set_manager int_d real_d =
	int_dim := int_d;
	real_dim := real_d 


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Tests} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Check if a constraint is false *)
let is_false = Abstract0.is_bottom manager

(** Check if a constraint is true *)
let is_true = Abstract0.is_top manager

(** Check if a constraint is satisfiable *)
let is_satisfiable = fun c -> not (is_false c)

(** Check if 2 constraints are equal *)
let is_equal = Abstract0.is_eq manager

(** Check if a constraint is included in another one *)
let is_leq = Abstract0.is_leq manager

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Pi0-compatibility} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Check if a linear constraint is pi0-compatible *)
let is_pi0_compatible pi0 linear_constraint =
	(* Get a list of linear inequalities *)
	let list_of_inequalities = Array.to_list (Abstract0.to_lincons_array manager linear_constraint) in
	(* Check the pi0-compatibility for all *)
	List.for_all (is_pi0_compatible_inequality pi0) list_of_inequalities


(** Compute the pi0-compatible and pi0-incompatible inequalities within a constraint *)
let partition_pi0_compatible pi0 linear_constraint =
	(* Get a list of linear inequalities *)
	let list_of_inequalities = Array.to_list (Abstract0.to_lincons_array manager linear_constraint) in
	(* Partition *)
	List.partition (is_pi0_compatible_inequality pi0) list_of_inequalities


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Conversion} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** String for the false constraint *)
let string_of_false = "false"


(** String for the true constraint *)
let string_of_true = "true"


(** Convert a linear constraint into a string *)
let string_of_linear_constraint names linear_constraint =
	(* Old debug *)
(* 	Abstract0.print names Format.std_formatter linear_constraint; *)
	(* First check if true *)
	if is_true linear_constraint then string_of_true
	(* Then check if false *)
	else if is_false linear_constraint then string_of_false
	else
	(* Get an array of linear inequalities *)
	let array_of_inequalities = Abstract0.to_lincons_array manager linear_constraint in
	(* Convert them to a string *)
	"  " ^
	(string_of_array_of_string_with_sep
		"\n& "
		(Array.map (string_of_linear_inequality names) array_of_inequalities)
	)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Functions} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Performs the intersection of a list of linear constraints *)
let intersection linear_constraints =
	Abstract0.meet_array manager (Array.of_list linear_constraints)


(** Eliminate (using existential quantification) a set of variables in a linear constraint *)
let hide variables linear_constraint =
	Abstract0.forget_array manager linear_constraint (Array.of_list variables) false


(** 'rename_variables renaming_couples c' renames all variables according to the couples of the form (old, new) *)
let rename_variables list_of_couples linear_constraint =
	(* Split the couples *)
	let old_list, new_list = List.split list_of_couples in
	(* Build the array of dimensions *)
	let array_of_dim = Array.of_list old_list in
	(* Build the array of linear expressions *)
	let array_of_linexpr = Array.of_list (
		List.map
		(fun variable -> Linexpr0.of_list None [apron_coeff_dim_of_member (NumConst.one, variable)] None)
		new_list
	) in
	(* Make a substitution *)
	Abstract0.substitute_linexpr_array manager linear_constraint array_of_dim array_of_linexpr None


(** 'add_d d coef variables c' adds a variable 'coef * d' to any variable in 'variables' *)
let add_d d coef variable_list linear_constraint =
	(* Build the array of dimensions *)
	let array_of_dim = Array.of_list variable_list in
	(* Build the array of linear expressions *)
	let array_of_linexpr = Array.of_list (
		List.map
		(fun variable -> Linexpr0.of_list None [apron_coeff_dim_of_member (coef, d); apron_coeff_dim_of_member (NumConst.one, variable)] None)
		variable_list
	) in
	(* Make a substitution *)
	Abstract0.substitute_linexpr_array manager linear_constraint array_of_dim array_of_linexpr None



(*

let of_int = NumConst.numconst_of_int;;
let of_frac = NumConst.numconst_of_frac;;

let names = fun i -> if i = 4 then "d" else ("x" ^ (string_of_int i));;
let pi0 = [| 1; 2; 3; 4 |];;

let pi0 = fun i -> (of_int pi0.(i));;

let int_dim = 0;;
let real_dim = 5;;

LinearConstraint.set_manager int_dim real_dim;;

let lt1 = LinearConstraint.make_linear_term [(of_int (-7), 1); (of_frac (-2) 2, 2); (of_int (0), 3); (of_int (-1), 1); (of_frac 132 64, 3); ] (of_frac (-4) 3);;
let lt2 = LinearConstraint.make_linear_term [(of_int (-1), 2); (of_int (1), 3)] (of_frac (0) (1));;
let lt3 = LinearConstraint.make_linear_term [] (of_frac (-137) (2046));;
let lt4 = LinearConstraint.make_linear_term [] (of_frac (0) (9));;

print_string ("\n lt1 := " ^ (LinearConstraint.string_of_linear_term names lt1));;
print_string ("\n lt2 := " ^ (LinearConstraint.string_of_linear_term names lt2));;
print_string ("\n lt3 := " ^ (LinearConstraint.string_of_linear_term names lt3));;
print_string ("\n lt4 := " ^ (LinearConstraint.string_of_linear_term names lt4));;

print_string ("\n lt1 + lt2 := " ^ (LinearConstraint.string_of_linear_term names (LinearConstraint.add_linear_terms lt1 lt2)));;
print_string ("\n lt1 + lt2 + lt3 := " ^ (LinearConstraint.string_of_linear_term names (LinearConstraint.add_linear_terms (LinearConstraint.add_linear_terms lt1 lt2) lt3)));;

let li1 = LinearConstraint.make_linear_inequality lt1 LinearConstraint.Op_g;;
let li2 = LinearConstraint.make_linear_inequality lt2 LinearConstraint.Op_ge;;
let li3 = LinearConstraint.make_linear_inequality lt3 LinearConstraint.Op_g;;
let li4 = LinearConstraint.make_linear_inequality lt4 LinearConstraint.Op_ge;;

print_string ("\n li1 := " ^ (LinearConstraint.string_of_linear_inequality names li1));;
print_string ("\n li2 := " ^ (LinearConstraint.string_of_linear_inequality names li2));;
print_string ("\n li3 := " ^ (LinearConstraint.string_of_linear_inequality names li3));;
print_string ("\n li4 := " ^ (LinearConstraint.string_of_linear_inequality names li4));;

print_string ("\n li1 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible_inequality pi0 li1)));;
print_string ("\n li2 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible_inequality pi0 li2)));;
print_string ("\n li3 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible_inequality pi0 li3)));;
print_string ("\n li4 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible_inequality pi0 li4)));;


let negate = LinearConstraint.negate_wrt_pi0 pi0;;

print_string ("\n neg li1 := " ^ (LinearConstraint.string_of_linear_inequality names (negate li1)));;
print_string ("\n neg li2 := " ^ (LinearConstraint.string_of_linear_inequality names (negate li2)));;
print_string ("\n neg li3 := " ^ (LinearConstraint.string_of_linear_inequality names (negate li3)));;
print_string ("\n neg li4 := " ^ (LinearConstraint.string_of_linear_inequality names (negate li4)));;

let lc1 = LinearConstraint.make [li1];;
let lc2 = LinearConstraint.make [li2];;
let lc3 = LinearConstraint.make [li3];;
let lc4 = LinearConstraint.make [li4];;
let lc12 = LinearConstraint.make [li1; li2];;

print_string ("\n lc1 := " ^ (LinearConstraint.string_of_linear_constraint names lc1));;
print_string ("\n lc2 := " ^ (LinearConstraint.string_of_linear_constraint names lc2));;
print_string ("\n lc3 := " ^ (LinearConstraint.string_of_linear_constraint names lc3));;
print_string ("\n lc4 := " ^ (LinearConstraint.string_of_linear_constraint names lc4));;
print_string ("\n [li1 ; li2] := " ^ (LinearConstraint.string_of_linear_constraint names lc12));;

print_string ("\n lc1 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible pi0 lc1)));;
print_string ("\n lc2 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible pi0 lc2)));;
print_string ("\n lc3 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible pi0 lc3)));;
print_string ("\n lc4 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible pi0 lc4)));;
print_string ("\n [li1 ; li2] is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible pi0 lc12)));;

let lc1i2 = LinearConstraint.intersection [lc1 ; lc2] in
print_string ("\n lc1 ^ lc2 = " ^ (LinearConstraint.string_of_linear_constraint names lc1i2));;
print_string ("\n lc1 ^ lc3 = " ^ (LinearConstraint.string_of_linear_constraint names (LinearConstraint.intersection [lc1 ; lc3])));;

print_string ("\n lc1 after elimination of x1 : " ^ (LinearConstraint.string_of_linear_constraint names (LinearConstraint.hide [1] lc1)));;

print_string ("\n -------------------");;

let lt1 = LinearConstraint.make_linear_term [(of_int 1, 3); (of_int (-1), 1)] (of_int 0);;
let lt2 = LinearConstraint.make_linear_term [(of_int 1, 1); (of_int (-1), 2)] (of_int 0);;
let li1 = LinearConstraint.make_linear_inequality lt1 LinearConstraint.Op_ge;;
let li2 = LinearConstraint.make_linear_inequality lt2 LinearConstraint.Op_g;;
let lc1 = LinearConstraint.make [li1];;
let lc2 = LinearConstraint.make [li2];;
print_string ("\n lc1 := " ^ (LinearConstraint.string_of_linear_constraint names lc1));;
print_string ("\n lc2 := " ^ (LinearConstraint.string_of_linear_constraint names lc2));;

let lc12 = LinearConstraint.intersection [lc1 ; lc2];;
print_string ("\n lc1 ^ lc2 = " ^ (LinearConstraint.string_of_linear_constraint names lc12));;

print_string ("\n lc1 ^ lc2 is pi-compatible : " ^ (string_of_bool (LinearConstraint.is_pi0_compatible pi0 lc12)));;

let pi0comp, pi0incomp = LinearConstraint.partition_pi0_compatible pi0 lc12;;
print_string ("\n Partition of the inequalities of lc1 ^ lc2 according to their pi0-compatibility:");;
let print_inequalities = List.iter (fun i -> print_string ("\n    - " ^ (LinearConstraint.string_of_linear_inequality names i))) in
print_string ("\n  - pi0-compatible:");
print_inequalities pi0comp;
print_string ("\n  - pi0-incompatible:");
print_inequalities pi0incomp;;

let lc3 = LinearConstraint.hide [1] lc12 in
print_string ("\n (*1) lc1 ^ lc2 after elimination of x1 : " ^ (LinearConstraint.string_of_linear_constraint names lc3));;

(* INCLUSION AND EQUALITY *)

let lc4 = LinearConstraint.make [LinearConstraint.make_linear_inequality (LinearConstraint.make_linear_term [(of_int 1, 3); (of_int (-1), 2)] (of_int 0)) LinearConstraint.Op_ge] in
print_string ("\n (*2) : " ^ (LinearConstraint.string_of_linear_constraint names lc4));;

print_string ("\n (*1) = (*1) : " ^ (string_of_bool (LinearConstraint.is_equal lc3 lc3)));;
print_string ("\n (*1) = (*2) : " ^ (string_of_bool (LinearConstraint.is_equal lc3 lc4)));;
print_string ("\n (*1) <= (*2) : " ^ (string_of_bool (LinearConstraint.is_leq lc3 lc4)));;
print_string ("\n (*1) >= (*2) : " ^ (string_of_bool (LinearConstraint.is_leq lc4 lc3)));;


(* VARIABLE RENAMINGS *)

let renamed = LinearConstraint.rename_variables [(2, 3); (3, 2)] lc12 in
print_string ("\n lc1 ^ lc2 after switching x2 and x3 " ^ (LinearConstraint.string_of_linear_constraint names renamed));;

let with_d = LinearConstraint.add_d 4 (of_int 1) [1] lc12 in
print_string ("\n lc1 ^ lc2 after adding 'd' " ^ (LinearConstraint.string_of_linear_constraint names with_d));;

let with_d = LinearConstraint.add_d 4 (of_int 1) [1; 2] lc12 in
print_string ("\n lc1 ^ lc2 after adding 'd' " ^ (LinearConstraint.string_of_linear_constraint names with_d));;




(*(* APRON TESTS *)

let manager = Polka.manager_alloc_strict () in

let of_int = Coeff.s_of_int in
let linexpr1 = Linexpr0.of_list None [(of_int (1), 0); (of_int (-2), 1); (of_int (3), 2);] (Some (of_int (2))) in
let abstract1 = Abstract0.of_lincons_array manager int_dim real_dim [| Lincons0.make linexpr1 Lincons0.EQ|] in

print_string ("\n Before test: ");
Abstract0.print names Format.std_formatter abstract1;
flush stdout;

let linarray = [|
(*	Linexpr0.of_list None [(of_int 1, 0);] (Some (of_int (-5)));
	Linexpr0.of_list None [(of_int 1, 1);] (Some (of_int (-5)));*)
(*	Linexpr0.of_list None [(of_int (1), 3);] (Some (of_int (0)));
	Linexpr0.of_list None [(of_int (1), 3);] (Some (of_int (0)));*)
	Linexpr0.of_list None [(of_int (1), 1);] (Some (of_int (0)));
	Linexpr0.of_list None [(of_int (1), 0);] (Some (of_int (0)));
	|] in
let test = Abstract0.substitute_linexpr_array manager abstract1 [| 0 ; 1|] linarray None in

print_string ("\n After test: ");
Abstract0.print names Format.std_formatter test;
flush stdout;;*)


print_newline();;

exit 0;;

*)
