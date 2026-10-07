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
- Stato: superata da D-024 (GDD §12 riscritto il 7 ottobre 2026: ogni entità descrive sé stessa).

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

### D-009 · Supercover sui bordi delle celle
- Sezione GDD: §5.2
- Ambiguità: "tutte le celle toccate dal segmento" non dice se un segmento che corre esattamente lungo il bordo tra due celle (per esempio `x = 8.0`) tocca le celle di entrambi i lati. Il caso dello spigolo diagonale è esplicito e già coperto.
- Scelta: una cella è toccata se il suo quadrato **chiuso** `[x, x+1] × [y, y+1]` interseca il segmento (`SimVision.touched_cells`). Un segmento lungo un bordo tocca quindi le celle di entrambi i lati, e basta un muro su un lato a bloccare la vista. Un segmento che passa per uno spigolo tocca tutte e quattro le celle, come chiede il §5.2. Con unità al centro delle celle il caso del bordo non si presenta; può capitare durante il movimento (M3).
- Alternative: contano solo le celle di cui il segmento attraversa l'interno, più la regola dello spigolo; un segmento lungo un bordo vedrebbe allora oltre un muro adiacente.
- Cambia l'esito di una battaglia: sì (solo nel caso limite del bordo)
- Stato: confermata (umano, 2026-10-06: scelta a, niente colpi radenti oltre i muri)

### D-010 · Configurazione del pathfinding
- Sezione GDD: §6.3
- Ambiguità: dettagli di `AStarGrid2D`.
- Scelta: `SimPathfinder` usa `DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES` (diagonale solo con le due ortogonali libere) e l'euristica `EUCLIDEAN` sia per il costo (1 e √2) sia per la stima (ammissibile, quindi percorsi di costo minimo), senza `jumping`. `find_path` restituisce le celle da partenza ad arrivo comprese, oppure un array vuoto se l'arrivo non è raggiungibile. Costo verificato su `temple_01`: cimitero `(8,33)` → reliquia 41,3137; piazzale `(35,30)` 16; esterno dell'ingresso est `(56,14)` 21.
- Alternative: euristica `OCTILE` (stesso costo minimo).
- Cambia l'esito di una battaglia: no (il costo minimo è fissato dal GDD; a parità di costo la scelta fra percorsi equivalenti è deterministica)
- Stato: confermata

