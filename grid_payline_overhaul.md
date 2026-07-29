# Combat Overhaul: 3×5 Grid + Paylines

Design spec for replacing the current single-row, hard-constrained-reel combat loop.
Godot 4.7 / GDScript. This document describes the **target**, not the current code.

---

## 0. Instructions for the implementing agent

Read this whole document before writing anything.

**Read the real code first, then reconcile.** Before implementing, read the existing combat
resolver, the `Reel` node, the loadout modal, and `CombatContext`. Then report where the actual
code differs from what this spec assumes — §10 ("Preserved From Current Systems") and §11
("Retired or Invalidated") in particular are assumptions about the current code that may be wrong.
Surface the discrepancies and reconcile them *before* building. Do not implement against this
spec's assumptions where they contradict the real code.

**Do not "improve" the counterintuitive choices.** Several decisions here look like mistakes
without their reasoning, and the reasoning is in the doc next to each. Do not silently change:
the 2-blank strip count (§3), free and toggleable holds (§5), min-2 matching (§4), the
damage-heavy 50/35 strip ratio (§3), same-price replace-vs-insert (§6), or pricing symbols by
inherent quality rather than by copies owned (§6). If you believe one is wrong, **flag it with
your reasoning and wait** — do not change it as part of the build.

**Never explain the game's reasoning to the player. Anywhere.** This binds every screen, label,
tooltip and description in the game, not just the sections that mention UI.

- **State facts, never implications.** "8 block" — not "8 block, which covers most of the
  incoming hit". "Removes one stop" — not "removes one stop, so everything left shows up more
  often". The moment a string explains what a number *means for your decision*, it has taken
  the decision over. Working the implications out is the game.
- **Prefer UI over prose for anything that does need conveying.** If the player must understand
  something, build the affordance: draw the payline path, glow the cells on it, colour shared
  cells in a pattern glyph, put a "+" on the insertion points. Reach for a sentence only when no
  visual will carry it, and then keep it to a fragment.
- **Concrete and short.** A symbol, a position, a count, a state. `RESPIN (2)`, `4 damage`,
  `No line selected`, `22 ATK · 8 BLK`. Not sentences, not hedges, not rationale.
- **Match the existing voice.** Souvenirs and modifiers already do this well — "+4 if an adjacent
  stop shares this symbol", "Start each combat with 5 block". Rules, stated flat, no commentary.

Prose that explains itself also reads as machine-written, which is its own reason to cut it.
Several readouts were built against earlier drafts of this document, played, and removed for
exactly this: the block-vs-intent delta and marginal preview (§9), the pattern-offer overlap
description (§4), and the reel editor's coverage and dilution analysis (§6). Each is documented
where it was cut. **Assume a readout you are about to add is one of these.**

**Check every new symbol, modifier, souvenir and drink against the others.** The hook surface
has grown orthogonal properties, and nothing about a symbol's flags tells you which hooks reach
it. Before adding any of the four, walk this table:

| Symbol property | What silently changes |
|---|---|
| `combos = false` | Skips the run-bonus curve **only**. `modify_stop_value` still applies, so every value effect is a multiplier on it. |
| `payout` non-empty | Scored from its own table; `values[]` is never read, so *no* value modifier reaches it. |
| `is_wild` | Contributes the adopted symbol's **base** value, not the modified one — decided, not accidental: a wild copies the symbol, not the investment in one stop. |
| `type == NONE` | Skipped by the run loop entirely, and by `_apply_result_totals`. |
| `type` GOLD or TOKEN | `_apply_result_totals` matches only ATTACK/DEFEND/HEAL, so `modify_result_total` never fires. |
| `trigger != NONE` | Pays off the board via BoardEffects, not off a line at all. |
| `type` in `Action.COMBAT_TYPES` | Attack, block and heal are the pot: they are spent inside the fight, and effects that skim it (The Rake) only touch these. Gold and tokens are carried out of the fight and are spared. New action types — bleed, poison — belong in COMBAT_TYPES when they land, or a rake will silently ignore them. |

And for a new effect, ask which of those properties neuter it or amplify it. A modifier whose
hook cannot reach a stop must say so in `can_apply` — otherwise it is a purchase that costs gold
and does nothing, with no feedback. Adjacency means **along the payline**, not along the strip;
strip adjacency is a static property the player can engineer once and stop thinking about.

Each row above is a bug that shipped, found by audit rather than by play.

**A nudge is a spin.** Anything that changes what is on the board has to run the whole
post-spin pipeline — ON_SPIN board effects, reel jams, payline rescoring. Live Wire and Penny
fire on nudges for that reason: a board-manipulation verb that dodged the spin tax would quietly
weaken the curse written to punish board manipulation. It is not a *respin*, though, so it never
raises the lever's price.

**Never keep a second copy of a fact.** Every drift bug in this project has the
same shape: two lists, two tables or two orderings that must agree, where
nothing enforces it and nothing fails loudly when they stop. So far that has
been the shop's private symbol-colour table against the board's, the paytable's
private sort order against the reel preview's, and the God Menu's enemy list
against the run queue. When something must be enumerated in more than one
place, give it one home — `EnemyCatalog.ALL`, `SymbolTable.sort_for_display`,
`SymbolCell.color_for` — and have every consumer read from it.

**Build in one pass, following the §13 phase order.** The phases are internal ordering to reach a
playable loop early; they do not gate on approval. Build straight through Phases 1–4.

**One exception: stop after Phase 1 so it can be played.** Phase 1 is the load-bearing bet of the
whole overhaul. A compiled-but-unplayed Phase 1 proves nothing. When Phase 1 is complete and
actually playable, stop and say so, so a real turn can be felt before Phases 2–4 build on top of
it. This is the only stop.

