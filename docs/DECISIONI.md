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
- Stato: chiusa (umano, 7 ottobre 2026): rianimazione a catena a metà vita, dado della rianimabilità, scelta della vita maggiore (GDD §6.7, §8; D-031).

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

### D-025 · Cella di nascita dei ratti
- Sezione GDD: §7 (Riproduzione)
- Ambiguità: "cella calpestabile scelta con l'RNG entro 1 cella dal punto medio della coppia" non dice come si misura "entro 1 cella" né in che ordine si elencano le celle per l'RNG.
- Scelta: celle calpestabili il cui centro dista ≤ 1,0 dal punto medio, elencate per riga e poi per colonna; l'RNG sceglie con `randi_range(0, n − 1)`. Se il punto medio è il centro di una cella, le candidate sono quella cella e le 4 ortogonali. Se non c'è nessuna cella candidata, la coppia non genera.
- Alternative: le 9 celle del quadrato 3×3 intorno alla cella del punto medio.
- Cambia l'esito di una battaglia: sì (posizione dei neonati e uso dell'RNG)
- Stato: decisa dall'umano (7 ottobre 2026), diversa dalla scelta iniziale: quadrato 3×3 intorno alla cella del punto medio, solo celle libere (senza unità vive); se nessuna, gli anelli successivi. L'occupazione serve solo a distribuire le nascite, le unità restano senza collisioni (GDD §7, T31).

### D-026 · Tempi del vagabondaggio
- Sezione GDD: §7 (Vagabondaggio)
- Ambiguità: "ogni `WANDER_PERIOD_TICKS` tick (dal proprio ultimo spostamento casuale)" non dice quando avviene la prima scelta né quali celle sono candidate.
- Scelta: la prima scelta avviene appena il ratto è senza bersaglio, poi ogni 20 tick dalla scelta precedente, anche se il ratto non è ancora arrivato; il conteggio continua anche mentre il ratto ha un bersaglio. Le candidate sono le celle calpestabili il cui centro dista ≤ `WANDER_RADIUS` dalla posizione del ratto, compresa la sua cella, in ordine di riga e colonna; la destinazione è il centro della cella scelta.
- Alternative: prima scelta dopo 20 tick; esclusa la cella attuale.
- Cambia l'esito di una battaglia: sì (uso dell'RNG e movimento dei ratti)
- Stato: decisa dall'umano (7 ottobre 2026), diversa dalla scelta iniziale: vagabondaggio a sciame (GDD §7, `SWARM_RADIUS`, T33). La prima votazione avviene al tick 20, come ogni evento "ogni N tick" (§6.1), quindi i ratti appena schierati stanno fermi per 1 secondo.

### D-027 · Il ladro si sposta alle spalle anche quando è già a portata
- Sezione GDD: §7 (Ladro), §6.5
- Ambiguità: il ladro "si avvicina al punto 1 cella dietro al bersaglio", ma la regola comune dice che chi ha il bersaglio a portata e in vista non si muove.
- Scelta: con il punto alle spalle libero, il ladro va sempre verso quel punto, anche se il bersaglio è già a portata, e intanto attacca quando la ricarica è pronta. Arrivato, resta lì. Se il punto è un muro vale la regola comune: va diretto sul bersaglio e si ferma a portata. Senza questa lettura un ladro che arriva di fronte si fermerebbe a portata e non pugnalerebbe mai alle spalle.
- Alternative: regola comune, cioè fermo appena a portata (la pugnalata riesce solo se arriva già da dietro).
- Cambia l'esito di una battaglia: sì
- Stato: decisa dall'umano (7 ottobre 2026), diversa dalla scelta iniziale: prima si posiziona, poi colpisce; finché il punto alle spalle non è muro, il ladro attacca solo da dietro (GDD §7, T32). Vedi D-032 per un caso limite.

