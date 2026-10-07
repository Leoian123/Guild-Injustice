# Test di regola, Fase 1

Scritti dall'umano. Ogni voce è un test GdUnit4 con l'ID nel nome. Se un test contraddice il GDD, segnalalo e non adattare il codice.

## Livelli
- **Funzione**: si chiama direttamente la funzione della regola con dati costruiti nel test. Nessun `World`.
- **Mondo**: `World` minimo sulla mappa di test, avanzato tick per tick.
- **Simulazione**: scenario e strategia reali, con la stessa API di `tools/sim.sh`.

## Modalità di test (mondo)
- **Mappa di test**: 24×12, bordo di muri, interno tutto pavimento, reliquia in `(20,6)`. Le voci indicano eventuali muri aggiuntivi.
- **Posizioni**: "unità in `(x,y)`" significa al centro della cella, cioè `(x+0.5, y+0.5)`.
- **IA spenta** (`ai_enabled = false`): l'unità non sceglie bersagli, non si muove e non cambia stato da sola. Attacca solo `forced_target_id`, se impostato, a portata e in vista. Restano attive le abilità passive (corazza, coraggio, tiro ravvicinato) e quelle periodiche (riproduzione, rianimazione).
- **Interventi del test**: prima di un tick il test può impostare direttamente posizione, orientamento e vita di un'unità.
- **Dado neutralizzato**: dove la voce lo indica, il test usa una copia delle regole con `REANIMATE_K_BASE` = 0. Così ogni cadavere che non si distrugge è rianimabile con probabilità 1.
- **Ancore**: salvo indicazione contraria, ogni test di mondo crea per ultime due unità con IA spenta che impediscono la fine della battaglia: un `paladin` del giocatore in `(2,10)` e un `undead` nemico in `(21,10)`.
- "Dopo il tick N" significa dopo aver eseguito la fase 8 del tick N.

## Test

