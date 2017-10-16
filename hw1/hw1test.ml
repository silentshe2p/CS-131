let my_subset_test0 = subset [2;3] [1;2;3;4]

let my_equal_sets_test0 = equal_sets [3;6;9] [6;3;3;9;6]

let my_set_union_test0 = equal_sets (set_union [6;7] [8;9]) [6;7;8;9]

let my_set_intersection_test0 =
  equal_sets (set_intersection [2;3;4;5] [4;5;6;7]) [4;5]

let my_set_diff_test0 = equal_sets (set_diff [1;3;5] [2;3;4;5]) [1]

let my_computed_fixed_point_test0 =
  computed_fixed_point (=) (fun x -> x*x -3*x + 4) 1 = 2

let my_computed_periodic_point_test0 =
  computed_periodic_point (=) (fun x -> x - x*x) 2 1 = 0

let my_while_away_test0 = while_away ((+) 2) ((>) 12) 5 = [5; 7; 9; 11]

let my_rle_decode_test0 = rle_decode [1,"h"; 1,"e"; 2,"l"; 3,"!"] = ["h";"e";"l";"l";"!";"!";"!"]

type animals_nonterminals = 
	| Bird | Fish | Reptile | Egg | Skin | Coldblood

let animals_rules = 
	[Bird, [T"Eagle"; N Egg; T"Parrot"];
	Bird, [T"Penguin"];
	Fish, [T"Shark"];
	Fish, [N Egg; T"Goldfish"];
	Reptile, [T"Snake"; N Skin; N Coldblood];
	Egg, [T"Oval"];
	Skin, [T"Color"; N Bird; N Fish]]

let animals_grammar = Skin, animals_rules

let my_filter_blind_alleys_test0 = filter_blind_alleys animals_grammar = 
	(Skin, 
	[(Bird, [T "Eagle"; N Egg; T "Parrot"]); (Bird, [T "Penguin"]);
	 (Fish, [T "Shark"]); (Fish, [N Egg; T "Goldfish"]); (Egg, [T "Oval"]); 
	 (Skin, [T "Color"; N Bird; N Fish])])
