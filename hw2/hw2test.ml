let accept_all derivation string = Some (derivation, string)

type animals_nonterminals = 
	| Bird | Fish | Reptile | Egg | Animal | Verb

let animals_rules = 
	[Animal, [N Bird; N Fish; N Reptile];
	Animal, [N Bird; N Verb; N Fish];
	Bird, [T"Penguin"];
	Fish, [T"Shark"];
	Fish, [T"Goldfish"; N Verb; N Egg];
	Reptile, [T"Snake"];
	Egg, [T"Egg"];
	Verb, [T"Lays"];
	Verb, [T"Hates"]; 
	Verb, [T"Eats"]]

let animals_grammar = Animal, animals_rules

let test_1 = ((parse_prefix (convert_grammar animals_grammar) accept_all ["Penguin"; "Eats"; "Goldfish"; "Lays"; "Egg"]) 
	= Some ([(Animal, [N Bird; N Verb; N Fish]); (Bird, [T "Penguin"]);
   			(Verb, [T "Eats"]); (Fish, [T "Goldfish"; N Verb; N Egg]);
   			(Verb, [T "Lays"]); (Egg, [T "Egg"])], []))


type awksub_nonterminals =
  | Expr | Term | Lvalue | Incrop | Binop | Num | Variable

let awkish_grammar =
  (Expr,
   function
     | Expr ->
         [[N Term; N Binop; N Expr];
          [N Term];]
     | Term ->
	 [[N Num];
	  [N Lvalue];
	  [N Incrop; N Lvalue];
	  [N Lvalue; N Incrop];
	  [T"("; N Expr; T")"];
	  [N Variable; T"^"; N Num]]
     | Lvalue ->
	 [[T"$"; N Expr]]
     | Incrop ->
	 [[T"++"];
	  [T"--"]]
     | Binop ->
	 [[T"+"];
	  [T"-"]]
	 | Variable -> 
	 [[T"x"]; [T"y"]]
     | Num ->
	 [[T"0"]; [T"1"]; [T"2"]; [T"3"]; [T"4"];
	  [T"5"]; [T"6"]; [T"7"]; [T"8"]; [T"9"]])

let rec contains_quadratic = function
	| [] -> false
	| rl::rls -> if (snd rl) = [N Num; T"^"; N Num] then true
				 else contains_quadratic rls

let accept_only_quadratic rules frag =
  if contains_quadratic rules
  then None
  else Some (rules, frag)

let test_2 = ((parse_prefix awkish_grammar accept_only_quadratic ["x"; "^"; "2"; "+"; "3"])
	= Some ([(Expr, [N Term; N Binop; N Expr]); (Term, [N Variable; T "^"; N Num]);
   			(Variable, [T "x"]); (Num, [T "2"]); (Binop, [T "+"]); (Expr, [N Term]);
   			(Term, [N Num]); (Num, [T "3"])], [])) 