---

## 1. Why

Current combat is shallow because **composition is committed before the roll**. Reels are
hard-typed by category (Attack, Defend, Heal), so the damage/block split is decided at loadout
and the spin only changes magnitude. Holds are free, so the post-spin phase has no economy
and generates no decisions.

The fix is an inversion: **roll a superset, then carve the action out of it with perfect
information against known enemy intent.** Composition becomes a post-information decision.

Everything below is an implementation of that inversion. Paylines are the delivery mechanism,
not the point.

---

## 2. Board

- **3 rows × 5 columns.**
- **One master reel** (single symbol strip), shared by all columns. Typed reels are retired.
- Each column is a **window into the strip**: the 3 visible cells are *adjacent stops*, not
  independent draws.
- Columns roll independently of each other; a spin is 5 independent stop positions.
- Holds operate on **whole columns**, never individual cells.

### Why master reel over typed reels

- **Odds legibility.** Respins are gambles; gambles need knowable odds. One pool is learnable,
  five distributions are memorization.
- **Better build layer.** Symbol add/remove/replace is finer-grained and more legible than
  swapping typed reels, and it makes the gift shop's remove-service load-bearing.
- Positional identity is lost, but paylines supply position instead.

**Rows are fixed at 3.** Not an upgrade axis, not configurable.

### Computing odds on a shared strip

All five columns are independent windows into the **same** strip, so one stop
can appear in several columns at once — even in all five. A single copy of a
symbol is enough to make any board pattern *possible*; extra copies only shorten
the odds. Two consequences worth holding onto, because both have already been
got wrong once:

- **On a payline**, each cell is an independent uniform draw from the strip, so
  P(cell) = `stops / strip_size`. Five of a kind on a line is `p^5`, and three
  in a row across five cells is `3p³ − 2p⁴`. With one Wild on a 20-stop strip an
  all-Wild line is `(1/20)^5` — 1 in 3.2 million, not impossible.
- **On the grid**, a column shows a 3-stop window, so P(a column shows a given
  stop) = `3 / strip_size` — a different and much larger number than the
  per-cell one. Grid-wide effects and payline effects therefore have completely
  different odds, and a payout tuned for one is badly wrong for the other.

Measure rather than derive when a payout depends on it.

---

## 3. The Strip

15 stops at run start. Small deliberately, and for two separate reasons.

**Odds granularity.** At 15 stops one stop is 6.7%, so a single shop removal or insertion is a
felt swing. At 40 it would be 2.5% and the shop's core verb would barely register.

**The strip is something the player has to hold in their head.** Order is a design layer — a
column shows three *adjacent* stops, so the sequence decides what can co-occur, and the nudge
(§ The Shim) is only playable by someone who can tell where a column has landed. Fifteen stops
is 25% less sequence to learn than twenty, and every 3-window stays unique, so a column's
position is always identifiable from its three visible cells.

It also matters that the strip is re-learned continuously: every purchase changes it, so a
shorter reel means less to relearn each time and each change is a larger, more memorable share
of the whole.

**Grow toward the ideal, do not drift from it.** A run adds roughly 8-10 stops, so starting at 15
ends near 22-25 — close to where granularity still reads. Starting at 20 ends near 30, where a
bought symbol shows on 41% of boards instead of 67%, and the shop quietly deflates exactly as
gold income peaks.

| Symbol | Type | Value | Stops | P/cell |
|---|---|---|---|---|
| Light Atk | damage | 2 | 3 | 20% |
| Med Atk | damage | 4 | 2 | 13% |
| Heavy Atk | damage | 6 | 1 | 6.7% |
| Mega Atk | damage | 10 | 1 | 6.7% |
| Light Blk | block | 2 | 2 | 13% |
| Med Blk | block | 4 | 2 | 13% |
| Heavy Blk | block | 8 | 1 | 6.7% |
| Heal | heal | 4 | 1 | 6.7% |
| Blank | — | 0 | 2 | 13% |

**Values were doubled from the original table in playtesting.** At the original scale a line
averaged 8.75 across all three types, so a 100 HP enemy took ~20 turns and individual symbols
read as rounding errors. The strip now averages **3.5/cell**, so a 5-cell line runs ~19 before
the run bonus — measured 19.0, effectively unchanged from the 20-stop version, because the cut
removed low-tier padding rather than value.

A singleton now shows on **67%** of boards rather than 56%, so Mega Atk is present on two turns
in three instead of just over half.

**Block is flatter than damage on purpose.** Damage runs 3/2/1/1 across four tiers; block runs
2/2/1 across three. A lone Light Blk is 2 against a hit of 12-20, which barely registers, so
bottom-heavy block supply produces stops that are technically defensive and practically dead.
Two Med Blks instead of a third Light Blk trades block *combos* (0.169 per line down to 0.148)
for block *consistency* — measured 6.6 to 7.3 block per line, and lines paying 12+ block rise
from 18% to 24%. Since block is capped by the intent and overflow is wasted, consistent
mid-sized block is worth more than occasional large block.

Watch this one: it is the number that moves "two lines covers a typical hit" from marginal to
comfortable, which is the direction the next note warns about.

**Damage 50% / block 35% is deliberate.** Block is capped by the intent number and overflow is
wasted; damage is unbounded. Equal supply would make covering the hit trivial and kill the
satisfice decision. Defense should feel slightly scarce relative to demand.

**Value scales inversely with frequency.** Two Light Atks is a constant occurrence; two Mega Atks
is an event. That gap is why a hold is worth spending a turn's attention on.