### D-028 · Unità nate in battaglia: orientamento, rianimazione di cadaveri nemici
- Sezione GDD: §6.5, §7, §8
- Ambiguità: il GDD dà l'orientamento iniziale solo per le unità schierate e non dice di chi sono i cadaveri che il necromante può rianimare.
- Scelta:
  - Neonati e rianimati ricevono l'orientamento iniziale della propria fazione: ratto neonato rivolto lontano dalla reliquia, rianimato rivolto verso la reliquia.
  - Il rianimato nasce con IA attiva, ricarica pronta, età 0 e punto di schieramento sul cadavere.
  - Il necromante può rianimare **qualunque** cadavere, anche di un'unità nemica (servo, non morto, revenant): il GDD dice "un cadavere".
- Alternative: orientamento del cadavere; solo cadaveri delle unità del giocatore.
- Cambia l'esito di una battaglia: sì (orientamento e quindi pugnalate; il necromante che rialza i propri servi)
- Stato: confermata (umano, 7 ottobre 2026): il necromante rianima qualunque cadavere; neonati e rianimati prendono l'orientamento iniziale della propria fazione.

### D-029 · Dettagli della fuga del goblin
- Sezione GDD: §7 (Goblin)
- Ambiguità: dettagli non scritti della fuga.
- Scelta:
  - Il controllo avviene nella fase 1, sulle posizioni correnti.
  - Entrando in `FLEE` l'unità perde il bersaglio; in fuga non sceglie bersagli, non arretra e non attacca, e corre alla reliquia lungo A*.
  - "Entro 1 cella dalla reliquia" vale ≤ 1,0 dal centro.
  - All'uscita lo stato torna `IDLE`.
  - "Goblin alleati" sono le unità vive dello stesso tipo e della stessa fazione: `PackCourageAbility` usa il tipo del proprietario, quindi vale per qualunque unità che la abbia.
  - Con IA spenta non fugge, perché "non cambia stato da sola"; il bonus di danno resta, come prevede la modalità di test.
- Alternative: nessuna rilevante.
- Cambia l'esito di una battaglia: no (è il testo applicato alla lettera)
- Stato: confermata

### D-030 · Modalità di test: neonati, eventi, varianti di unità
- Sezione GDD: —; `docs/TESTS.md`
- Ambiguità: come trattare i neonati di genitori con IA spenta (T08); dove stanno gli eventi.
- Scelta:
  - Un neonato eredita `ai_enabled` dal primo genitore. In partita l'IA è sempre attiva, quindi non cambia nessuna battaglia vera. Senza questa regola, in T08 il neonato vagabonda oltre `BREED_RADIUS` e la coppia non genera: sarebbero 5 ratti invece di 6.
  - Gli eventi del §11 (`death`, `reanimate`, `birth`, `flee_start`, `flee_end`) sono in `World.events`: sono solo uscita e restano fuori dallo `state_hash`.
  - Le statistiche dei test ora vengono da `data/units/`; le varianti si costruiscono nel test (`TestWorlds.without_ability`).
