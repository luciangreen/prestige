% inputs.pl - 200 generated essays (some with too few sentences written
% first, some with the user's own introduction/conclusion to check).
input(Id, prestige, E) :- between(1, 200, Id), gen_essay(Id, E).

lcg(S0, S) :- S is (S0 * 1103515245 + 12345) mod 2147483648.
rnd(M, S0, S, X) :- lcg(S0, S), X is (S >> 16) mod M.

vocab([learning, memory, students, market, policy, energy, rhythm, proof, language, cells,
       society, design, health, reasoning, feedback, retrieval, practice, network, value, argument,
       evolution, performance, curriculum, citizens, structure, attention, motivation, treatment,
       harmony, identity, algorithm, knowledge, gravity, assessment, ownership, independence]).

pick(S0, S, W) :- vocab(V), length(V, N), rnd(N, S0, S, I), nth0(I, V, W).

sentence(S0, S, Sent) :-
    pick(S0, S1, A), pick(S1, S2, B), pick(S2, S3, C), rnd(4, S3, S, K),
    nth0(K, ['The ~w of ~w shapes ~w.', 'Good ~w improves ~w through ~w.',
             '~w links ~w with ~w daily.', 'Without ~w, ~w weakens ~w.'], F),
    format(atom(Sent0), F, [A, B, C]), cap(Sent0, Sent).
cap(A, B) :- atom_chars(A, [C|Cs]), upcase_atom(C, U), atom_chars(U, [UC]), atom_chars(B, [UC|Cs]).

sentences(0, S, S, []) :- !.
sentences(N, S0, S, [X|Xs]) :- sentence(S0, S1, X), N1 is N - 1, sentences(N1, S1, S, Xs).

gen_essay(Id, essay(Ex, Cr, I, C)) :-
    S0 is Id * 9973,
    ( Id mod 17 =:= 0 -> NE = 4 ; NE = 5 ), ( Id mod 23 =:= 0 -> NC = 3 ; NC = 5 ),
    sentences(NE, S0, S1, Ex), sentences(NC, S1, S2, Cr),
    rnd(4, S2, _, K), own(K, Ex, Cr, I, C).

own(0, _, _, none, none).
own(1, _, Cr, I, none) :- Cr = [A|_], format(atom(I), 'This essay considers that ~w', [A]).
own(2, Ex, Cr, I, C) :- atomic_list_concat(Ex, ' ', I), reverse(Cr, R), atomic_list_concat(R, ' ', C).
own(3, Ex, Cr, I, C) :- atomic_list_concat(Cr, ' ', I), atomic_list_concat(Ex, ' ', C).
