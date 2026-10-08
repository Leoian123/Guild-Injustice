# Gilda Grigia — prototipo Fase 1

Autobattler tattico dark fantasy in Godot 4. Il giocatore esplora con 3 rivelazioni nella nebbia, schiera unità con un budget, poi le unità combattono da sole. Fase 1 = solo il puzzle di combattimento: una mappa, una fazione nemica, 5 unità del giocatore.

<!-- Note per l'umano: questo file si carica in ogni sessione, tienilo sotto le 200 righe.
     Le regole per cartella sono in .claude/rules/, i flussi in .claude/skills/. -->

## Dove sta cosa
- Regole del gioco (fonte di verità): `docs/GDD_fase1.md`
- Milestone e criteri di accettazione: `docs/MILESTONES.md`
- Test di regola con valori attesi: `docs/TESTS.md`
- Decisioni prese e domande aperte: `docs/DECISIONI.md`
- Scelte di comodo da rivedere rispetto alla visione finale: `docs/DELTA.md`. Ogni nuova scorciatoia si registra lì quando la si prende, e il report di fine milestone elenca le voci aggiunte o cambiate.
- Versioni di Godot e GdUnit4 in uso: `docs/VERSIONI.md`
- Mappa: `data/maps/temple_01.txt` · Strategie di riferimento: `tools/strategies/`

Leggi le sezioni del GDD che servono al compito corrente, non tutto il documento.

## Ambiente
- Windows con Git Bash. L'eseguibile di Godot è nella variabile d'ambiente `GODOT`; usa sempre `"$GODOT"`, mai un percorso scritto a mano.
- GDScript tipizzato, sintassi Godot 4. Test con GdUnit4 in `addons/gdUnit4/`.

## Comandi
- `bash tools/check.sh` — import, controllo errori nel log, test. Esce con codice ≠ 0 se qualcosa fallisce. È la definizione di "verificato".
- `bash tools/sim.sh --scenario temple_01 --strategy tools/strategies/<file>.json --seed 42 --out <file>.jsonl` — simulazione headless (contratto in GDD §11).
- `bash tools/sim.sh ... --seeds 1-100` — batch.
- `"$GODOT" --path .` — avvia il gioco (solo l'umano lo guarda).

`tools/check.sh` e `tools/sim.sh` si creano in M1 (vedi `docs/MILESTONES.md`).

## Architettura
- Logica di gioco in classi `RefCounted` sotto `src/sim/`, eseguibile headless senza scene. `src/view/` e `src/ui/` leggono lo stato e disegnano: non decidono nulla.
- Simulazione deterministica a tick fisso: stesso input + stesso seed = stesso `state_hash`. Dettagli in `.claude/rules/simulation.md`.
- Numeri di bilanciamento solo in `data/` (`UnitData`, `ScenarioData`, `data/rules.tres`). Mai negli script.
- Abilità come componenti (`BreedAbility`, `BackstabAbility`, …), non sottoclassi di `SimUnit`.
- Niente ECS, niente fisica di Godot per il combattimento, niente addon oltre a GdUnit4.

## Identificatori canonici
Unità: `rat` `rabbit` `goblin` `archer` `thief` `paladin` · `servant` `undead` `revenant` `necromancer`.
Stati: `IDLE` `MOVE` `ATTACK` `FLEE` `DEAD`. Fazioni: `PLAYER` `ENEMY`. Gruppi: `blitz` `hunt`.
Abilità: `WanderBehavior` `BreedAbility` `PackCourageAbility` `PointBlankPenalty` `BackstabAbility` `ArmorAbility` `ReanimateAbility` `FearlessTrait`.
Volontà: `HoldGroundWill` `HungerWill` `NecroBoundWill` `PreyWill`.
Non inventare sinonimi.

## Decidere o chiedere
- **Decidi e annota** in `docs/DECISIONI.md` i dettagli tecnici che non cambiano chi vince: struttura delle classi, rappresentazione interna, nomi, organizzazione dei test, flag della toolchain.
- **Chiedi** per tutto ciò che può cambiare l'esito di una battaglia: distanze, tempi, danni, priorità, ordine del tick, vittoria e sconfitta, comportamento delle unità.
- Non fermarti a ogni dubbio: annota la domanda in `DECISIONI.md` con stato `da confermare`, prosegui sulle parti indipendenti e presenta tutte le domande insieme nel report.
- IMPORTANT: se un test di `docs/TESTS.md` contraddice il GDD, non adattare il codice per farlo passare. Segnala la contraddizione e aspetta.

## Cosa non toccare
- Mappa, strategie di riferimento, `addons/`, `.godot/`: bloccati dai permessi.
- GDD, test, milestone, valori numerici in `data/`: modificabili solo su richiesta esplicita (i permessi chiedono conferma).
- Non aggiungere funzionalità, parametri o sistemi che il GDD non chiede.

## Flusso di lavoro
- Una milestone alla volta: `/milestone M<n>` esegue il flusso completo.
- Commit a ogni `tools/check.sh` verde, messaggio `M<n>: <cosa>`.
- Non dichiarare finito un lavoro senza mostrare l'output di `tools/check.sh`.
- Non vedi lo schermo: verifica con log, `tools/sim.sh` e, da M5, con lo screenshot di `tools/screenshot.gd`.
- Durante la compattazione conserva: milestone corrente, file modificati, domande aperte.

## Lingua
Codice, commenti e identificatori in inglese. Documentazione in italiano.
