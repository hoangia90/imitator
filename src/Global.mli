(*****************************************************************
 *
 *                     IMITATOR II
 *
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Author:        Etienne Andre
 * Created:       2009/09/08
 * Last modified: 2010/05/07
 *
 ****************************************************************)

(****************************************************************)
(** Version string *)
(****************************************************************)

val version_string: string
val print_version_string: unit -> unit

(****************************************************************)
(** Exceptions *)
(****************************************************************)
exception InternalError of string

(** Parsing exception: starting position of the error symbol, ending position of the error symbol *)
exception ParsingError of (int * int)

(** Mode for IMITATOR *) 
type imitator_mode =
	(** Classical parametric reachability analysis *)
	| Reachability_analysis
 	(** Reachability using predicate abstraction *)
	| AbstractReachability
	(** Classical inverse method *)
	| Inverse_method
	(** Cover the whole cartography *)
	| Cover_cartography
	(** Randomly pick up values for a given number of iterations *)
	| Random_cartography of int



(****************************************************************)
(** Debug modes *)
(****************************************************************)

type debug_mode =
	| Debug_error (* c'est quoi ca ? *)
	| Debug_nodebug
	| Debug_standard
	| Debug_low
	| Debug_medium
	| Debug_high
	| Debug_total


(* Return true if the global debug mode is greater than 'debug_mode', false otherwise *)
val debug_mode_greater : debug_mode -> bool

(* Convert a string into a debug_mode; raise Not_found if not found *)
val debug_mode_of_string : string -> debug_mode

(* Set the debug mode *)
val set_debug_mode : debug_mode -> unit

(* Get the debug mode *)
val get_debug_mode : unit -> debug_mode


(****************************************************************)
(** Global time counter *)
(****************************************************************)

(** Get the value of the counter *)
val get_time : unit -> float

(** Compute the duration since time t *)
val time_from : float -> float

(** Print a number of seconds *)
val string_of_seconds : float -> string

(** Create a string of the form 'after x seconds', where x is the time since the program started *)
val after_seconds : unit -> string

(** Set the timed mode *)
val set_timed_mode : unit -> unit


(****************************************************************)
(** Useful functions on lists *)
(****************************************************************)
(** Check if a list is empty *)
val list_empty : 'a list -> bool

(** Return a random element in a list *)
val random_element : 'a list -> 'a

(** list_of_interval a b Create a fresh new list filled with elements [a, a+1, ..., b-1, b] *)
val list_of_interval : int -> int -> int list

(** Intersection of 2 lists (keeps the order of the elements as in l1) *)
val list_inter : 'a list -> 'a list -> 'a list

(** Union of 2 lists *)
val list_union : 'a list -> 'a list -> 'a list

(** Tail-recursive function for 'append' *)
val list_append : 'a list -> 'a list -> 'a list

(** Return a list where every element only appears once *)
val list_only_once : 'a list -> 'a list

(** Filter the elements appearing several times in the list *)
val elements_existing_several_times : 'a list -> 'a list

(****************************************************************)
(** Variable sets *)
(****************************************************************)

type variable_index = int
type clock_index = variable_index
type parameter_index = variable_index
type discrete_index = variable_index
type variable_name = string
type value = NumConst.t

module VariableSet: Set.S with type elt=variable_index 

(****************************************************************)
(** Useful functions on arrays *)
(****************************************************************)

(* Check if an element belongs to an array *)
val in_array : 'a -> 'a array -> bool

(* Returns the (first) index of an element in an array, or raise Not_found if not found *)
val index_of : 'a -> 'a array -> int

(* Return the list of the indexes whose value is true *)
val true_indexes : bool array -> int list

(** exists p {a1; ...; an} checks if at least one element of the Array satisfies the predicate p. That is, it returns (p a1) || (p a2) || ... || (p an). *)
val array_exists : ('a -> bool) -> 'a array -> bool


(****************************************************************)
(** Useful functions on dynamic arrays *)
(****************************************************************)

(* exists p {a1; ...; an} checks if at least one element of the DynArray satisfies the predicate p. That is, it returns (p a1) || (p a2) || ... || (p an). *)
val dynArray_exists : ('a -> bool) -> 'a DynArray.t -> bool


(****************************************************************)
(** Useful functions on string *)
(****************************************************************)
(* Convert an array of string into a string *)
val string_of_array_of_string : string array -> string

(* Convert a list of string into a string *)
val string_of_list_of_string : string list -> string

(* Convert an array of string into a string with separators *)
val string_of_array_of_string_with_sep : string -> string array -> string

(* Convert a list of string into a string with separators *)
val string_of_list_of_string_with_sep : string -> string list -> string

(* 's_of_int i' Return "s" if i > 1, "" otherwise *)
val s_of_int : int -> string

(****************************************************************)
(** Useful functions on booleans *)
(****************************************************************)
(* Evaluate both part of an 'and' comparison and return the conjunction *)
val evaluate_and : bool -> bool -> bool

(* Evaluate both part of an 'or' comparison and return the disjunction *)
val evaluate_or : bool -> bool -> bool


(****************************************************************)
(** Messages *)
(****************************************************************)
(*(* Print a message if global_debug_mode >= message_debug_mode *)
val print_debug_message : debug_mode -> debug_mode -> string -> unit*)

(* Print a message if global_debug_mode >= message_debug_mode *)
val print_message : debug_mode -> string -> unit

(* Print a warning *)
val print_warning : string -> unit

(* Print an error *)
val print_error : string -> unit


(****************************************************************)
(** Terminating functions *)
(****************************************************************)
(* Abort program *)
val abort_program : unit -> unit

(* Terminate program *)
val terminate_program : unit -> unit