**Only 2 blanks.** Blanks are *unconditionally* bad, which flattens line selection (a line with
two blanks is bad against every enemy) and makes shop removal an obvious non-choice. Low-value
live symbols do the same insufficiency job while keeping removal a real tradeoff — thinning
raises average cell value but lowers match density. The 2 remaining blanks exist as a tutorial
for the removal verb: an early obvious-good purchase that teaches what the shop does.

**Heal participates in matching. Only Blank does not.** Heal is balanced against block by
**value, not by rules**: at equal rarity, heal is worth less than block (1 stop of Heal = 4,
1 stop of Heavy Blk = 8). Heal doesn't expire and has no cap, so it must pay less per cell to
avoid dominating the defensive slot. Keep that 1:2 ratio if either is retuned — the value
doubling above preserved it exactly.

**Note:** at 1 stop, heal matching is close to a technicality — a Heal pair is p² = 0.25% per
adjacent position. If heal matching is meant to be a live consideration rather than a rare
novelty, it needs 2–3 stops, which means cutting elsewhere and shifting the damage/block ratio.
Flagged, not decided.

### Strip order (circular, 20 → 1)

| # | Symbol | # | Symbol | # | Symbol | # | Symbol |
|---|---|---|---|---|---|---|---|
| 1 | Light Atk | 6 | Light Blk | 11 | **Mega Atk** | 16 | Light Blk |
| 2 | Light Blk | 7 | Light Atk | 12 | Light Blk | 17 | Med Atk |
| 3 | Med Atk | 8 | Med Blk | 13 | Light Atk | 18 | Med Blk |
| 4 | Blank | 9 | Med Atk | 14 | Heal | 19 | Light Atk |
| 5 | Heavy Atk | 10 | Blank | 15 | Heavy Atk | 20 | **Heavy Blk** |

**Order is a design layer, not arbitrary.** Because a column shows 3 adjacent stops, what sits
next to what determines which symbols can co-occur vertically. In this arrangement:

- **18–20 (Med Blk, Heavy Blk, Light Atk)** is a jackpot window — 6 block plus damage in one
  column. Nearly always worth holding.
- **Mega Atk at 11 is flanked by a Blank at 10.** It always arrives with dead weight attached.
  Holding that column means eating a dead cell that may sit on a line you want.
- **Blanks cluster at 4 and 10** rather than spreading evenly. Even spacing produces uniformly
  mediocre columns; clustering produces a mix of clean and ruined, which sharpens hold choices.

---

## 4. Paylines

### Selection is post-spin

The player spins, holds, respins, *then* buys lines. Perfect information is correct here: the
decision is not "will this pay off" but "which action does this turn call for, given the intent."
Pre-spin selection is hollow — before the board exists all patterns are symmetric, so only the
count would matter.

### Line composition

- A line takes **one cell per column**, left to right — always 5 cells, always 4 adjacent pairs.
- The player starts the run owning the **three straights — top, center and bottom.** (The
  original spec was center-only; that gave the selection layer nothing to compare against until
  the first reward landed, so the turn had no decision in it.) The other nine *patterns* are
  acquired over the run and enter an inventory of options.
- **Each turn, the player selects one payline for free** from their owned patterns. Selecting
  *additional* paylines in the same turn costs tokens (see Multi-line below).

Two distinct things, easy to conflate:
**pattern inventory** = which shapes you own, grown permanently over the run;
**lines played this turn** = how many of them you activate right now, bought per turn.

### Scoring

A line pays the **sum of its symbols**, plus a bonus for matches.

- **Matching requires same exact symbol** (not same category) and must be **consecutive**,
  **minimum run of 2**.
- **Each run scores independently.** A run of 4 is worth far more than two separate pairs of the
  same symbol — consolidating a run is a real hold decision, not just accumulating copies.

Bonus per run, reusing the existing combo formula's **scaling terms only** (the flat sum is
already paid by the line's base sum — including it would double-count):

```
bonus = flat_sum * 0.35 * scale + scale
where flat_sum = symbol_value * count
      scale     = (count - 1) ^ 1.35
```

**Both knobs have been retuned** (from `0.12` / `1.3`). The original rate left the additive
`+scale` floor carrying **81%** of the bonus at a pair — which is where most matches land, so
matching barely registered. At `0.35` the floor is down to **42%** and the multiplicative term
drives the payout from a pair upward. The steeper exponent widens the gap between consolidating
a run and merely collecting copies:

| | run of 2 | 3 | 4 | 5 |
|---|---|---|---|---|
| bonus as % of flat | +50% | +133% | +213% | +290% |

Concretely, three Light Atks on one line pay **6** scattered, **8** as a pair plus a single, and
**14** consolidated into a run of 3 — so where the copies land is worth spending a hold on.

### Why consecutive + min 2

- Min-2 **non**-consecutive would fire on ~91% of lines — that's baseline damage with extra
  arithmetic, not a bonus.
- Min-2 consecutive fires on **~43%** of lines (Σp² over matchable symbols — everything except
  Blank — is 0.130; `1 − (1 − 0.130)^4`). Frequent enough to be a live consideration every turn,
  absent often enough that completing a run feels earned.
- Min-3 consecutive would be roughly 3× rarer and would go quiet exactly when you want more to
  think about.
- A run of 2 extends at *either* end, so chasing one with a respin has two outs, not one
  specific bridge cell.

### Multi-line

- **Multiple lines per turn is a core mechanic, not a rare effect.** It is the cleanest delivery
  of the offense/defense split: cover the intent with a block-heavy line, dump the rest into a
  damage line. With only one line, a single path must satisfy both, which is usually
  unsatisfiable and collapses into "take the least-bad line."
- **Overlapping cells double-dip** — a cell on two purchased lines pays into both. This is what
  makes pattern geometry a real decision and makes holds leveraged.