- Alternative: neonati sempre con IA attiva (T08 fallirebbe in modo casuale).
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-031 · Rianimazione a catena, dado della rianimabilità, dardo
- Sezione GDD: §6.7, §8, §9, §10 (riscritti su richiesta dell'umano, 7 ottobre 2026)
- Ambiguità: dettagli di implementazione delle nuove regole.
- Scelta:
  - Il dado si tira nella fase 6, alla morte, in ordine di ID, con l'RNG unico del mondo (`.claude/rules/simulation.md` vieta un secondo generatore). Se il cadavere si distrugge non si tira.
  - La probabilità usa la vita massima dell'unità morta, con K = `REANIMATE_K_BASE` (x = 0, Δ-13).
  - Il cadavere non rianimabile resta, con `reanimable = false`, per `CORPSE_TICKS`: serve alla vista (M5).
  - La regola del dardo si valuta nella fase 4 sui cadaveri esistenti in quel momento. Se un cadavere compare nella fase 6 dello stesso tick, il necromante può aver già tirato e rianimare nella fase 7: succede solo nel tick esatto in cui la ricarica è pronta e il primo cadavere compare.
  - Nei test la rianimazione si isola dal dado con una copia delle regole a K = 0 ("Dado neutralizzato" in `docs/TESTS.md`).
- Alternative: generatore separato per i cadaveri (Δ-14); dardo deciso nella fase 7, anticipando l'attacco.
- Cambia l'esito di una battaglia: no (le regole sono quelle chieste; qui ci sono solo i dettagli tecnici)
- Stato: confermata

### D-032 · Il ladro non raggiunge mai un bersaglio che cammina via
- Sezione GDD: §7 (Ladro), §6.2
- Ambiguità: il punto da raggiungere è esattamente 1 cella dietro il bersaglio, e la portata del ladro è esattamente 1. Se il bersaglio si allontana, il ladro (con ID più basso) arriva a 1,00 nella fase 3, poi il bersaglio si muove e nella fase 4 il ladro è a 1,075: fuori portata. Il ladro resta incollato alle spalle senza colpire, finché il bersaglio non esce dal suo raggio di inseguimento. Con un ID più alto del bersaglio il problema non c'è: l'esito dipende dall'ordine degli ID. Trovato con una sonda: contro un non morto senza mente che cammina verso la reliquia, 0 colpi in circa 100 tick.
- Scelta: nessuna modifica finché l'umano non decide.
- Alternative: (a) punto alle spalle a mezza cella invece di 1, con una costante `BACKSTAB_APPROACH` = 0,5: margine sufficiente anche contro il nemico più veloce, il servo a 0,15 celle per tick; (b) il ladro si ferma sul punto alle spalle solo se ci arriva entro la portata dopo il movimento di tutti (richiede di anticipare il movimento del bersaglio); (c) lasciare così.
- Cambia l'esito di una battaglia: sì
- Stato: decisa dall'umano (7 ottobre 2026) con una regola diversa dalle alternative: contro un bersaglio in movimento (stato `MOVE` o `FLEE`) il ladro gli va addosso e colpisce appena è a portata, anche di fronte, poi torna a riposizionarsi; contro un bersaglio fermo si posiziona prima alle spalle (GDD §7, T34). "In movimento" si legge dallo stato del bersaglio, cioè dal suo ultimo movimento: se il bersaglio ha un ID più alto, nella fase 3 il ladro vede lo stato del tick precedente.

### D-033 · Fine battaglia e scenario anticipati da M6 a M5
- Sezione GDD: §3, §9; `docs/MILESTONES.md` M5 e M6
- Ambiguità: il collaudo di M5 chiede "una partita completa", che richiede la fine della battaglia (§3) e le unità nemiche dello scenario (§9), pianificate per M6.
- Scelta: in M5 entrano la fase 8 (vittoria, annientamento, furto, tempo, timer della reliquia con l'evento `relic_timer_reset`), `ScenarioData` con `data/scenarios/temple_01.tres`, l'estrazione delle varianti (Blitz, poi Caccia, con l'RNG del mondo) e i test T12, T13, T15. Restano a M6 `tools/sim.sh` completo (validazione con codice 2, `by_variant`, JSON Lines, riepilogo del batch), T01 e il report di bilanciamento. Le regole non cambiano: cambia solo quando vengono implementate. T15 oggi usa `SimScenario.create_world`; in M6 va ricollegato all'API di `tools/sim.sh`, come chiede il suo livello "Simulazione".
- Alternative: chiudere M5 con un collaudo parziale, senza fine battaglia.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-034 · Dettagli dell'interfaccia e dello schieramento
- Sezione GDD: §2, §5.1, §11
- Ambiguità: dettagli che il GDD non fissa.
- Scelta:
  - La rivelazione è centrata sul centro della cella cliccata. Le quattro strategie di riferimento risultano valide con questa lettura in tutte le combinazioni (test `test_reference_strategies_are_valid`).
  - Gli indicatori di minaccia esistono solo nella nebbia: un indicatore sparisce quando la sua cella diventa visibile, per non coprire le unità.
  - Dopo la terza rivelazione lo schieramento parte da solo; si può passare allo schieramento anche prima, con "Fine ricognizione".
  - Lo schieramento accetta più unità sulla stessa cella (le unità non si bloccano, §6.3); il clic destro toglie l'ultima unità piazzata su quella cella e restituisce il costo.
  - "Via!" richiede almeno un'unità.
  - Il seed di una nuova partita viene dall'orologio ed è mostrato a schermo; "Rigioca" ripete lo stesso seed.
  - Il riepilogo divide le perdite per tipo e conta a parte i nemici rianimati uccisi.
- Alternative: rivelazione sull'angolo della cella; indicatori sempre visibili.
- Cambia l'esito di una battaglia: no (la rivelazione centrata è la lettura confermata dalle strategie; il resto è interfaccia)
- Stato: confermata

### D-035 · Dettagli di implementazione dell'ingombro, della pattuglia e della guardia
- Sezione GDD: §6.3, §6.6, §7, §8
- Ambiguità: dettagli tecnici delle regole di M5.1.
- Scelta:
  - Le celle occupate per i percorsi si fotografano all'inizio della fase 3, una volta per fazione (`World._occupied`, fuori dall'hash perché ricalcolato a ogni tick). Il blocco del passo usa invece le posizioni correnti, quindi chi ha un ID più basso prende la cella per primo.
  - Il passo tagliato si ferma a 0,001 dal bordo della cella nemica (margine di precisione), così la cella della posizione non cambia.
  - Il razziatore segna il bloccante in `SimUnit.blocker_id` (nell'hash). Il bloccante è accettato come bersaglio finché è vivo; quando il razziatore ritrova una via che aggira i nemici, il segno si azzera.
  - Il costo della guardia è arrotondato a 6 decimali prima di `ceil`, perché `1900 × 1,1` in virgola mobile vale `2090,0000000000002`.
  - Il rianimato in cella occupata cerca la prima cella libera ad anelli, in ordine di riga e colonna, senza RNG.
  - Il passo all'indietro (§6.8) che entrerebbe in una cella nemica si ferma al bordo, come ogni passo (§6.3). Una prima versione lo rifiutava per intero: corretta dopo la revisione, perché cambiava l'esito (l'arciere restava più vicino a chi lo minaccia).
  - Anche le unità in fuga senza bersaglio tirano la cella di pattuglia, come dice il §6.6 ("ogni unità senza bersaglio"): saltarle spostava la sequenza dell'RNG. La pattuglia non muove chi fugge, che continua a correre alla reliquia.
  - `SimScenario.create_world_with_variants` crea un mondo con una combinazione di varianti scelta, per strumenti e test.
  - `tools/screenshot.gd` accetta anche strategie fuori dal progetto (percorso assoluto) e rispetta `"guard"`.
- Alternative: occupazione ricalcolata dopo ogni passo anche per i percorsi (più costosa).
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-036 · T35 riscritto e T00 esteso senza goblin
- Sezione GDD: §6.3, §6.8; `docs/TESTS.md` T35
- Ambiguità: il T35 proposto prevedeva che un servo senza mente aggirasse un goblin isolato e lo superasse. Con portata 1 ogni giro intorno a un nemico passa nella cella accanto, a distanza 1, e il senza mente colpisce chi ha a portata (§6.8): si ferma a combattere. Il valore atteso era sbagliato, non la regola.
- Scelta: T35 usa un muro con due varchi. Il goblin tappa quello vicino e il servo passa dall'altro senza toccarlo: è il caso che il GDD descrive come "aggirare". Nel T00 esteso i goblin sono sostituiti da paladino e ladro: un goblin ferito fugge verso la reliquia, da lì fissa il nuovo punto di schieramento e finisce accanto all'ancora nemica. È un comportamento corretto, ma rendeva lo scenario di prova inadatto.
- Alternative: nessuna.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-037 · Danno dell'arciere da 8 a 12
- Sezione GDD: §7
- Ambiguità: nel collaudo l'arciere sembrava non fare danno. Misura: tirava alla cadenza massima, ma con 8 danni ogni 1,5 s aveva il peggior rapporto danno/costo dopo il paladino (17,8 DPS ogni 1000 monete).
- Scelta: decisione dell'umano. Prima danno 8 → 16; poi, sempre su sua indicazione, 16 → 12 (6 a bruciapelo). Valore in vigore: 12 in `data/units/archer.tres` e nella tabella del §7 (DPS 8, cioè 26,7 ogni 1000 monete). Aggiornati di conseguenza i valori attesi di T03 (68), T16 (6) e T23 (18, poi 6 al tick 30).
- Alternative: aspettare il report di bilanciamento di M6.
- Cambia l'esito di una battaglia: sì
- Stato: confermata (umano, 7 ottobre 2026)

### D-038 · Integrità: due interpretazioni da confermare
- Sezione GDD: §6.7, §8 (regole dell'umano del 7 ottobre 2026: integrità per unità, rianimazione con integrità ≥ 1, "rianimare toglie 1 punto integrità" al posto del dimezzamento, vita del rianimato "porzione × 25")
- Ambiguità: (1) se la vita del rianimato si calcola sull'integrità del cadavere prima o dopo il punto tolto; (2) con quale criterio il necromante sceglie fra i cadaveri, ora che la vita del rianimato dipende dall'integrità e non più dalla vita massima.
- Scelta: (1) vita = integrità del cadavere × `INTEGRITY_HP`, prima del punto tolto; il rianimato ha integrità − 1. Con l'altra lettura un goblin (integrità 1) si rialzerebbe con 0 di vita. (2) Il necromante sceglie il cadavere con l'integrità più alta, cioè quello che darà il rianimato con più vita, coerente con "scudi di carne".
- Alternative: (1) vita = (integrità − 1) × 25; (2) scegliere ancora per vita massima originale.
- Cambia l'esito di una battaglia: sì
- Stato: da confermare

### D-039 · Dettagli dello spazzino e delle guardie nella stanza
- Sezione GDD: §6.7, §6.8, §7, §4
- Ambiguità: dettagli tecnici delle nuove regole.
- Scelta:
  - Il ratto affamato sceglie il cadavere nella fase 1 (posizioni correnti) e mangia nella fase 7, dopo la rianimazione, se è entro 1 cella. Mangia qualunque cadavere, anche di un alleato.
  - La tana è salvata nella volontà del ratto (`HungerWill.den`) ed entra nell'hash. Lo sciame sazio accorcia la meta verso la tana e poi la taglia sui muri.
  - Le stanze sono rettangoli nello scenario. Oggi c'è solo `relic_room` (Cuore: x 31–40, y 10–18). Sulla mappa di test la stanza è x 17–22, y 3–8, lontana dall'ancora nemica: con y fino a 9 una guardia la uccideva e la battaglia finiva.
  - Una guardia sceglie la prima cella appena entra nella stanza (fase 3, in ordine di ID) e poi ai tick di pattuglia. Le celle già scelte da altre guardie sono escluse se c'è alternativa.
  - Il test T42 verifica che le guardie restino nella stanza con mete diverse, ma non distingue da solo la regola delle "celle già scelte": togliendola passa lo stesso, perché la preferenza per le celle senza alleati basta quasi sempre.
  - Correzioni dopo la revisione: il necromante ora sceglie davvero per integrità (il codice sceglieva ancora per vita massima e T27 non se ne accorgeva; T45 distingue i due criteri); un ratto che va a mangiare abbandona la meta dello sciame; un arciere guardia può arretrare ovunque dentro la stanza (il suo posto è la stanza, non il centro della reliquia).
  - `TestWorlds.run_until` e i cicli dei test si fermano a battaglia finita, e `tools/check.sh` dà 300 s al passo dei test: un ciclo su una battaglia già finita bloccava il gate.
- Alternative: nessuna rilevante.
- Cambia l'esito di una battaglia: no
- Stato: confermata

### D-040 · Chiusura di M5 e M5.1 con il collaudo
- Sezione GDD: §2, §14.5; `docs/MILESTONES.md` M5, M5.1
- Ambiguità: nessuna.
- Scelta: l'umano ha giocato una partita completa con il mouse (7 ottobre 2026). M5 e M5.1 sono chiuse. Impressione registrata per la domanda §14.5: "mi sembra strana ancora la vibe, ma magari è solo perché è incompleta". Da riconsiderare dopo il report di bilanciamento di M6 e quando l'interfaccia mostrerà di più (colpi, stati, Δ-15). Restano aperte le due interpretazioni di D-038.
- Alternative: nessuna.
- Cambia l'esito di una battaglia: no
- Stato: confermata