### D-011 · `SimMap`
- Sezione GDD: §4
- Ambiguità: rappresentazione e celle fuori dalla griglia.
- Scelta: muri in un `PackedByteArray`; le celle fuori dalla griglia contano come muro. `E` e `R` sono pavimento. Le celle `E` sono conservate per la vista. Il caricamento accetta LF e CRLF e rifiuta righe di lunghezza diversa, simboli sconosciuti e un numero di reliquie diverso da 1.
- Alternative: nessuna rilevante.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-012 · Vista della mappa e fixture dei test
- Sezione GDD: §4
- Ambiguità: dove stanno dimensione delle celle e colori; dove sta la mappa di test.
- Scelta: `MapView` (`src/view/map_view.gd`) disegna rettangoli e un cerchio per la reliquia. I 16 px per cella sono impostati in `src/main.tscn`; i colori sono costanti di presentazione nella vista. Finestra 1024×640, cioè 64×40 celle. Mappa di test, ancore e `UnitData` minime dei test sono in `test/support/test_worlds.gd` (`TestWorlds`). Da M2 T00 usa la mappa di test.
- Alternative: dimensione delle celle in `data/`.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-013 · Movimento lungo il percorso in M3
- Sezione GDD: §6.3
- Ambiguità: M2 si intitola "movimento", ma lo spostamento richiede velocità (`UnitData`), stati e bersagli, che arrivano in M3.
- Scelta: M2 fornisce percorso e costo. Lo spostamento di `velocità / 20` celle per tick lungo il percorso si implementa nella fase 3 in M3.
- Alternative: una funzione di avanzamento lungo il percorso senza ancora unità che la usino.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-014 · Come si misura il limite di inseguimento
- Sezione GDD: §6.6
- Ambiguità: "inseguono un bersaglio solo entro `LEASH_RADIUS` dal punto di schieramento: se per raggiungerlo dovrebbero uscirne, lo abbandonano". Non è detto se "raggiungerlo" significa arrivare sul bersaglio o arrivare a portata d'attacco, né se la distanza è in linea d'aria o lungo il percorso.
- Scelta: un'unità del giocatore può avere come bersaglio solo un nemico con `distanza(punto di schieramento, nemico) ≤ LEASH_RADIUS + raggio d'attacco`, in linea d'aria. Per il corpo a corpo il limite è 7, per l'arciere 12. Il controllo vale sia nella scelta sia in ogni tick successivo: se il bersaglio esce dal limite viene abbandonato subito, come uno non più notato. Senza bersaglio l'unità torna al punto di schieramento. I nemici non hanno limite. L'eccezione dei ratti arriva in M4.
- Alternative: (a) il nemico stesso deve stare entro `LEASH_RADIUS` dal punto di schieramento (limite 6 per tutti, l'arciere non tira oltre); (b) come la scelta, ma con la distanza lungo il percorso A* invece che in linea d'aria (conta i muri, più costoso).
- Cambia l'esito di una battaglia: sì
- Stato: superata (umano, 2026-10-07: la volontà di inseguire dipende dall'unità — fame, influenza del necromante, coraggio; vedi M3.1 e GDD §6.8). Fino a M3.1 resta in vigore la scelta implementata.

### D-015 · Quando un'unità smette di avvicinarsi al bersaglio
- Sezione GDD: §6.3, §6.5
- Ambiguità: il GDD dice di muoversi verso il bersaglio e di attaccare se è a portata e in vista, ma non se l'avvicinamento si ferma esattamente al raggio d'attacco a metà tick.
- Scelta: nella fase 3, se il bersaglio è già a portata e in vista l'unità non si muove; altrimenti percorre tutto il passo del tick (`velocità / 20`). Può quindi finire fino a un passo più vicina del raggio d'attacco (al massimo 0,16 celle). Il percorso segue i centri delle celle di A* (partendo dalla cella della posizione attuale) e l'ultimo punto è la posizione esatta della destinazione. Viene ricalcolato a ogni tick. L'orientamento diventa la direzione dell'ultimo tratto percorso nel tick.
- Alternative: fermarsi a metà tick appena si entra a portata (distanza finale = raggio d'attacco, salvo vista).
- Cambia l'esito di una battaglia: sì (di poco: posizioni finali diverse fino a un passo)
- Stato: superata (umano, 2026-10-07: il corpo a corpo ingaggia, le unità a distanza arretrano; vedi M3.1 e GDD §6.8). Il corpo a corpo resta come implementato.

### D-016 · Significato degli stati
- Sezione GDD: §6.2
- Ambiguità: il GDD elenca gli stati ma non quando si passa dall'uno all'altro, salvo `FLEE` e `DEAD`.
- Scelta: con IA attiva, nella fase 3, `ATTACK` se il bersaglio è a portata e in vista (anche durante la ricarica), `MOVE` se l'unità si è mossa, altrimenti `IDLE`; l'unità che attacca nella fase 4 è in `ATTACK`; `DEAD` nella fase 6. Con IA spenta lo stato cambia solo in `DEAD` ("non cambia stato da sola"). `FLEE` arriva in M4. Lo stato oggi non decide nulla: entra nello `state_hash` e nella vista.
- Alternative: `ATTACK` solo nel tick del colpo.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-017 · Modalità di test e campi di `SimUnit`
- Sezione GDD: —; `docs/TESTS.md` "Modalità di test"
- Ambiguità: valore di `target_id` con IA spenta; dove stanno le statistiche dei test.
- Scelta: con IA spenta `target_id` vale `forced_target_id` se quell'unità è viva, altrimenti -1 (conta solo per lo `state_hash`). Una morta ha `target_id` -1 e conserva la vita ≤ 0. `SimUnit` copia da `UnitData` le statistiche e converte l'intervallo d'attacco in tick alla creazione (`UnitData.seconds_to_ticks`), senza scrivere sulla Resource. Le statistiche dei test (`TestWorlds.GDD_STATS`) sono trascritte dal GDD §7–§8 per `goblin`, `archer`, `undead`, più `servant` (serve a T02) e `paladin` (ancora), finché M4 non crea `data/units/`.
- Alternative: nessuna rilevante.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-018 · Durata e ordine dei cadaveri
- Sezione GDD: §6.7, §12
- Ambiguità: da quando conta `CORPSE_TICKS`.
- Scelta: il cadavere nasce nella fase 6 con `ttl = CORPSE_TICKS`; nella fase 1 di ogni tick successivo `ttl` scende di 1 e a 0 il cadavere sparisce. Chi muore al tick t lascia un cadavere visibile dopo i tick da t a t + 399, cioè per 400 tick. I cadaveri restano ordinati per ID dell'unità anche se un ID minore muore dopo.
- Alternative: cadavere ancora presente al tick t + 400.
- Cambia l'esito di una battaglia: no (è la lettura diretta di "resta per `CORPSE_TICKS` tick"; la differenza di un tick nella finestra di rianimazione si verifica in M4 con T10–T11)
- Stato: confermata

### D-019 · Orientamento iniziale sulla cella della reliquia
- Sezione GDD: §6.5
- Ambiguità: un nemico al centro della reliquia non ha direzione "verso la reliquia".
- Scelta: se l'unità è esattamente sul centro della reliquia guarda a sud `(0,1)`, qualunque sia la fazione. Nessuno scenario mette nemici lì.
- Alternative: nessuna rilevante.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-020 · Prestazioni
- Sezione GDD: —
- Ambiguità: il percorso ricalcolato a ogni tick potrebbe essere lento nei batch.
- Scelta: ricalcolo a ogni tick, senza cache. Misura su `temple_01`: 6000 tick con 20 unità in circa 1,4 s. Se i batch di M6 saranno lenti, si aggiungerà una cache che dà gli stessi percorsi.
- Alternative: cache del percorso per destinazione.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-021 · Struttura della volontà
- Sezione GDD: §6.8
- Ambiguità: come si collega la volontà all'unità e al tick.
- Scelta: `SimWill` (`src/sim/wills/`) è la base comune, con un'istanza per unità creata dal nome in `UnitData.will`. Ha un punto di aggancio per ogni momento del tick: creazione dell'unità (`on_spawn`), fase 1 (`on_tick_start`), fase 2 (`accepts`), fase 3 (`idle_destination`, `allows_step`, `may_kite`, `allows_kite_step`), fase 4 (`on_attack_landed`). Il comportamento senza bersaglio del §6.6 passa dalla volontà: `HoldGroundWill` torna al punto di schieramento, `NecroBoundWill` va alla reliquia, `HungerWill` resta ferma finché M4 non porta il vagabondaggio. Il necromante si riconosce dal tipo `necromancer`.
- Alternative: volontà come campo enum di `SimUnit`; sottoclassi di `SimUnit` (vietate da `CLAUDE.md`).
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-022 · Dettagli letterali della volontà
- Sezione GDD: §6.8
- Ambiguità: punti in cui il testo si applica alla lettera e conviene fissarlo.
- Scelta:
  - "Necromante vivo" significa stato diverso da `DEAD`: un necromante con vita 0 influenza ancora fino alla fase 6 del tick (come previsto in T22).
  - Un'unità è "sotto influenza" in base alla posizione all'inizio del suo passo; il passo viene rifiutato per intero, non accorciato.
  - Per arretrare basta un nemico vivo entro `KITE_RADIUS`, anche senza vista.
  - Il passo all'indietro controlla solo la cella di arrivo: un passo diagonale molto vicino a uno spigolo può sfiorare due muri.
  - Per un senza mente, "già entro il proprio raggio d'attacco" si misura dalla posizione dell'unità a quella del nemico; per notarlo resta necessaria la vista (§6.4).
  - La fame scende anche per i ratti con IA spenta.
- Alternative: passo accorciato fino al bordo dell'influenza; arretramento solo da nemici in vista.
- Cambia l'esito di una battaglia: no (è il testo del §6.8 applicato alla lettera)
- Stato: confermata

### D-023 · Campi di stato fuori dallo `state_hash`
- Sezione GDD: §12; `.claude/rules/simulation.md`
- Ambiguità: la regola del progetto chiede di aggiungere all'hash ogni nuovo campo di stato, ma il §12 fissa il formato riga per riga. Non sono nell'hash: punto di schieramento e tick dell'ultimo calcolo del bersaglio (M3), morsi rimasti e timer di digestione del ratto (M3.1).
- Scelta: il formato resta quello del §12, fonte di verità. Il determinismo non cambia: ogni campo escluso dipende solo da input e seed. L'hash è solo meno sensibile a una divergenza che non tocca ancora vita, posizione o bersaglio, e che di norma si vede nei tick successivi.
- Alternative: aggiungere al §12 una riga per i campi di volontà (`will|id|…`), con modifica del GDD.
- Cambia l'esito di una battaglia: no
- Stato: superata da D-024 (umano, 7 ottobre 2026: l'hash deve contenere tutto ciò che determina il comportamento).

### D-024 · Lo `state_hash` come autodescrizione delle entità
- Sezione GDD: §12 (riscritto su richiesta dell'umano)
- Ambiguità: come garantire che ogni campo di stato, presente e futuro, entri nell'hash.
- Scelta: `SimState` (`src/sim/sim_state.gd`) è la base di `World`, `SimUnit`, `SimWill` e `SimCorpse`. `describe()` scrive tutte le variabili dello script nell'ordine di dichiarazione, con il nome, e scende nelle entità annidate e negli array. Un tipo che non sa scrivere è un errore (`push_error`, quindi gate rosso), mai un campo saltato. `World` esclude solo `rules`, `map`, `pathfinder` e `_pending_damage`. I valori sono scritti con `var_to_str`, quindi i float sono esatti. `test/test_state_hash_completeness.gd` cambia ogni campo di ogni tipo di entità e verifica che l'hash cambi; ho controllato che fallisca rompendo apposta la scrittura dei vettori. La descrizione è anche uno strumento di debug: se due simulazioni divergono, il confronto dei due testi mostra il campo.
- Alternative: elenco fisso di campi nel GDD (D-002, superata); ECS (escluso da `CLAUDE.md`, vedi Δ-01).
- Cambia l'esito di una battaglia: no
- Stato: confermata
