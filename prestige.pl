% prestige - for an essay whose exposition (5 sentences) and critique
% (5 sentences) are written first, finds 5 algorithmic details from 5
% different academic departments for each sentence, each with its
% connection to the sentence; then writes and checks the introduction
% (topic, thesis statement, what will be argued) and the conclusion
% paragraph, which gives these in reverse.
%
% prestige(+essay(Exposition, Critique, MyIntro, MyConclusion), -Report)
%   Exposition, Critique: lists of sentence atoms (5 each, written first)
%   MyIntro, MyConclusion: your own text to check, or none
% Report = report(Status, Details, intro(Topic, Thesis, Argued), Conclusion, Checks)
%
% Try:  ?- example(E), show(E).

:- ensure_loaded('departments.pl').

prestige(essay(Ex, Cr, MyI, MyC), Report) :-
    length(Ex, NE), length(Cr, NC),
    (   NE =\= 5 -> Report = report(write_first(exposition, NE), [], none, none, [])
    ;   NC =\= 5 -> Report = report(write_first(critique, NC), [], none, none, [])
    ;   details(exposition, Ex, D1), details(critique, Cr, D2), append(D1, D2, Ds),
        intro(Ex, Cr, Intro), conclusion(Intro, Cr, Concl),
        checks(Intro, Cr, MyI, MyC, Checks),
        Report = report(ok, Ds, Intro, Concl, Checks)
    ).

% ---- words and keywords -----------------------------------------------------
words(S, Ws) :-
    downcase_atom(S, L), atom_chars(L, Cs),
    maplist(clean_char, Cs, Cs2), atom_chars(A, Cs2),
    atomic_list_concat(Parts, ' ', A), exclude(==(''), Parts, Ws).

clean_char(C, C2) :- ( char_type(C, alnum) -> C2 = C ; C2 = ' ' ).

content_words(S, Cs) :- words(S, Ws), include(content, Ws, Cs).
content(W) :- atom_length(W, L), L >= 4, \+ stopword(W).

stopword(W) :- memberchk(W, [that, this, with, from, have, which, their, there, about, into,
    than, then, them, they, were, will, would, also, been, being, because, while, where,
    when, what, essay, argues, does, more, most, some, such, very]).

% keyword: the longest content word (earliest on ties).
keyword(S, K) :- content_words(S, Cs), Cs \== [], foldl(longer, Cs, '', K).
keyword(S, none) :- content_words(S, []).
longer(W, Best, B) :- atom_length(W, L), atom_length(Best, LB), ( L > LB -> B = W ; B = Best ).

% ---- details ----------------------------------------------------------------
% details(+Section, +Sentences, -[s(Section, I, Keyword, [d(Dept, Algorithm, Connection)x5])])
details(Sec, Ss, Ds) :- details_(Ss, 1, Sec, Ds).
details_([], _, _, []).
details_([S|Ss], I, Sec, [s(Sec, I, K, Five)|Ds]) :-
    keyword(S, K), content_words(S, Cs),
    findall(Sc-D, ( dept(D, Vocab, _), score(Cs, K, D, Vocab, Sc) ), Scored),
    top5(Scored, Depts),
    maplist(detail(K, Cs), Depts, Five),
    I1 is I + 1, details_(Ss, I1, Sec, Ds).

score(Cs, K, D, Vocab, Sc) :-
    intersection(Cs, Vocab, Common), length(Common, N),
    hash(K, D, H), Sc is 10 * N + H.

hash(K, D, H) :- atom_codes(K, A), atom_codes(D, B), append(A, B, C), sum_list(C, S), H is S mod 10.

% Highest score first; equal scores in alphabetical order of department.
top5(Pairs, Depts) :-
    predsort(by_score, Pairs, Sorted), length(Top, 5), append(Top, _, Sorted),
    findall(D, member(_-D, Top), Depts).
by_score(O, S1-D1, S2-D2) :- ( S1 > S2 -> O = (<) ; S1 < S2 -> O = (>) ; compare(O, D1, D2) ).

detail(K, Cs, D, d(D, Alg, Conn)) :-
    dept(D, Vocab, Alg),
    (   member(W, Cs), memberchk(W, Vocab)
    ->  format(atom(Conn), '~w connects to ~w through the shared idea of ~w: ~w', [K, D, W, Alg])
    ;   format(atom(Conn), '~w connects to ~w by analogy: ~w', [K, D, Alg])
    ).

% ---- introduction and conclusion --------------------------------------------
% Topic: the most frequent content word of the exposition (on ties, the one
% that appears first).
topic(Ex, T) :-
    findall(W, ( member(S, Ex), content_words(S, Cs), member(W, Cs) ), Ws),
    first_seen(Ws, [], Order),
    foldl(best_count(Ws), Order, 0-'', _-T).
