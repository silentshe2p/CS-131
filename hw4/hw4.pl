head([H|T], H).
tail([H|T], T).

signal_morse([], []).
signal_morse([1|T], [.|S]) :- \+(head(T, 1)), signal_morse(T, S).
signal_morse([1,1|T], [.|S]) :- \+(head(T, 1)), signal_morse(T, S).
signal_morse([1,1|T], [-|S]) :- \+(head(T, 1)), signal_morse(T, S).
signal_morse([1,1,1|T], [-|S]) :- \+(head(T, 1)), signal_morse(T, S).
signal_morse([1,1,1|T], [-|S]) :- head(T, 1), tail(T, TT), signal_morse([1,1,1|TT], [-|S]).

signal_morse([0|T], S) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0|T], S) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0|T], [^|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0|T], [^|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0,0|T], [^|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0,0,0|T], [^|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0,0,0|T], [#|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0,0,0,0|T], [#|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0,0,0,0,0|T], [#|S]) :- \+(head(T, 0)), signal_morse(T, S).
signal_morse([0,0,0,0,0,0,0|T], [#|S]) :- head(T, 0), tail(T, TT), signal_morse([0,0,0,0,0,0,0|TT], [#|S]).


morse(a, [.,-]).           % A
morse(b, [-,.,.,.]).	   % B
morse(c, [-,.,-,.]).	   % C
morse(d, [-,.,.]).	   % D
morse(e, [.]).		   % E
morse('e''', [.,.,-,.,.]). % É (accented E)
morse(f, [.,.,-,.]).	   % F
morse(g, [-,-,.]).	   % G
morse(h, [.,.,.,.]).	   % H
morse(i, [.,.]).	   % I
morse(j, [.,-,-,-]).	   % J
morse(k, [-,.,-]).	   % K or invitation to transmit
morse(l, [.,-,.,.]).	   % L
morse(m, [-,-]).	   % M
morse(n, [-,.]).	   % N
morse(o, [-,-,-]).	   % O
morse(p, [.,-,-,.]).	   % P
morse(q, [-,-,.,-]).	   % Q
morse(r, [.,-,.]).	   % R
morse(s, [.,.,.]).	   % S
morse(t, [-]).	 	   % T
morse(u, [.,.,-]).	   % U
morse(v, [.,.,.,-]).	   % V
morse(w, [.,-,-]).	   % W
morse(x, [-,.,.,-]).	   % X or multiplication sign
morse(y, [-,.,-,-]).	   % Y
morse(z, [-,-,.,.]).	   % Z
morse(0, [-,-,-,-,-]).	   % 0
morse(1, [.,-,-,-,-]).	   % 1
morse(2, [.,.,-,-,-]).	   % 2
morse(3, [.,.,.,-,-]).	   % 3
morse(4, [.,.,.,.,-]).	   % 4
morse(5, [.,.,.,.,.]).	   % 5
morse(6, [-,.,.,.,.]).	   % 6
morse(7, [-,-,.,.,.]).	   % 7
morse(8, [-,-,-,.,.]).	   % 8
morse(9, [-,-,-,-,.]).	   % 9
morse(., [.,-,.,-,.,-]).   % . (period)
morse(',', [-,-,.,.,-,-]). % , (comma)
morse(:, [-,-,-,.,.,.]).   % : (colon or division sign)
morse(?, [.,.,-,-,.,.]).   % ? (question mark)
morse('''',[.,-,-,-,-,.]). % ' (apostrophe)
morse(-, [-,.,.,.,.,-]).   % - (hyphen or dash or subtraction sign)
morse(/, [-,.,.,-,.]).     % / (fraction bar or division sign)
morse('(', [-,.,-,-,.]).   % ( (left-hand bracket or parenthesis)
morse(')', [-,.,-,-,.,-]). % ) (right-hand bracket or parenthesis)
morse('"', [.,-,.,.,-,.]). % " (inverted commas or quotation marks)
morse(=, [-,.,.,.,-]).     % = (double hyphen)
morse(+, [.,-,.,-,.]).     % + (cross or addition sign)
morse(@, [.,-,-,.,-,.]).   % @ (commercial at)

% Error.
morse(error, [.,.,.,.,.,.,.,.]). % error - see below

% Prosigns.
morse(as, [.,-,.,.,.]).          % AS (wait A Second)
morse(ct, [-,.,-,.,-]).          % CT (starting signal, Copy This)
morse(sk, [.,.,.,-,.,-]).        % SK (end of work, Silent Key)
morse(sn, [.,.,.,-,.]).          % SN (understood, Sho' 'Nuff)


interpret([], [], []).
interpret([], L, [LI]) :- reverse(L, LR), morse(LI, LR).
interpret([^|T], [], TI) :- interpret(T, [], TI).
interpret([^|T], L, [LI|TI]) :- reverse(L, LR), morse(LI, LR), interpret(T, [], TI).
interpret([#|T], [], [#|TI]) :- interpret(T, [], TI).
interpret([#|T], L, [LI,#|TI]) :- reverse(L, LR), morse(LI, LR), interpret(T, [], TI).
interpret([H|T], [], MSG) :- interpret(T, H, MSG).
interpret([H|T], L, MSG) :- interpret(T, [H|L], MSG).

filter([], [], []).
filter([], L, L).
filter([error|T], [], [error|TF]) :- filter(T, [], TF).
filter([error|T], L, TF) :- filter(T, [], TF).
filter([#|T], [], [#|TF]) :- filter(T, [], TF).
filter([#|T], L, FLT) :- append(L, [#], LS), filter(T, [], TF), append(LS, TF, FLT).
filter([H|T], [], FLT) :- filter(T, [H], FLT).
filter([H|T], L, FLT) :- append(L, [H], LH), filter(T, LH, FLT).
filter_once(MSG, FLT) :- once(filter(MSG, [], FLT)).

signal_message([], []).
signal_message([H|T], FLT) :- signal_morse([H|T], MRS), interpret(MRS, [], MSG), filter_once(MSG, FLT).