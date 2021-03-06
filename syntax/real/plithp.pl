eval(X,O) :- defined(X,A), eval(A,O).
eval([X|T],O) :- defined(X,A), eval([A|T],O).

eval(X,X) :- number(X); X = t ; X = [].

eval([quote,X],X).
eval([lambda|X],[lambda|X]).
eval([define,X,Y],t) :- \+ defined(X,_), asserta(defined(X,Y)).

eval([cond],_) :- !, fail.
eval([cond,[H,A]|_],Z) :- eval(H,O), \+ O = [],!, eval(A,Z).
eval([cond,_|T],Z) :- eval([cond|T],Z),!.

eval([F|A],X) :- eval_list(A,Ae), apply(F,Ae,X),!.

eval_list([],[]).
eval_list([H|T],[Ho|To]) :- eval(H,Ho), eval_list(T,To).

apply(add,[X,Y],Z) :- Z is X + Y.
apply(add,[X,Y|T],Z) :- I is X + Y, apply(add,[I|T],Z).

apply(mul,[X,Y],Z) :- Z is X * Y.
apply(mul,[X,Y|T],Z) :- I is X * Y, apply(mul,[I|T],Z).

apply(sub,[X,Y],Z) :- Z is X - Y.
apply(div,[X,Y],Z) :- Z is X / Y.

apply(mod,[X,Y],Z) :- Z is X mod Y.
apply(pow,[X,Y],Z) :- Z is X ** Y.

apply(eq,[X,Y],t) :- X = Y.
apply(eq,[X,Y],[]) :- \+ X = Y.

apply(atom,[X],t) :- number(X);atom(X); X = [].
apply(atom,[[_|_]],[]).

apply(cons,[X|[Y]],[X|Y]).
apply(car,[[X|_]],X).
apply(cdr,[[_|T]],T).

apply([lambda,[],E],[],O) :- eval(E,O).
apply([lambda,[A|Ta],E],[L|Tl],O) :- subst(A,[quote,L],E,E2), apply([lambda,Ta,E2],Tl,O).

subst(_,_,[],[]).
subst(A,B,[A|T],[B|L]) :- subst(A,B,T,L).
subst(A,B,[H|T],[H2|L]) :- subst(A,B,H,H2),subst(A,B,T,L).
subst(A,B,A,B).
subst(_,_,X,X).

% gprolog
:- predicate_property(defined,dynamic).
% swi prolog
:- dynamic defined/2.

defined(_,[]) :- !,fail.


lisp([
      [define,null,[lambda,[x],[eq,x,[quote,[]]]]],
      [define,and,[lambda,[x,y],[cond,[x,[cond,[y,t],[t,[quote,[]]]]],[t,[quote,[]]]]]],
      [define,not,[lambda,[x],[cond,[x,[quote,[]]],[t,t]]]],
      [define,append,[lambda,[x,y],[cond,[[null,x],y],[t,[cons,[car,x],[append,[cdr,x],y]]]]]],
      [define,list,[lambda,[x,y],[cons,x,[cons,y,[quote,[]]]]]],
      [define,pair,[lambda,[x,y],[cond,[[and,[null,x],[null,y]],[quote,[]]],[[and,[not,[atom,x]],[not,[ato
												      m,y]]],[cons,[list,[car,x],[car,y]],[pair,[cdr,x],[cdr,y]]]]]]],
      [define,assoc,[lambda,[x,y],[cond,[[eq,x,[car,[car,y]]],[car,[cdr,[car,y]]]],[t,[assoc,x,[cdr,y]]]]]
      ],
      [define,evcon,[lambda,[c,a],[
				   cond,[[eval,[caar,c],a],[eval,[cadar,c],a]],[t,[evcon,[cdr,c],a]]
				  ]]],
      [define,eval,[lambda,[e,a],[
				  cond,
				  [[atom,e],[assoc,e,a]],
				  [[atom,[car,e]],[cond,
						   [[eq,[car,e],[quote,quote]],[cadr,e]],
						   [[eq,[car,e],[quote,atom]],[atom,[eval,[cadr,e],a]]],
						   [[eq,[car,e],[quote,eq]],[eq,[eval,[cadr,e],a],[eval,[caddr,e],a]]],
						   [[eq,[car,e],[quote,car]],[car,[eval,[cadr,e],a]]],
						   [[eq,[car,e],[quote,cdr]],[cdr,[eval,[cadr,e],a]]],
						   [[eq,[car,e],[quote,cons]],[cons,[eval,[cadr,e],a],[eval,[caddr,e],a]]],
						   [[eq,[car,e],[quote,cond]],[evcon,[cdr,e],a]],
						   [t,[eval,[cons,[assoc,[car,e],a],[cdr,e]],a]]
						  ]],
				  [[eq,[caar,e],[quote,label]],
				   [eval,[cons,[caddar,e],[cdr,e]],[cons,[list,[cadar,e],[car,e]],a]]
				  ],
				  [[eq,[caar,e],[quote,lambda]],
				   [append,[pair,[cadar,e],[evlis,[cdr,e],a]],a]
				  ]]]],
      [define,evlis,[lambda,[m,a],[
				   cond,[[null,m],[quote,[]]],[t,[cons,[eval,[car,m],a],[evlis,[cdr,m],a]]]
				  ]]],
      [define,cadr,[lambda,[x],[car,[cdr,x]]]],
      [define,caddr,[lambda,[x],[car,[cdr,[cdr,x]]]]],
      [define,cadar,[lambda,[x],[car,[cdr,[car,x]]]]],
      [define,caddar,[lambda,[x],[car,[cdr,[cdr,[car,x]]]]]]
     ]).

load :- lisp(X), eval_list(X,_)

    paren("(").
paren(")").

digit("0") --> "0".
digit("1") --> "1".
digit("2") --> "2".
digit("3") --> "3".
digit("4") --> "4".
digit("5") --> "5".
digit("6") --> "6".
digit("7") --> "7".
digit("8") --> "8".
digit("9") --> "9".

space(" ") --> " ".
space("\t") --> "\t".
space("\n") --> "\n".

identifier_char(X) :-
    \+ space(X, _, _),
    \+ paren(X),
    \+ digit(X, _, _).

ws --> space(_).
ws --> space(_), ws.
ows --> space(_), ows.
ows --> [].

program([H|T]) --> sexp(H), ows, program(T).
program([H]) --> sexp(H).

sexp(L) --> "(", ows, sexp_list(L), ows, ")".
sexp([]) --> "(", ows, ")".
sexp_list([H|T]) --> (sexp(H); atom(H)), ws, sexp_list(T).
sexp_list([H]) --> sexp(H); atom(H).

atom(A) --> identifier(A) ; number(A).

identifier(I) --> [A], { identifier_char([A]) }, id_list(L), { atom_codes(I, [A|L]) }.
id_list([H|T]) --> [H], { identifier_char([H]) }, id_list(T).
id_list([]) --> [].

number(N) --> n_list(L), { number_codes(N, L) }.
n_list([H|T]) --> digit([H]), n_list(T).
n_list([H]) --> digit([H]).
