# Milestone, Fase 1

Una milestone alla volta, con `/milestone M<n>`. Si chiude quando i test indicati passano, `tools/check.sh` è verde e il criterio di chiusura è soddisfatto.

## M1 — Scheletro
- **GDD**: §6.1, §6.2 (solo struttura delle fasi), §10, §12.
- **Lavoro**:
  - Progetto Godot, cartelle (`src/sim`, `src/view`, `src/ui`, `data`, `tools`, `test`, `reports`), `.gitignore` già fornito.
  - GdUnit4 in `addons/gdUnit4/`.
  - Verifica sulla versione installata e annota in `docs/VERSIONI.md`: versione di Godot e GdUnit4, disponibilità di `--import`, flag di GdUnit4 per l'headless (es. `--ignoreHeadlessMode`), codici di uscita di GdUnit4 con i soli warning.
  - `tools/check.sh`: import, avvio headless con controllo del log (`SCRIPT ERROR`, `Parse Error`, `Failed to load`, righe `ERROR:`), test. Esce con codice ≠ 0 se una delle tre fallisce.
  - `tools/sim.sh` e `tools/run_sim.gd` con gli argomenti del §11 (per ora creano solo il `World`).
  - `data/rules.tres` con le costanti del §10. `World` con tick, RNG con seed e `state_hash`.
- **Test**: T00.
- **Chiusura**: `bash tools/check.sh` verde su un clone pulito.

## M2 — Mappa, movimento, visione
- **GDD**: §4, §5.2, §5.3, §6.3.
- **Lavoro**: caricamento di `temple_01.txt`, pathfinding, linea di vista, rendering a forme della mappa.
- **Test**: T17, T18.
- **Chiusura**: test verdi.

## M3 — Combattimento base
- **GDD**: §6 completo.
- **Lavoro**: `SimUnit`, `UnitData` (solo `goblin`, `undead`, `archer` per i test), modalità di test di `docs/TESTS.md`, stati, ingaggio, bersagli, orientamento, fotografia, attacchi, danni simultanei, morti e cadaveri, limite di inseguimento.
- **Test**: T02, T03; T00 esteso a un mondo con unità che combattono.
- **Chiusura**: test verdi.

## M3.1 — Volontà di combattere
- **Origine**: risposte dell'umano a D-014 e D-015. Il limite di inseguimento uguale per tutti diventa la volontà di ogni unità; le unità a distanza arretrano (kiting).
- **Prerequisito**: l'umano approva `docs/PROPOSTA_M3.1.md`, eventualmente cambiando i numeri marcati (?). Poi l'agente porta i testi approvati in `docs/GDD_fase1.md` (§6.6, nuovo §6.8, §7, §8, §10, §13), `docs/TESTS.md` (T19–T23), `data/rules.tres` e `CLAUDE.md` (identificatori), e cancella la proposta.
- **GDD**: §6.6, §6.8, §10.
- **Lavoro**: componenti `HoldGroundWill`, `HungerWill`, `NecroBoundWill` (non sottoclassi di `SimUnit`); campo `chase_radius` in `UnitData`; arretramento delle unità a distanza nella fase 3; tolta la costante `LEASH_RADIUS`. Le unità in `data/units/`, il vagabondaggio dei ratti e le abilità restano in M4.
- **Test**: T19–T23; T00, T02, T03 restano verdi.
- **Chiusura**: test verdi.

## M4 — Unità e abilità
- **GDD**: §7, §8, §10.
- **Lavoro**: tutte le `UnitData` in `data/units/` con i valori iniziali; tutte le abilità come componenti.
- **Test**: T04–T11, T14, T16.
- **Chiusura**: test verdi.

## M5 — Fasi di gioco e interfaccia (collaudo umano)
- **GDD**: §2, §5.1.
- **Lavoro**: ricognizione con 3 rivelazioni e indicatori di minaccia; schieramento con budget e vincolo di visibilità; battaglia con pausa e velocità; schermata di risultato; debug (etichette stato/vita, griglia, rivela tutto, linee di vista del bersaglio). `tools/screenshot.gd`, eseguito senza `--headless`, salva un PNG di un frame per il controllo visivo dell'agente.
- **Test**: nessun test di regola nuovo; `tools/check.sh` verde.
- **Chiusura**: l'agente consegna istruzioni di collaudo (cosa provare, cosa aspettarsi) e uno screenshot per fase. **La milestone si chiude solo quando l'umano conferma** di aver giocato una partita completa con il mouse.

## M6 — Scenario e strumenti
- **GDD**: §3, §9, §11.
- **Lavoro**: `ScenarioData` di `temple_01` con le varianti, condizioni di fine battaglia, `tools/sim.sh` completo (validazione, `by_variant`, JSON Lines, riepilogo per combinazione).
- **Test**: T01, T12, T13, T15.
- **Chiusura**: test verdi, poi `/balance-report 1-100`. L'agente consegna il report e non modifica dati o regole per migliorare i risultati.
