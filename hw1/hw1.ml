let subset a b =
	let in_b x = List.mem x b in
	List.for_all (in_b) a;;

let equal_sets a b = (subset a b) && (subset b a);;

let rec set_union a b =
	match a with
	| [] -> b
	| x::xs -> if List.mem x b then set_union xs b else x::set_union xs b

let rec set_intersection a b =
	match a with
	| [] -> []
	| x::xs -> if List.mem x b then x :: set_intersection xs b else set_intersection xs b;;

let rec set_diff a b =
	match a with
	| [] -> []
	| x::xs -> if List.mem x b then set_diff xs b else x :: set_diff xs b;;

let rec computed_fixed_point eq f x =
    if eq (f x) x then x else computed_fixed_point eq f (f x);;

let rec solve_n_times f n x = if n = 0 then x else solve_n_times f (n-1) (f x);;

let rec computed_periodic_point eq f p x =
	match p with
	| 0 -> x
	| 1 -> computed_fixed_point eq f x
	| n -> if eq (solve_n_times f n x) x then x else computed_periodic_point eq f n (f x);;

let rec while_away s p x = if (p x) then x :: while_away s p (s x) else [];;

let rec rle_decode lp =
	let rec tnsl (n,x) = if n = 0 then [] else x::tnsl (n-1,x) in
	match lp with
	| [] -> []
	| (n,x)::t -> tnsl (n,x) @ rle_decode t;;

type ('nonterminal, 'terminal) symbol =
	| N of 'nonterminal
	| T of 'terminal;;

let rec symbol_in_list lhs_list symbol = match lhs_list with
	| [] -> false
	| x::xs -> if N x = symbol then true else symbol_in_list xs symbol;;

let is_terminal good_lhs rhs  = List.for_all (fun x -> match x with | T y -> true | N y -> symbol_in_list good_lhs x) rhs;;

let rec find_good_lhs rules good_lhs = match rules with
		| [] -> good_lhs
		| x::xs -> 	if (is_terminal good_lhs (snd x) && not (List.mem (fst x) good_lhs)) 
						then find_good_lhs xs ((fst x)::good_lhs)
					else find_good_lhs xs good_lhs;;

let filter_blind_alleys g =
	fst g, List.filter (fun x -> is_terminal (computed_fixed_point (equal_sets) (find_good_lhs (snd g)) []) (snd x)) (snd g);;