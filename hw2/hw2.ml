type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

let rec find_rhs rules lhs = match rules with
	| [] -> []
	| rule::more -> if lhs = fst rule then snd rule :: find_rhs more lhs else find_rhs more lhs

let convert_grammar gram1 = 
	let start = fst gram1 and rules = snd gram1 in
	start, fun x -> find_rhs rules x

let rec matcher rules start curr_rules accept derv frag = match curr_rules with
  | [] -> None
  | rl::rls -> match (try_prefix rules rl accept (derv @ [start, rl]) frag) with
                | None -> matcher rules start rls accept derv frag
                | ok -> ok
and try_prefix rules rule accept derv frag = match rule, frag with
  | [], [] -> accept derv frag
  | _, [] -> None 
  | [], _ -> accept derv frag
  | (N sym)::syms, pref::suff -> (matcher rules sym (rules sym) (try_prefix rules syms accept) derv frag)  
  | (T sym)::syms, pref::suff -> if sym = pref then (try_prefix rules syms accept derv suff) 
                                 else None

let parse_prefix gram accept frag = 
  let start = fst gram and rules = snd gram in
  matcher rules start (rules start) accept [] frag;;