- **Cap at 3 lines per turn.** Souvenirs raise the cap; they do not cut the price. Cap increases
  are chunky and legible; price cuts silently break the economy everywhere at once.
- Temporary access to a line *beyond* the cap is a good drink/event effect — a burst payoff on a
  system the player already understands.

### Pattern acquisition

- Patterns are acquired through the run; the player chooses which to take.
- **In isolation, all patterns are statistically identical** — every visible row has the same
  marginal distribution, and every line has 4 adjacent pairs regardless of shape. Choice is
  meaningful only *relative to lines already owned*.
- The real axis is **concentrate vs. spread**: a pattern overlapping existing lines leverages
  holds (one held column pays into several lines) for a higher ceiling and swingier outcomes;
  a pattern avoiding them makes more of the board live for more consistent conversion.
- Curate **8–12 named, visually distinct patterns** out of the 243 possible. The pool must
  contain both concentrating and spreading options relative to a typical inventory, or the axis
  has nothing to offer.
- **Legibility requirement:** candidate patterns must be rendered against owned lines with shared
  cells highlighted. A coverage heat map of the board (how many owned lines touch each cell)
  doubles as the hold-decision aid, since a cell's worth is exactly its coverage count.
  - **Carried entirely by the glyph, with no prose.** Each offer draws its shape as a 3×5 mini
    grid and colours cells shared with an owned line hot. Spelling the same thing out in words
    underneath ("concentrates — 2 shared cells") was cut: the picture already says it, and the
    sentence just made the choice look more procedural than it is.

---

## 5. Economy

Tokens are a **persistent pool across the fight**, not per-turn refresh. Refreshing tokens are
use-it-or-lose-it, so the correct play is always "spend everything," and the decision evaporates.
Persistence makes every spend a comparison against future turns, which is what makes a
multi-turn intent queue pay off.

### Holds are FREE and fully toggleable

Reversing the earlier plan to price them. Column strips already make holds a real decision —
a held column is a *package* (the Mega Atk with a Blank attached, the jackpot window you can't
split), and its worth depends on which lines you intend to buy. The geometry does the work a
price tag was meant to do.

Also: on real machines you pay to *play*, never to keep. Video poker holds are free.

**Toggleable across respins.** Nothing changes between pressing hold and pressing respin, so
irreversibility there is a misclick tax, not commitment under uncertainty. After a respin
resolves, releasing a previously-held column *is* a real decision (new information arrived).
Locking held columns would punish correct early play and create a perverse incentive to
under-hold on respin 1.

Interface note: since holds are free and reversible, the hold set is really "which columns does
the respin button touch." Consider presenting the respin button with the count of columns it
will reroll, rather than 5 separate commitment gestures.

### Respins cost, incrementing within a turn

**1 / 2 / 3 / …** — the nth respin of a turn costs n tokens. Resets each turn. The increment
kills the fish-for-a-Mega-Atk failure mode without a separate rule, and a linear ramp keeps the
cost mentally trivial to track mid-turn.

This gives the allocation puzzle: **respins and lines draw on one pool**, so every turn is
*fix this board, or buy more out of it as-is.* Two opposed sinks, one budget.

### Line pricing

Price as a **multiple of per-turn token income**, not in absolute numbers.

- 2nd line ≈ **1.5–2 turns of income** (affordable ~every other turn if you spend on nothing
  else — a bank-and-spike decision, not a per-turn tax)
- 3rd line ≈ **3–4 turns of income** (a genuine event you save toward and usually skip)

**As implemented:** income is 1 token/turn, so the 2nd line costs **2** and the 3rd costs **4**
(6 tokens to hold all three at once). The token cap had to rise from 3 to **10** for this to
mean anything — a cap below the price of a single purchase makes "bank against future turns"
impossible and leaves the 3-line cap as dead content. Combats open at **3** tokens, well under
the cap, so banking stays a real multi-turn decision rather than something the opening hand
already affords.

Sanity check against intent: the strip averages 3.5/cell, so a random 5-cell line is ~17.5
before bonus — but split across types, which is the part that matters. The block share is
~6 per line against a typical intent of 10, so an average line covers **~60%** of the hit.
Defense stays slightly scarce relative to demand, which is the point (§3); damage is where the
surplus goes.

If players buy the 2nd line nearly every turn, **cut income rather than raising the price** —
income also gates respins.