first_seen([], Acc, Order) :- reverse(Acc, Order).
first_seen([W|Ws], Acc, Order) :- ( memberchk(W, Acc) -> first_seen(Ws, Acc, Order) ; first_seen(Ws, [W|Acc], Order) ).
best_count(Ws, W, B0-T0, B-T) :-
    include(==(W), Ws, Hits), length(Hits, N),
    ( N > B0 -> B = N, T = W ; B = B0, T = T0 ).

thesis(Cr, Th) :- Cr = [S|_], atom_concat(S0, '.', S), !, downcase_first(S0, Th).
thesis([S|_], Th) :- downcase_first(S, Th).
downcase_first(S, T) :- atom_chars(S, [C|Cs]), downcase_atom(C, L), atom_chars(T, [L|Cs]).

argued(Cr, Ks) :- maplist(keyword, Cr, Ks).

intro(Ex, Cr, intro(TopicS, ThesisS, ArguedS)) :-
    topic(Ex, T), thesis(Cr, Th), argued(Cr, Ks), list_text(Ks, KT),
    format(atom(TopicS), 'This essay is about ~w.', [T]),
    format(atom(ThesisS), 'It argues that ~w.', [Th]),
    format(atom(ArguedS), 'It will argue about ~w.', [KT]).

conclusion(intro(TopicS, ThesisS, _), Cr, C) :-
    argued(Cr, Ks), reverse(Ks, Rs), list_text(Rs, RT),
    atom_concat('This essay is about ', T0, TopicS), atom_concat(T, '.', T0),
    atom_concat('It argues that ', Th0, ThesisS), atom_concat(Th, '.', Th0),
    format(atom(C), 'In conclusion, the essay argued about ~w. It argued that ~w. This essay was about ~w.', [RT, Th, T]).

list_text([X], X) :- !.
list_text(Xs, T) :- append(Init, [Last], Xs), atomic_list_concat(Init, ', ', A),
    format(atom(T), '~w and ~w', [A, Last]).

% ---- checking your own introduction and conclusion --------------------------
checks(intro(TopicS, _, _), Cr, MyI, MyC, Checks) :-
    atom_concat('This essay is about ', T0, TopicS), atom_concat(T, '.', T0),
    Cr = [C1|_], keyword(C1, ThK), argued(Cr, Ks),
    ( MyI == none -> CI = [] ;
      words(MyI, WI),
      verdict(memberchk(T, WI), intro_topic, A1), verdict(memberchk(ThK, WI), intro_thesis, A2),
      verdict(forall(member(K, Ks), memberchk(K, WI)), intro_argued, A3),
      verdict(in_order(Ks, WI), intro_order, A4), CI = [A1, A2, A3, A4] ),
    ( MyC == none -> CC = [] ;
      words(MyC, WC), reverse(Ks, Rs),
      verdict(memberchk(T, WC), conclusion_topic, B1), verdict(memberchk(ThK, WC), conclusion_thesis, B2),
      verdict(in_order(Rs, WC), conclusion_reverse_order, B3), CC = [B1, B2, B3] ),
    append(CI, CC, Checks).

verdict(G, Name, check(Name, R)) :- ( call(G) -> R = pass ; R = fail ).

% in_order(Ks, Ws): each keyword occurs, first occurrences in this order.
in_order(Ks, Ws) :- maplist(first_pos(Ws), Ks, Ps), Ps \== [], strictly_up(Ps).
first_pos(Ws, K, P) :- nth1(P, Ws, W), W == K, !.
strictly_up([_]).
strictly_up([A, B|T]) :- A < B, strictly_up([B|T]).

% ---- display ----------------------------------------------------------------
show(E) :-
    prestige(E, report(St, Ds, I, C, Ch)), format("Status: ~w~n", [St]),
    forall(member(s(Sec, N, K, Five), Ds),
           ( format("~w ~w (keyword ~w):~n", [Sec, N, K]),
             forall(member(d(D, A, Co), Five), format("   ~w: ~w~n      ~w~n", [D, A, Co])) )),
    ( I = intro(A1, A2, A3) -> format("Introduction:~n  ~w ~w ~w~nConclusion:~n  ~w~n", [A1, A2, A3, C]) ; true ),
    forall(member(X, Ch), writeln(X)).

example(essay(
  ['Learning grows when students practise retrieval daily.', 'Memory strengthens through spaced repetition schedules.',
   'Feedback guides attention toward errors.', 'Motivation depends on achievable goals.', 'Teachers model reasoning aloud.'],
  ['Retrieval practice is the strongest method.', 'Spacing schedules ignore individual differences.',
   'Feedback without explanation confuses novices.', 'Goals need ownership by learners.', 'Modelling reasoning builds independence.'],
  'This essay is about learning and argues retrieval matters, covering retrieval, differences, explanation, ownership and independence.',
  none)).
