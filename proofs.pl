% proofs.pl - properties of prestige.
:- ensure_loaded('prestige.pl').
:- ensure_loaded('spec.pl').
:- ensure_loaded('tests/inputs.pl').

sample(E) :- between(1, 50, Id), gen_essay(Id, E), E = essay(Ex, Cr, _, _), length(Ex, 5), length(Cr, 5).

% Exactly 5 details per sentence, from 5 different departments, for all 10 sentences.
proof(five_distinct_departments, forall(sample(E), ( prestige(E, report(ok, Ds, _, _, _)), length(Ds, 10),
      forall(member(s(_, _, _, F), Ds), ( length(F, 5), findall(D, member(d(D, _, _), F), L), sort(L, S), length(S, 5) )) ))).

% Every detail names its connection to the sentence keyword.
proof(connections_mention_keyword, forall(sample(E), ( prestige(E, report(ok, Ds, _, _, _)),
      forall(( member(s(_, _, K, F), Ds), member(d(_, _, C), F) ), atom_concat(K, _, C)) ))).

% Exposition and critique must be written first.
proof(write_first, ( prestige(essay([a], [], none, none), report(write_first(exposition, 1), [], none, none, [])) )).

% The generated conclusion mentions the argued points in exactly reverse order
% of the introduction, so the generated pair always passes the checks.
proof(generated_pair_passes, forall(sample(essay(Ex, Cr, _, _)),
      ( prestige(essay(Ex, Cr, none, none), report(ok, _, intro(A, B, C), Con, _)),
        atomic_list_concat([A, B, C], ' ', Intro),
        prestige(essay(Ex, Cr, Intro, Con), report(ok, _, _, _, Checks)),
        forall(member(check(N, R), Checks), ( R == pass ; N == intro_order ; N == conclusion_reverse_order ; dup_keys(Cr) )) ))).
dup_keys(Cr) :- maplist(keyword, Cr, Ks), msort(Ks, S), sort(Ks, S2), S \== S2.

% Ranking is a total order: top5 picks the 5 highest scores.
proof(top5_maximal, forall(sample(essay(Ex, _, _, _)), ( Ex = [S|_], keyword(S, K), content_words(S, Cs),
      findall(Sc-D, ( dept(D, V, _), score(Cs, K, D, V, Sc) ), All), top5(All, Top),
      forall(( member(D1, Top), member(Sc1-D1, All), member(Sc2-D2, All), \+ memberchk(D2, Top) ), Sc1 >= Sc2) ))).

% Refinement: implementation equals the spec on samples.
proof(implementation_equals_spec, forall(( between(1, 50, Id), gen_essay(Id, E) ), ( prestige(E, A), spec_prestige(E, B), A == B ))).