**Known interaction:** with double-dip, respin value scales with lines purchased, so a flat
escalation curve reads cheap to a 3-line player. Acceptable (it's the reward for buying in);
if it needs a lever, scale respin cost by lines purchased rather than raising the base.

### Respin pricing

**As implemented:** the nth respin of a turn costs **1, 2, 3, 5, 8**, then +3 for each one past
that. The opening spin is free and automatic, so the lever is always a respin.

Superlinear past the third, and only past the third. A flat +1 per respin let a player banking
tokens buy six looks in one turn, which is searching for a board rather than gambling on one.
The first three rungs are deliberately unchanged because they are the only ones most players
reach: measured token income is **1.0/turn** with no Token stops, against **12.2/turn** with
three gilded ones. This ladder is build-facing content, so steepening its early rungs would tax
the build that pays for it while changing nothing for anyone else.

Note that no cost curve fixes a 12x income swing. If respins ever need a harder brake, that
ratio is the thing to attack, not the price.

### Gold

Two sources, deliberately: a flat payout for winning, and whatever the strip pays out.

**As implemented:** the player starts with **300g** and each win pays **100 ± 25**. Shop prices
sit at 50 (drink) / 100 (souvenir, stat upgrade) / 120 (remove) / 40–300 (stops), so a win is
about one item and the opening balance is about two. It started at 1000g for testing,
which is ten purchases — the first shop wasn't a decision, it was a supply run.

**The band is house variance, not a performance grade.** Scaling the payout by how fast the fight
ended would tax defensive play, and block is already deliberately scarce against demand (§3). It
should not be charged for twice.

**Economy stops are the second income, and the interesting one.** A stop spent on Coin, Chip or
Penny is a stop not spent on damage — a weaker board now for more buying power later. At a real
commitment (3 copies, 3 lines, an ~8-turn fight) Coin and Chip each return roughly 90g per fight
and Penny roughly 36g, so committing to gold about doubles income. The first copy is nearly
worthless and the third carries it, which is the increasing-return curve §6 prices for.

**Do not reprice the shop down to symbol-payout scale.** It looks like it would make the gold
symbols feel weightier, but discounts are percentage-based and integer-rounded: Frequent Flyer is
10% and Loyalty Card stacks 15%, so at single-digit prices they round to zero and become inert
content. The price ladder also needs the resolution to say that Light Atk is cheap and Wild is a
commitment. The two scales are already consistent — payouts were sized against these prices.

### Open: payline acquisition is too frequent

One new line after every combat is a lot of cognitive load — the set of
available lines never settles long enough to be learned, and a player tracking
which lines they own is not reading the board. The first line should still be
an immediate choice, but the rest want spacing: a combat counter, a level
threshold, or a shop offer competing against the other things gold buys.

Blocked on run length. At four encounters there is no room to space anything
out, so this can only be judged once the run is long enough for the gap between
acquisitions to be felt.

---

## 6. Shop Verbs

Three verbs, three different effects on strip length, which is what governs board consistency
(a specific stop is on-board `1 − (1 − 3/N)^5` of spins: 56% at N=20, 76% at N=12, 90% at N=8).

- **Remove** — strongest. Concentrates the distribution *and* shortens the strip, improving
  consistency on everything remaining. Price highest. Self-limiting (you run out of chaff).
- **Replace** — the workhorse and the default. Strictly positive, no hidden cost, always sensible.
- **Add** — weakest and situational. Gives one new symbol and charges dilution on everything
  else, including the thing just bought. Its only genuine advantages: it's the only verb that
  can add symbol *types*, and it's correct when nothing on the strip is worth losing.

### Replace and Add are the same purchase at the same price

The player **buys a stop, then places it.** Land it on an occupied position to replace; land it
between two to insert. One price, then the real question: *do I have something worth sacrificing,
or do I eat dilution?*

This self-balances — early runs the strip is full of chaff so replacement is obvious; late, when
everything is good, eating dilution becomes a live option. The decision gets harder as the build
improves, with no tuning.

Removal stays a separate service (it isn't buying a symbol), matching the existing gift shop's
remove-stop wall sign.

### Placement position matters

- **Every insertion edits the adjacency graph** — which symbols can co-occur in a column window.
  That's the layer that makes column holds interesting.
- **Duplicate copies should be spread, not clustered.** A payline takes one cell per column, so
  two copies inside the same column window can never both score on a line. Two Heavy Atks at
  stops 10 and 11 occupy 4 of 20 possible windows; the same two at 10 and 1 occupy 6 of 20 —
  50% better for the same stop count.

**Show the strip, not the analysis.** This originally read "invisible without UI support, show
it", and a full readout was built: window coverage before and after, dilution percentages, the
new column window, on-board odds at each strip length. It was **cut on sight in playtesting.**
Two problems, and the second is the real one:

- It stated conclusions the player should be reaching themselves. Working out that copies want
  spreading *is* the build layer; a label that says "spread copies apart" hands over the answer
  and leaves only data entry.
- It read as machine-written — dense, hedged, explaining its own reasoning at the player.

The editor now shows the strip in order, with each stop's symbol, and insertion points between
them. That's the whole surface. The adjacency consequence is legible from the strip itself,
because the strip is *right there in order* — which is the UI support the original note was
reaching for. Keep any future addition here concrete and short (a symbol, a position, a count);
never a sentence explaining what a number implies.

### Do not scale symbol price by how many copies are already on the strip

Match contribution scales with p², so the k-th copy adds `(2k−1)/N²` to match probability —
marginal value *rises* with each copy. That increasing return **is the build payoff**. Charging
more as the player specializes taxes exactly the commitment the system should reward. Price by
inherent symbol quality and let specialized builds extract more value.

---

## 7. Node Structure

The strip is **data** (`Array[Symbol]`, edited by the shop). Scrolling cells are a
**fixed-size recycled pool** — 5 nodes regardless of strip length, reassigned textures every
frame. They are a sliding window over the array, not a representation of it.

Consequence: **pool cells have no stable identity.** Node index 2 is not "the Mega Atk" — it's
"whatever is 1 above center right now." No game state can live on them.

```
ReelColumn (Control, clip_contents)
├─ ScrollLayer (Control)   # 5 recycled TextureRects, pure display, mouse_filter = IGNORE
└─ CellOverlay (Control)   # 3 static Panels at fixed row positions, mouse_filter = STOP
```

**Positions are stable, symbols aren't.** "Row 1 of column 3" is always the same screen position
and always the same cell on the payline grid; what symbol sits there changes every spin. So all
game logic — payline membership, highlighting, scoring-run indicators, hit-testing — attaches to
the **overlay**, which never scrolls.

This also solves curvature: the shader distorts the scroll layer only, so highlight rectangles
stay axis-aligned and click regions stay simple rectangles.

- **Scrolling cells:** `TextureRect` (needs `expand_mode` / `stretch_mode`).
- **Overlay markers:** `Panel` with `StyleBoxFlat` theme overrides swapped per state
  (neutral / on-purchased-line / in-scoring-run). `NinePatchRect` instead if the art direction
  wants hand-drawn cabinet framing rather than programmatic borders.
- **Hold state lives on `ReelColumn`**, not on cells — it's a whole-column property and should
  read as a column-level treatment.
- Set `mouse_filter` explicitly on both layers; defaults differ by node type.

---

## 8. Spin Animation

**No animation assets, and nothing baked.** The shop edits the strip constantly, so the reel must
render whatever is in the array at call time.

A spin is **one tween driving one float** (`scroll_pos`). Everything visual is derived from it:

- `base = floor(scroll_pos)` picks which stops are in view
- `frac = scroll_pos - base` slides them sub-stop for smooth motion
- When `scroll_pos` crosses an integer, every cell's texture swaps to the next stop at once

Cells don't animate "from Light Atk to Heavy Atk" — they slide a fixed distance while textures
get reassigned at wrap points. At 1.2s across dozens of stops the swaps are imperceptible.

### Landing is computed, not discovered

```gdscript
var from: int = int(floor(scroll_pos))
var forward: int = wrapi(target_stop - from, 0, strip.size())
var target: float = float(from + EXTRA_LOOPS * strip.size() + forward)
```

`forward` is the shortest *forward* distance, so the reel never reverses. `EXTRA_LOOPS * size`
prepends full revolutions purely for show. The tween endpoint **is** the target stop plus whole
revolutions, so easing shapes *how* it arrives but can never change *where*. No drift, no
snapping correction.

Edge cases handled for free: `target_stop == current` still spins three full revolutions (reads
as a real spin, not a no-op); a killed tween leaving `scroll_pos` fractional still floors to an
integer endpoint on the next `spin_to`.

`EXTRA_LOOPS` fixes **duration**, not speed — a 12-stop and a 30-stop strip both take
`SPIN_DURATION`. Do not tween through N stops at fixed speed; that makes thinned strips spin
faster, which reads as a bug.

### Curvature

Slight drum curvature for styling — **noticeable but never at the cost of legibility.** Use a
shader, not 3D geometry: real 3D fixes curvature by drum radius and camera FOV, which can't be
tuned independently, and the perspective squeeze lands hardest on the top and bottom rows where
zigzag paylines live.

The key trick 3D can't do cleanly: **animate the curvature amount.** Full effect while spinning,
easing toward near-flat as the reel settles. Classic drum motion during the spin, legible
symbols for the read.

Vertical darkening gradients at the window edges do more perceptual work for the cylinder
illusion than the geometry does, at zero legibility cost. Land closer to digital-slot convention
than physical-machine convention — the board has 15 cells to read, more than any real machine
asked of a player.

### Reference implementation

Per-symbol squeeze (compression steps at symbol boundaries; not noticeable at these values):

```gdscript
class_name Reel
extends Control

signal spin_finished(stops: Array[Symbol])

const VISIBLE_ROWS: int = 3
const BUFFER: int = 1
const POOL_SIZE: int = VISIBLE_ROWS + BUFFER * 2
const SYMBOL_HEIGHT: float = 96.0
const EXTRA_LOOPS: int = 3
const SPIN_DURATION: float = 1.2
const CURVATURE_SPINNING: float = 0.28
const CURVATURE_RESTING: float = 0.06

@export var strip: Array[Symbol] = []

var scroll_pos: float = 0.0:
	set(value):
		scroll_pos = value
		_layout()

var curvature: float = CURVATURE_RESTING:
	set(value):
		curvature = value
		_layout()

var _cells: Array[TextureRect] = []
var _spin_tween: Tween


func _ready() -> void:
	clip_contents = true
	custom_minimum_size.y = SYMBOL_HEIGHT * VISIBLE_ROWS
	for i in POOL_SIZE:
		var cell := TextureRect.new()
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_SCALE
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.size = Vector2(size.x, SYMBOL_HEIGHT)
		cell.pivot_offset = Vector2(size.x * 0.5, SYMBOL_HEIGHT * 0.5)
		add_child(cell)
		_cells.append(cell)
	_layout()


## Center-row strip index at rest.
func current_stop() -> int:
	return wrapi(int(floor(scroll_pos)), 0, strip.size())


## The three symbols occupying the payline rows, top to bottom.
func visible_stops() -> Array[Symbol]:
	var out: Array[Symbol] = []
	var base: int = int(floor(scroll_pos))
	for row: int in range(-1, 2):
		out.append(strip[wrapi(base + row, 0, strip.size())])
	return out


func spin_to(target_stop: int) -> void:
	if strip.is_empty():
		return
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()

	var from: int = int(floor(scroll_pos))
	var forward: int = wrapi(target_stop - from, 0, strip.size())
	var target: float = float(from + EXTRA_LOOPS * strip.size() + forward)

	_spin_tween = create_tween()
	_spin_tween.set_parallel(true)
	_spin_tween.tween_property(self, "scroll_pos", target, SPIN_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_spin_tween.tween_property(self, "curvature", CURVATURE_SPINNING, SPIN_DURATION * 0.15)
	_spin_tween.chain().tween_property(self, "curvature", CURVATURE_RESTING, SPIN_DURATION * 0.35)

	await _spin_tween.finished
	scroll_pos = float(wrapi(int(target), 0, strip.size()))
	spin_finished.emit(visible_stops())


func _layout() -> void:
	if strip.is_empty() or _cells.is_empty():
		return

	var base: int = int(floor(scroll_pos))
	var frac: float = scroll_pos - float(base)
	var center_y: float = SYMBOL_HEIGHT * VISIBLE_ROWS * 0.5
	var half_window: float = center_y + SYMBOL_HEIGHT

	for i in POOL_SIZE:
		var row: int = i - BUFFER - 1
		var cell: TextureRect = _cells[i]
		cell.texture = strip[wrapi(base + row, 0, strip.size())].texture

		var offset: float = (float(row) - frac) * SYMBOL_HEIGHT
		var norm: float = clampf(offset / half_window, -1.0, 1.0)
		var squeeze: float = 1.0 - curvature * norm * norm

		cell.position.y = center_y + offset * squeeze - SYMBOL_HEIGHT * 0.5
		cell.scale.y = squeeze
```

Driving it:

```gdscript
var target: int = randi() % reel.strip.size()
reel.spin_to(target)
var stops: Array[Symbol] = await reel.spin_finished
```

Stagger columns with a short `create_timer` between `spin_to` calls, or vary `SPIN_DURATION`
slightly per column. **Held columns simply never get `spin_to` called.**

If per-symbol curvature stepping becomes visible, move to a `SubViewport` + shader for a
continuous UV remap:

```glsl
shader_type canvas_item;
uniform float curvature : hint_range(0.0, 0.5) = 0.28;

void fragment() {
	float o = UV.y - 0.5;
	float norm = o * 2.0;
	UV.y = 0.5 + o * (1.0 + curvature * norm * norm);
	COLOR = texture(TEXTURE, UV);
}
```

This samples outside the viewport at the extremes, so the SubViewport needs one buffer symbol of
vertical padding beyond what's displayed — which the existing pool already provides.

**Guard `strip.size() < POOL_SIZE`.** `wrapi` handles it correctly but the same symbol appears
twice in the window. Either floor strip size at ~5 in the shop, or allow it — a reel thinned that
far arguably *should* look repetitive.

---

## 9. Board Reading UI

15 cells re-scanned after every respin is a real cost, and the expensive part is **tracing the
path**, not computing totals.

- **On payline hover: highlight that line's 5 cells, dim everything else**, and draw the path
  itself cell-centre to cell-centre. Highlighting says *which* cells; the drawn line says the
  order and the shape, which highlighting alone can't convey. Both belong on the overlay layer.
- Text summary carries what highlighting can't — the split, the matched runs, the cost:

```
Line 4 — 3 tokens
9 ATK · 4 BLK
Med Atk ×2 matched (+3)
```

- **The summary states the outcome and stops there.** It was originally specified to show block
  as a delta against intent (`4 / 11 BLK`, `−7`), plus a *marginal* preview once a line was
  purchased, on the reasoning that the satisfice decision is a comparison so the UI should
  display the comparison. **Both were built, played, and cut.** Doing the comparison on the
  player's behalf is doing their thinking for them: the intent is already telegraphed on the
  enemy, and reading the board against it is the decision the whole turn is built around. The
  readout gives ATK/BLK/HEAL and the matched runs; the weighing is the player's.
  - Block overflow is still wasted at resolution (§10) — that rule didn't change, it just
    isn't spelled out in the UI.
  - Consequence to accept: with double-dip, a second block-heavy line can be worth much less
    than its standalone number suggests, and nothing warns you. That's the intended cost.
- **Hover a single cell to read that stop's effect** ("4 damage", "2 block") — one line, no
  symbol name, no match table. Enough to answer "what is that", not a second summary.
- Hover is absent on touch and slow when comparing 5+ candidate lines, so the list of owned
  lines is persistent, with hover reserved for the *path* and the readout. Comparison becomes a
  glance rather than a sequence of hovers.
  - The rows carry **only the line's name.** Per-line numbers on every row were noise next to
    the readout and the board.
- **The readout must live outside the list container, at a fixed size.** If it shares a
  container, its text growing on hover resizes the panel, pushes rows out from under the cursor,
  and re-fires `mouse_exited`/`mouse_entered` — flickering between two states every frame. Hold
  the size by hanging the labels off an anchored child, which contributes no minimum size.
- The existing `HoverLabel` autoload (cursor-following, `show_dynamic`) already provides the
  plumbing.
- **Make the free center line genuinely playable.** Depth should be available every turn, not
  mandatory every turn — a player must be able to take the obvious line and move on when the turn
  doesn't warrant deliberation.

---

## 10. Preserved From Current Systems

- **Telegraphed enemy intent with a visible number** — already exists. It must keep *varying*
  turn to turn, and should sometimes telegraph beyond the current turn (wind-ups, small/small/huge
  patterns). Multi-turn visibility is what gives the persistent token pool something to bank
  against. "See one extra turn of intent" is a clean non-numeric Souvenir effect.
- **Block expires at end of turn; excess block is wasted.** This asymmetry is the whole mechanism —
  it produces satisfice-on-defense, optimize-on-offense. If block carried over or overshoot were
  free, the target dissolves and the board collapses to maximizing one number.
- **Heal stays rare and separate from block.** Unconditional value with no target; it doesn't
  participate in the satisfice decision.
- `CombatContext.turn_number` is still missing and is needed.
- `RunEffect` / Souvenirs / Drinks / drunkenness are unchanged at the architecture level, but
  every Souvenir written against the old resolver needs re-examining.

---

## 11. Retired or Invalidated

- **Typed reels** (Attack / Defend / Heal categories) — replaced by the master reel.
- **The reel loadout modal** — the build layer moves to strip composition. This is a system swap,
  not an addition.
- **The combo formula as a top-level scorer** — it survives only as per-line run bonus, scaling
  terms only, with both knobs retuned.
- **Paid holds** — considered and rejected; column geometry does that work.

---

## 12. Open / Undecided

- **Respin cost curve** and whether it scales with lines purchased. Playtest question.
- **Line pricing** against real income numbers. First pass is in (§5) and holding; still the
  most likely thing to need moving once fights are played end to end.
- **Enemy numbers.** Untouched by the value retune: enemies are 100 HP with intents of 10–35,
  so a single line now kills in ~5–7 turns instead of ~20. If fights read as too short, enemy
  HP is the lever — not the symbol values, which are what makes block scarce against intent.
- **Board growth, if any.** Rows are fixed at 3, so the board's only remaining size axis is
  columns — and columns are the expensive one. Every added column shifts match probability
  (7 adjacent pairs at width 8 pushes match frequency past 60%), extends `scale`'s ceiling,
  lengthens the traced path, and multiplies the pattern space (3⁸ = 6,561 vs 243). Growth is
  therefore better routed into **strip composition and pattern inventory**, which are already
  two axes and need no retuning. If board width does become an upgrade, every number in §5 has
  to scale with it.
- **Layout.** Mostly settled. Cells landed at **144px**, so the board is 768×432 and the machine
  1548×549, hugging its content with the grid's midpoint exactly on the screen centre — the
  payline column and the lever bay are equal-width flanks, which is what holds that centring.
  The remaining **upstream question is how large the enemy needs to be**: a static portrait +
  HP bar + intent is ~400px; animated character art with attack telegraphs is not. That
  art-direction commitment gates whatever fills the room above the machine.
- **Symbol art** — the strip currently uses effect names (Light Atk etc.) as placeholders drawn
  as coloured cells. Final symbols should be classic slot iconography, now readable at ~144px.

---

## 13. Build Order

Build the whole thing in one pass — no stopping to check in between phases. The ordering below
exists so the loop becomes **playable as early as possible**, before the expensive parts are
built, so that a flat core surfaces immediately rather than after the pattern system, multi-line,
and shop are all in place. Build straight through; the ordering is about de-risking, not about
gating on approval.

The core bet the whole overhaul rests on: **post-information composition choice produces real
decisions in this game, at this pacing, against these intent numbers.** Phase 1 makes that bet
playable. Everything after amplifies it. If Phase 1 turns feel flat, no later phase fixes it —
so build Phase 1 such that it can actually be played and felt, not just compiled.

### Phase 1 — Playable core (the load-bearing bet)

A complete, playable turn on the **3×5 grid** with a **single center payline**. This is the
minimum that exercises the inversion on the real board.

- Master reel: one shared 20-stop strip (§3), all 5 columns sampling it, columns as 3-cell
  windows into adjacent stops (§2).
- Spin animation (§8) and the `Reel` node structure (§7). Whole-column holds, free and
  toggleable across respins (§5).
- Respins cost 1 / 2 / 3… incrementing per turn, from a persistent token pool (§5).
- **One payline: the straight center row.** No inventory, no selection UI yet — it's always the
  center line.
- Line scoring (§4): sum of symbols + per-run bonus, exact-symbol matching, consecutive, min-2,
  runs scored independently.
- Resolve into **damage and block**, block expiring end of turn with excess wasted (§10).
- Telegraphed enemy intent with a visible number (§10); add `CombatContext.turn_number`.

At the end of Phase 1 the turn is: spin → hold → respin (paying) → the center line resolves
against intent. That is the inversion, minus geometry. It is the thing to actually play and feel
before continuing.

### Phase 2 — Pattern inventory and selection

- Pattern inventory: the run owns shapes, starting with only the center row (§4).
- Per-turn the player selects **one** owned payline for free.
- Curate 8–12 named, distinct patterns (§4) and the acquisition path to gain them.
- Hover-to-highlight the selected line's 5 cells; the text summary with the intent delta (§9).

This is where line *geometry* first matters — zigzags, edge lines — and where the reading-load
UI earns its place.

### Phase 3 — Multi-line and intersections

- Allow selecting **additional** paylines in a turn for a token cost; cap at 3 (§4).
- **Double-dip**: shared cells pay into every line they're on (§4). This is what makes pattern
  geometry a decision rather than decoration.
- Marginal-value preview once a line is purchased (§9) — standalone totals mislead under
  double-dip.
- Line pricing per §5; treat the numbers as starting points to tune in play.

Multi-line is the actual delivery mechanism for the offense/defense split — cover intent with a
block-heavy line, dump the rest into damage. Only here does the core tension reach full strength.

### Phase 4 — Shop verbs (build layer)

- Buy-a-stop-then-place, replace vs. insert as a placement choice at one price (§6).
- Remove as a separate, higher-priced service (§6).
- Surface placement position: adjacency-graph edits and duplicate-spreading (§6).
- Price by inherent symbol quality, never by copies already on the strip (§6).

The shop closes the loop between combats and makes the strip a build. It comes last because it
only matters once the combat it feeds is proven.

### Cross-cutting, throughout

- Curvature shader (§8) can land in Phase 1 or be deferred; it's cosmetic and gates nothing.
- Every Souvenir written against the old resolver needs re-examining against the new one (§10)
  as its hooks come online.
- Retire typed reels and the loadout modal in Phase 1 — the shared strip replaces both, so they
  go early, not at some later "grid" step.

### What to watch in Phase 1 specifically

Because Phase 1 is the bet, judge it honestly before leaning on later phases to rescue it:

- **Does the same board admit two defensible plays that differ in kind** — cover the hit and fall
  behind, or eat it and push lethal — rather than one computable best?
- **Do you ever decline to respin while holding tokens?** If respinning is always correct, the
  board isn't insufficient enough for banking to compete — check the 50/35 damage/block ratio (§3)
  before concluding the design is wrong.
- A single center line is deliberately the *weakest* version of the loop (no geometry, no
  multi-line). If it already produces decisions, later phases only deepen them. If it's flat,
  diagnose the strip and intent numbers before adding systems on top — more systems won't fix a
  loop that's flat at its core.
