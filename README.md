# Prestige

For an essay whose **exposition (5 sentences) and critique (5 sentences) are written first**:

- For each of the 10 sentences, it finds 5 algorithmic details from 5 different academic departments (`departments.pl`, 15 departments), each with its connection to the sentence's keyword.
- It writes the introduction: the topic, the thesis statement (the critique's main claim) and what will be argued.
- It writes the conclusion paragraph, which gives these in reverse.
- It checks your own introduction and conclusion: topic, thesis and argued points present, in order, and reversed in the conclusion.

```
?- example(E), show(E).
```

Proved properties: 5 distinct departments per sentence, every connection names its keyword, the exposition and critique must come first, the generated introduction/conclusion pair passes the checks, the top 5 are maximal, and the implementation equals the spec.

## Tests and proofs

```
swipl run_tests.pl        # runs the 200 saved I/O pairs and checks every proof
swipl tests/gen_io.pl     # regenerates tests/io_pairs.pl from spec.pl
```

- `tests/io_pairs.pl` has 200 saved `io(Id, Predicate, Input, ExpectedOutput)` facts.
- The expected outputs come from `spec.pl`, an independent specification written in a different style from the implementation. Because the implementation is checked against a separate oracle, a pass is real evidence and not the program checking itself.
- `proofs.pl` has machine-checked `proof(Name, Goal)` theorems. Each one is checked exhaustively on a bounded domain or over sample inputs, and its comment gives the general (usually inductive) argument.

All files are plain, portable SWI-Prolog, with no packs needed.