| ID | Livello | Regola | Situazione | Atteso |
|---|---|---|---|---|
| T00 | Mondo | Determinismo di base (§12) | Due `World` con seed 7 e le stesse unità (solo ancore). Un terzo con seed 8 | Dopo il tick 99: stesso `state_hash` per i primi due. `rng_state` del terzo diverso dai primi due |
| T01 | Simulazione | Determinismo completo | `s1_sciame_e_lame`, seed 42, eseguita due volte | Le due esecuzioni con seed 42 hanno lo stesso `state_hash` finale e lo stesso esito |
| T02 | Mondo | Danni simultanei (§6.2) | `goblin` in `(5,5)` e `servant` in `(6,5)`, IA spenta, vita 1, ciascuno con `forced_target_id` sull'altro. Senza ancore | Dopo il tick 0 entrambi sono `DEAD` |
| T03 | Mondo | Linea di vista e attacco (§5.2, §6.5) | Muri in `(8,4)` `(8,5)` `(8,6)`. `archer` con IA attiva in `(5,5)`, `undead` con IA spenta in `(11,5)` | Dopo il tick 39 l'undead ha 80 di vita. Prima del tick 40 il test sposta l'undead in `(8,1)`. Dopo il tick 40 l'undead ha 72 di vita |
| T04 | Funzione | Pugnalata alle spalle (§7) | Danno di `thief` in `(5,6)` contro `undead` in `(5,5)` orientato `(0,-1)` | 24 |
| T05 | Funzione | Pugnalata frontale | Come T04, con il ladro in `(5,4)` | 6 |
| T06 | Funzione | Corazza | Danno di `servant` contro `paladin`, nessun altro nemico vicino | 1 |
| T07 | Funzione | Paladino circondato | Come T06, con 4 `servant` entro 1,5 celle dal paladino nella fotografia | 5 |
| T08 | Mondo | Riproduzione (§7) | 2 `rat` con IA spenta in `(5,5)` e `(7,5)` | Dopo il tick 99: 2 ratti. Dopo il tick 100: 3. Dopo il tick 199: 3. Dopo il tick 200: 6 |
| T09 | Mondo | Tetto dei ratti | 6 `rat` con IA spenta in `(5,5)` `(6,5)` `(7,5)` `(5,6)` `(6,6)` `(7,6)` | Dopo il tick 100: 21. Dopo il tick 200: 24. Fino al tick 1000 mai più di 24 |
| T10 | Mondo | Rianimazione (§8) | Dado neutralizzato. `necromancer` con IA spenta in `(5,5)`, `rat` del giocatore con IA spenta in `(9,5)`. Prima del tick 0 il test porta a 0 la vita del ratto | Dopo il tick 0: esiste un'unità `rat` della fazione `ENEMY` con 10 di vita, ID maggiore di tutti gli altri, senza `BreedAbility`; il cadavere non c'è più |
| T11 | Mondo | Rianimazione a catena (§6.7, §8) | Seguito di T10: prima del tick 1 il test porta a 0 la vita del ratto rianimato | Dopo il tick 1 esiste il cadavere del ratto rianimato, rianimabile. Dopo il tick 119 c'è ancora. Dopo il tick 120 esiste un nuovo `rat` `ENEMY` con 5 di vita e non esistono cadaveri |
| T12 | Mondo | Reliquia contesa (§3) | `servant` con IA spenta in `(20,6)`, `goblin` con IA spenta in `(21,6)`, nessun bersaglio forzato | Dopo il tick 199 la battaglia non è finita e il timer è 0. Prima del tick 200 il test sposta il goblin in `(10,6)`. La battaglia finisce con `relic_stolen` al tick 299 |
| T13 | Mondo | Il timer si azzera | `servant` con IA spenta in `(20,6)`, `goblin` con IA spenta in `(10,6)`. Prima del tick 80 il test sposta il goblin in `(21,6)`, prima del tick 81 lo riporta in `(10,6)` | Dopo il tick 79 il timer vale 80. Dopo il tick 80 vale 0. La battaglia finisce con `relic_stolen` al tick 180 |
| T14 | Mondo | Fuga del goblin (§7) | `goblin` con IA attiva in `(5,5)` con 20 di vita, `servant` con IA spenta in `(7,5)` | Dopo il tick 0 il goblin è in `FLEE` ed è stato registrato `flee_start`. Fino al tick 19 il servo resta a 30 di vita e la distanza del goblin dalla reliquia diminuisce |
| T15 | Simulazione | Varianti (§9) | `temple_01` con i seed da 1 a 40, solo l'estrazione delle varianti | Compaiono tutte e 4 le combinazioni; lo stesso seed dà sempre la stessa combinazione |
| T16 | Funzione | Arrotondamenti (§6.1) | Danno di un `goblin` con 2 goblin alleati entro 3 celle. Danno di un `archer` con un nemico entro 1 cella | 9 e 4 |
| T17 | Funzione | Spigoli e vista (§5.2) | Vista dal centro di `(4,4)` al centro di `(5,5)`: prima senza muri, poi con un muro in `(5,4)` | Vero, poi falso |
| T18 | Funzione | Percorso (§6.3) | Costo del percorso A* su `temple_01` dalla cella `(8,33)` alla reliquia (ortogonale 1, diagonale √2) | 41,3 ± 0,1, senza celle muro e senza tagli d'angolo |
| T19 | Mondo | Coraggio (§6.8, `HoldGroundWill`) | `goblin` con IA attiva in `(5,5)`, `undead` con IA spenta in `(10,5)` | Dopo il tick 59 il bersaglio del goblin è l'undead. Prima del tick 60 il test sposta l'undead in `(13,5)`. Dopo il tick 60 il goblin non ha bersaglio e la sua distanza dal punto di schieramento è diminuita |
| T20 | Mondo | Fame (§6.8, `HungerWill`) | `rat` del giocatore con IA attiva in `(5,5)`, senza `WanderBehavior`; `undead` con IA spenta in `(6,5)` | Dopo il tick 32 l'undead ha 71 di vita e il ratto è sazio. Dopo il tick 33 il ratto non ha bersaglio. Dopo il tick 131 l'undead ha ancora 71. Dopo il tick 132 ha 68 |
| T21 | Mondo | Influenza del necromante (§6.8, `NecroBoundWill`) | `undead` con IA attiva in `(10,5)`, `goblin` con IA spenta in `(10,2)`, `necromancer` con IA spenta in `(8,5)` | Dopo il tick 0 il bersaglio dell'undead è il goblin. Dopo il tick 60 il goblin ha meno di 45 di vita |
| T22 | Mondo | Senza mente (§6.8) | Come T21, senza necromante. Variante: con il necromante, a cui il test porta la vita a 0 prima del tick 0 | Senza necromante: dopo ogni tick da 0 a 60 l'undead non ha bersaglio. Nella variante lo stesso vale dal tick 1, perché il necromante muore nella fase 6 del tick 0, come in T10. In entrambi i casi, dopo il tick 60 il goblin ha 45 di vita e l'undead è più vicino alla reliquia che all'inizio |
| T23 | Mondo | Kiting (§6.8) | `archer` con IA attiva in `(5,5)`, `servant` con IA spenta in `(6,6)` | Dopo il tick 0 il servo ha 22 di vita. Dopo il tick 7 la distanza fra i due è > 2,0 e l'arciere è orientato `(-0,7071, -0,7071)`. Dopo il tick 29 il servo ha ancora 22. Dopo il tick 30 ha 14 |
| T24 | Mondo | Guinzaglio dell'influenza (§6.8) | `necromancer` con IA spenta in `(5,5)`, `undead` con IA attiva in `(12,5)`, a 7 celle | Dopo il tick 100 la distanza dell'undead dal necromante è ≤ 8,0 e la sua posizione è uguale a quella dopo il tick 99 |
| T25 | Mondo | Senza mente e reliquia (§6.8, §3) | `servant` con IA attiva in `(18,6)`, senza necromante. `goblin` con IA spenta che il test mette nella posizione `(21.7, 6.5)`, a 1,2 celle dal centro della reliquia | Dopo il tick 0 il bersaglio del servo è il goblin. Dopo il tick 100 il goblin ha meno di 45 di vita |
| T26 | Mondo | Il necromante e il suo gruppo (§6.8) | `necromancer` con IA attiva in `(5,5)`, `goblin` con IA spenta in `(6,6)`, `undead` con IA spenta in `(5,8)`. Variante: senza undead | Dopo il tick 0 il goblin ha 35 di vita. Con l'undead: dopo il tick 10 il necromante è ancora al centro di `(5,5)`. Senza undead: dopo il tick 9 la distanza dal goblin è ≤ 2,0; dopo il tick 10 è > 2,0 e il necromante è orientato `(-0,7071, -0,7071)` |
| T27 | Mondo | Scudi di carne (§8) | Dado neutralizzato. `necromancer` con IA spenta in `(5,5)`; `rat` del giocatore con IA spenta in `(7,5)` e `goblin` con IA spenta in `(5,9)`. Prima del tick 0 il test porta a 0 la vita di entrambi | Dopo il tick 0 esiste un `goblin` `ENEMY` con 22 di vita; il cadavere del ratto c'è ancora |
| T28 | Mondo | Fine della catena (§6.7) | Dado neutralizzato. Come T10; dopo ogni rianimazione il test porta a 0 la vita del nuovo rianimato prima del tick successivo | I rianimati nascono ai tick 0, 120, 240 e 360 con 10, 5, 2 e 1 di vita. Dopo il tick 361 non esistono cadaveri. Dopo il tick 480 non è nata nessun'altra unità |
| T29 | Funzione e Mondo | Dado della rianimabilità (§6.7) | Probabilità di un'unità con vita massima 20, con `REANIMATE_K_BASE` = 1. Poi, nel mondo: come T10 ma con `REANIMATE_K_BASE` = 1 000 000 | 0,952 ± 0,001. Nel mondo: dopo il tick 0 esiste il cadavere del ratto, non rianimabile, e non esiste nessuna unità `ENEMY` di tipo `rat` |
| T30 | Mondo | Il dardo (§8) | Dado neutralizzato. `necromancer` con IA attiva in `(5,5)`; `goblin` con IA spenta in `(8,5)`; due `rat` del giocatore con IA spenta in `(5,9)` e `(5,10)`. Prima del tick 0 il test porta a 0 la vita dei due ratti; prima del tick 1 porta a 0 la vita del ratto rianimato. Al tick 120 sono pronti sia il dardo sia la rianimazione | Dopo il tick 0 il goblin ha 35 di vita. Dopo il tick 119 ha 15. Dopo il tick 120 ha ancora 15 ed esiste un nuovo `rat` `ENEMY` con 10 di vita. Dopo il tick 121 il goblin ha 5 |
