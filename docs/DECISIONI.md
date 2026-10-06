# Decisioni

Registro delle decisioni dell'agente. Le voci `da confermare` sono domande per l'umano: vanno tutte nel report di fine milestone.

Formato:

```
### D-<numero> · <titolo breve>
- Sezione GDD: §x.y
- Ambiguità: …
- Scelta: …
- Alternative: …
- Cambia l'esito di una battaglia: sì / no
- Stato: confermata | da confermare
```

Se "Cambia l'esito" è "sì", lo stato iniziale è sempre `da confermare`.

---

### D-000 · Rianimazioni potenti
- Sezione GDD: §8
- Ambiguità: un paladino o un revenant rianimato è un nemico molto forte (400 o 250 di vita).
- Scelta: tenuto così, per dare un motivo per uccidere il necromante per primo.
- Alternative: rianimati con vita dimezzata; esclusione delle unità d'élite.
- Cambia l'esito di una battaglia: sì
- Stato: da confermare (decisione dell'umano, da rivedere dopo il primo report di bilanciamento)

### D-001 · Valore di `tick` nello `state_hash`
- Sezione GDD: §12, §6.1
- Ambiguità: `tick=<n>` non dice se è l'ultimo tick eseguito o il prossimo.
- Scelta: `World.tick` è l'indice del prossimo tick da eseguire. Parte da 0; dopo il tick 99 vale 100.
- Alternative: indice dell'ultimo tick eseguito (-1 prima di iniziare).
- Cambia l'esito di una battaglia: no (cambia solo il testo dell'hash)
- Stato: confermata

### D-002 · Testo dello `state_hash`
- Sezione GDD: §12
- Ambiguità: separatori, fine riga finale, rappresentazione di fazione e stato.
- Scelta: righe unite da `\n` con `\n` finale, SHA-256 esadecimale minuscolo (`String.sha256_text()`). Fazione e stato con i nomi canonici (`PLAYER`, `IDLE`, …), tipo con l'ID canonico (`paladin`). Float con `%.4f`.
- Alternative: numeri degli enum; nessun `\n` finale.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-003 · Nomi e tipi in `data/rules.tres`
- Sezione GDD: §10
- Ambiguità: le costanti del GDD sono in maiuscolo; tipo intero o float.
- Scelta: `RulesData` (`src/sim/rules_data.gd`) con le stesse costanti in snake_case minuscolo (`TICK_RATE` → `tick_rate`). Interi per tick e conteggi (`*_TICKS`, `TICK_RATE`, `REVEALS`, `COURAGE_MIN_ALLIES`, `ARMOR_REDUCTION`, `SURROUND_COUNT`, `RAT_CAP`); float per raggi, rapporti e moltiplicatori, compreso `backstab_mult = 4.0` (per danni interi `floor(d × 4.0) = d × 4`).
- Alternative: proprietà in maiuscolo; `backstab_mult` intero.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-004 · `SimUnit` e `UnitData` minimi in M1
- Sezione GDD: §6.1, §12; `docs/TESTS.md` (ancore)
- Ambiguità: T00 richiede le ancore, ma `UnitData` e le unità arrivano in M3–M4.
- Scelta: `UnitData` con solo `unit_type` e `max_hp`; `SimUnit` con i soli campi dello `state_hash` più `ai_enabled`. Nel test le ancore usano `UnitData` costruite nel test (paladino 400, non morto 80, dal GDD §7–§8). L'orientamento iniziale resta `(0,0)` finché M3 non implementa il §6.5, che richiede la posizione della reliquia dalla mappa (M2). `SimCorpse` esiste già per lo `state_hash`. Le 8 fasi del §6.2 sono metodi vuoti di `World.step()`.
- Alternative: rimandare T00 a M3.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-005 · `tools/check.sh`
- Sezione GDD: —; `docs/MILESTONES.md` M1
- Ambiguità: flag e criteri del gate.
- Scelta: tre passi (import, avvio della scena principale con `--quit-after 10`, test GdUnit4); log in `reports/raw/check/`, report GdUnit4 in `reports/raw/gdunit/` (ignorati da git). Un passo fallisce se il codice di uscita è diverso da 0 o se il log contiene `SCRIPT ERROR`, `Parse Error`, `Failed to load` o righe che iniziano con `ERROR:`. Il codice 101 di GdUnit4 (solo warning) è un fallimento. Fallisce anche se non è stato eseguito nessun test. Verificato: un errore di sintassi in `src/sim/` fa fallire il passo dei test (105) ma non l'import né l'avvio, che non caricano gli script della simulazione.
- Alternative: accettare il 101; caricare tutti gli script all'avvio.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-006 · Fine riga e file generati da Godot
- Sezione GDD: —
- Ambiguità: git su Windows converte LF in CRLF; Godot genera `.uid` e `.import`.
- Scelta: `.gitattributes` con `eol=lf` per i file di testo (CRLF solo per `.cmd` e `.bat`, PNG binari). I `.uid` e `.import` sono versionati, compresi quelli in `addons/`. Il parser della mappa (M2) accetterà comunque anche `\r\n`.
- Alternative: lasciare la conversione automatica.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-007 · `tools/sim.sh` in M1
- Sezione GDD: §11
- Ambiguità: comportamento prima che scenario e battaglia esistano; codice per argomenti errati.
- Scelta: legge e valida gli argomenti del §11 e crea un `World` per seed, stampando lo `state_hash` su stdout. Non scrive ancora il file `--out` (JSON Lines in M6). Argomenti mancanti o errati: codice 1 e uso su stderr (il 2 resta per la validazione della strategia). I percorsi sono relativi alla radice del progetto. Se manca `.godot/` esegue prima l'import.
- Alternative: file `--out` con righe vuote già da M1.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-008 · Scena principale e plugin
- Sezione GDD: —
- Ambiguità: l'avvio headless richiede una scena principale.
- Scelta: `src/main.tscn`, un `Node` vuoto che diventerà il gioco in M5. Il plugin GdUnit4 è abilitato in `project.godot` per usarlo dall'editor.
- Alternative: nessuna scena principale e avvio solo tramite script.
- Cambia l'esito di una battaglia: no
- Stato: confermata
