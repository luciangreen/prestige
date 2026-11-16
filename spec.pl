% spec.pl - independent oracle for prestige: words by character scanning,
% department ranking by msort of negated scores, and intro/conclusion built
% from explicit lists.
:- ensure_loaded('departments.pl').

spec_for(prestige, spec_prestige).

spec_prestige(essay(Ex, Cr, MyI, MyC), R) :-
    length(Ex, NE), length(Cr, NC),
    (   NE \== 5 -> R = report(write_first(exposition, NE), [], none, none, [])
    ;   NC \== 5 -> R = report(write_first(critique, NC), [], none, none, [])
    ;   findall(s(exposition, I, K, F), ( nth1(I, Ex, S), spec_sent(S, K, F) ), D1),
        findall(s(critique, I, K, F), ( nth1(I, Cr, S), spec_sent(S, K, F) ), D2),
        append(D1, D2, Ds),
        spec_topic(Ex, T), Cr = [C1|_], spec_thesis(C1, Th),
        findall(K, ( member(S, Cr), spec_key(S, K) ), Ks),
        spec_and(Ks, KT), reverse(Ks, Rs), spec_and(Rs, RT),
        atomic_list_concat(['This essay is about ', T, '.'], TS),
        atomic_list_concat(['It argues that ', Th, '.'], ThS),
        atomic_list_concat(['It will argue about ', KT, '.'], AS),
        atomic_list_concat(['In conclusion, the essay argued about ', RT, '. It argued that ', Th,
                            '. This essay was about ', T, '.'], Concl),
        spec_key(C1, ThK),
        spec_checks(T, ThK, Ks, MyI, MyC, Checks),
        R = report(ok, Ds, intro(TS, ThS, AS), Concl, Checks)
    ).

spec_words(S, Ws) :- downcase_atom(S, L), atom_chars(L, Cs), spec_split(Cs, [], Ws).
spec_split([], [], []) :- !.
spec_split([], Cur, [W]) :- reverse(Cur, R), atom_chars(W, R).
spec_split([C|Cs], Cur, Ws) :-
    (   char_type(C, alnum) -> spec_split(Cs, [C|Cur], Ws)
    ;   Cur == [] -> spec_split(Cs, [], Ws)
    ;   reverse(Cur, R), atom_chars(W, R), Ws = [W|Ws1], spec_split(Cs, [], Ws1) ).

spec_content(S, Cs) :- spec_words(S, Ws), findall(W, ( member(W, Ws), atom_length(W, N), N > 3, \+ spec_stop(W) ), Cs).
spec_stop(W) :- member(W, [that, this, with, from, have, which, their, there, about, into,
    than, then, them, they, were, will, would, also, been, being, because, while, where,
    when, what, essay, argues, does, more, most, some, such, very]), !.

spec_key(S, K) :- spec_content(S, Cs), ( Cs == [] -> K = none ; spec_longest(Cs, K) ).
spec_longest([W|Ws], K) :- foldl(spec_l, Ws, W, K).
spec_l(W, B, R) :- atom_length(W, A), atom_length(B, C), ( A > C -> R = W ; R = B ).

spec_sent(S, K, Five) :-
    spec_key(S, K), spec_content(S, Cs),
    findall(Neg-D, ( dept(D, V, _), aggregate_all(count, ( member(W, Cs), memberchk(W, V) ), N),
                     atom_codes(K, KC), atom_codes(D, DC), sum_list(KC, A), sum_list(DC, B),
                     Neg is -(10 * N + (A + B) mod 10) ), L),
    msort(L, Sorted), findall(D, member(_-D, Sorted), All), All = [D1, D2, D3, D4, D5|_],
    findall(d(D, Alg, Conn), ( member(D, [D1, D2, D3, D4, D5]), dept(D, V, Alg),
              ( member(W, Cs), member(W, V) -> atomic_list_concat([K, ' connects to ', D, ' through the shared idea of ', W, ': ', Alg], Conn)
              ; atomic_list_concat([K, ' connects to ', D, ' by analogy: ', Alg], Conn) ) ), Five).

spec_topic(Ex, T) :-
    findall(W, ( member(S, Ex), spec_content(S, Cs), member(W, Cs) ), Ws),
    findall(N-I-W, ( nth1(I, Ws, W), \+ ( nth1(J, Ws, W2), J < I, W2 == W ),
                     aggregate_all(count, ( member(X, Ws), X == W ), N) ), L),
    findall(N, member(N-_-_, L), Ns), max_list(Ns, Max),
    findall(I-W, member(Max-I-W, L), Cands), msort(Cands, [_-T|_]).

spec_thesis(S, Th) :-
    atom_chars(S, [C|Cs]), downcase_atom(C, L0), atom_chars(L0, [L]),
    ( append(Body, ['.'], Cs) -> true ; Body = Cs ), atom_chars(Th, [L|Body]).

spec_and([X], X) :- !.
spec_and(Xs, T) :- append(I, [L], Xs), atomic_list_concat(I, ', ', A), atomic_list_concat([A, ' and ', L], T).

spec_checks(T, ThK, Ks, MyI, MyC, Checks) :-
    (   MyI == none -> CI = []
    ;   spec_words(MyI, W),
        spec_pf(member(T, W), A1), spec_pf(member(ThK, W), A2),
        spec_pf(\+ ( member(K, Ks), \+ member(K, W) ), A3), spec_pf(spec_ordered(Ks, W), A4),
        CI = [check(intro_topic, A1), check(intro_thesis, A2), check(intro_argued, A3), check(intro_order, A4)] ),
    (   MyC == none -> CC = []
    ;   spec_words(MyC, W2), reverse(Ks, Rs),
        spec_pf(member(T, W2), B1), spec_pf(member(ThK, W2), B2), spec_pf(spec_ordered(Rs, W2), B3),
        CC = [check(conclusion_topic, B1), check(conclusion_thesis, B2), check(conclusion_reverse_order, B3)] ),
    append(CI, CC, Checks).

spec_pf(G, R) :- ( once(G) -> R = pass ; R = fail ).

spec_ordered(Ks, W) :-
    findall(P, ( member(K, Ks), once(nth1(P, W, K)) ), Ps), length(Ps, N), length(Ks, N), N > 0,
    msort(Ps, Ps), sort(Ps, S), length(S, N).
