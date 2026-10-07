# Proposta M3.1 — Volontà di combattere

Stato: **da approvare**. Quando l'umano la approva, i testi delle sezioni A–D entrano in `GDD_fase1.md`, `TESTS.md`, `data/` e `CLAUDE.md`, e questo file si cancella.

Origine: risposte dell'umano a D-014 e D-015 (6–7 ottobre 2026), più due correzioni dalla revisione dell'umano (guinzaglio dell'influenza, contesa della reliquia). Nella versione finale il gioco deve simulare la "voglia" di combattere delle unità, in stile Darkest Dungeon e Mordheim. Il limite di inseguimento uguale per tutti è sostituito da un sistema unico, la **volontà**, con una causa diversa per ogni tipo di unità. La Fase 1 ne implementa la forma più semplice. Il sistema completo di paura e disciplina resta fuori perimetro, ma ogni nuova causa si aggiungerà come nuovo componente.

I numeri marcati con **(?)** sono valori iniziali proposti: l'umano li conferma o li cambia.

---

## A. Testo per il GDD

### §6.6 Comportamento senza bersaglio (sostituisce il testo attuale)
- **Unità del giocatore** (tranne i ratti): tornano al punto di schieramento e lo tengono.
- **Ratti**: vagano (§7).
- **Unità nemiche**: avanzano verso la reliquia.
- Quali bersagli un'unità accetta di inseguire lo decide la sua volontà (§6.8).

### §6.8 Volontà di combattere (nuova)
Ogni unità ha esattamente un componente di volontà. La volontà decide quali nemici notati (§6.4) l'unità accetta come bersaglio. Un bersaglio che la volontà non accetta più viene abbandonato subito, come uno non più notato. La scelta fra i bersagli accettati segue la regola comune del §6.4.

| Componente | Unità | Bersagli accettati |
|---|---|---|
| `HoldGroundWill` | `goblin` `archer` `thief` `paladin` | Nemici con `distanza(punto di schieramento, nemico) ≤ chase_radius + raggio d'attacco`, in linea d'aria. `chase_radius` è una statistica dell'unità (§7): il suo coraggio. |
| `HungerWill` | `rat` del giocatore | Da affamato: qualunque nemico notato, senza limite. Da sazio: nessuno. |
| `NecroBoundWill` | `servant` `undead` `revenant` `necromancer` e ogni rianimato | Entro `NECRO_INFLUENCE_RADIUS` da un `necromancer` vivo: qualunque nemico notato, senza limite (caccia). Fuori: solo i nemici già entro il proprio raggio d'attacco e quelli che contendono la reliquia, cioè entro `RELIC_CONTEST_RADIUS` dal suo centro (senza mente: non deviano, salvo per difendere il furto). |

**Fame del ratto.** Ogni ratto parte affamato con `RAT_HUNGER_BITES` morsi. Ogni attacco messo a segno toglie un morso. Al morso che porta il conto a 0 il ratto diventa sazio per `RAT_DIGEST_TICKS` tick. Il timer scende nella fase 1; quando arriva a 0, nella stessa fase il ratto torna affamato con `RAT_HUNGER_BITES` morsi. Da sazio non ha bersaglio e vaga. Un ratto rianimato non ha fame: ha `NecroBoundWill`.

**Influenza del necromante.** La distanza si misura dalla posizione dell'unità a quella del necromante vivo più vicino, senza bisogno di vista. Il necromante è sempre entro la propria influenza. Se tutti i necromanti muoiono, i non morti restano senza mente fino alla fine della battaglia. Con la volontà `FearlessTrait` non cambia: i non morti non fuggono mai.

**Guinzaglio dell'influenza.** Nella fase 3 un'unità sotto influenza non fa un passo che la porterebbe oltre `NECRO_INFLUENCE_RADIUS` dal necromante vivo più vicino: se succederebbe, resta ferma in quel tick, mantenendo bersaglio e orientamento. Le unità si processano per ID crescente e il necromante ha un ID più basso dei suoi non morti, quindi si muove prima e i suoi non morti si regolano sulla sua nuova posizione. Il gruppo avanza compatto alla velocità del necromante. Il guinzaglio non trattiene chi è già fuori dall'influenza: resta senza mente finché non rientra nel raggio per conto suo.

**Corpo a corpo e distanza (kiting).** Vale per tutte le unità, secondo il tipo di attacco:
- **Corpo a corpo** (raggio d'attacco ≤ 1): ingaggia, cioè si avvicina al bersaglio finché è a portata e in vista (§6.3, §6.5).
- **A distanza** (raggio d'attacco > 1): nella fase 3, se la ricarica dell'attacco è > 0 e c'è un nemico vivo entro `KITE_RADIUS`, l'unità arretra invece di muoversi altrimenti. Si sposta in linea retta, alla propria velocità, in direzione opposta al nemico vivo più vicino; a parità di distanza conta l'ID più basso. Il passo si annulla, e l'unità resta ferma, se la nuova posizione cade in una cella muro oppure, per un'unità con `HoldGroundWill`, se la porta oltre `chase_radius` dal punto di schieramento. Arretrando, l'orientamento diventa la direzione del movimento, quindi l'unità volta le spalle al nemico (§7, ladro).

### §7 Unità del giocatore: nuova colonna `Insegue` (`chase_radius`, celle)
| Unità | `chase_radius` |
|---|---|
| `goblin` | 6 (era `LEASH_RADIUS`) **(?)** |
| `archer` | 4 **(?)** (tira fino a 4 + 6 = 10 celle dal suo posto) |
| `thief` | 8 **(?)** (cacciatore di isolati) |
| `paladin` | 5 **(?)** (guardiano lento) |
| `rat` | — (ha `HungerWill`) |

Nel testo del Ratto, "ignorano il limite di inseguimento" diventa "inseguono finché hanno fame (§6.8)".

### §8 Fazione nemica
- Ogni unità nemica ha `NecroBoundWill`, compresi i rianimati: la volontà non è un'abilità, quindi il rianimato non la perde.
- Nel testo del rianimato, "Si comporta come un'unità nemica: avanza verso la reliquia" resta invariato.

### §10 Costanti
- Tolta: `LEASH_RADIUS`.
- Nuove: `RAT_HUNGER_BITES` = 3 **(?)**, `RAT_DIGEST_TICKS` = 100 **(?)** (5 s), `NECRO_INFLUENCE_RADIUS` = 8,0 **(?)**, `KITE_RADIUS` = 2,0 **(?)** (appena oltre il tiro ravvicinato).

### §13 Fuori perimetro
"Sistema completo di paura/disciplina/avidità (qui solo codardia dei goblin, ratti incontrollati **e la volontà del §6.8**)".

---

## B. Nuovi test per `docs/TESTS.md`

Valori calcolati con le regole sopra e le statistiche del §7–§8. Da M4 l'arciere avrà `PointBlankPenalty`: T23 è costruito apposta senza nemici entro 1 cella.

| ID | Livello | Regola | Situazione | Atteso |
|---|---|---|---|---|
| T19 | Mondo | Coraggio (§6.8, `HoldGroundWill`) | `goblin` con IA attiva in `(5,5)`, `undead` con IA spenta in `(10,5)` | Dopo il tick 59 il bersaglio del goblin è l'undead. Prima del tick 60 il test sposta l'undead in `(13,5)`. Dopo il tick 60 il goblin non ha bersaglio e la sua distanza dal punto di schieramento è diminuita |
| T20 | Mondo | Fame (§6.8, `HungerWill`) | `rat` del giocatore con IA attiva in `(5,5)`, senza `WanderBehavior`; `undead` con IA spenta in `(6,5)` | Dopo il tick 32 l'undead ha 71 di vita e il ratto è sazio. Dopo il tick 33 il ratto non ha bersaglio. Dopo il tick 131 l'undead ha ancora 71. Dopo il tick 132 ha 68 |
| T21 | Mondo | Influenza del necromante (§6.8, `NecroBoundWill`) | `undead` con IA attiva in `(10,5)`, `goblin` con IA spenta in `(10,2)`, `necromancer` con IA spenta in `(8,5)` | Dopo il tick 0 il bersaglio dell'undead è il goblin. Dopo il tick 60 il goblin ha meno di 45 di vita |
| T22 | Mondo | Senza mente (§6.8) | Come T21, senza necromante. Variante: con il necromante, a cui il test porta la vita a 0 prima del tick 0 | Senza necromante: dopo ogni tick da 0 a 60 l'undead non ha bersaglio. Nella variante lo stesso vale dal tick 1, perché il necromante muore nella fase 6 del tick 0, come in T10. In entrambi i casi, dopo il tick 60 il goblin ha 45 di vita e l'undead è più vicino alla reliquia che all'inizio |
| T23 | Mondo | Kiting (§6.8) | `archer` con IA attiva in `(5,5)`, `servant` con IA spenta in `(6,6)` | Dopo il tick 0 il servo ha 22 di vita. Dopo il tick 7 la distanza fra i due è > 2,0 e l'arciere è orientato `(-0,7071, -0,7071)`. Dopo il tick 29 il servo ha ancora 22. Dopo il tick 30 ha 14 |
| T24 | Mondo | Guinzaglio dell'influenza (§6.8) | `necromancer` con IA spenta in `(5,5)`, `undead` con IA attiva in `(12,5)`, a 7 celle | Dopo il tick 100 la distanza dell'undead dal necromante è ≤ 8,0 e la sua posizione è uguale a quella dopo il tick 99 |
| T25 | Mondo | Senza mente e reliquia (§6.8, §3) | `servant` con IA attiva in `(18,6)`, senza necromante. `goblin` con IA spenta che il test mette nella posizione `(21.7, 6.5)`, a 1,2 celle dal centro della reliquia | Dopo il tick 0 il bersaglio del servo è il goblin. Dopo il tick 100 il goblin ha meno di 45 di vita |

---

## C. Dati
- `data/rules.tres`: le costanti del §10 come sopra.
- `UnitData`: nuovo campo `chase_radius`. In M3.1 vive nelle statistiche dei test; in M4 entra in `data/units/`.

## D. `CLAUDE.md`, identificatori canonici
Aggiungere la riga "Volontà: `HoldGroundWill` `HungerWill` `NecroBoundWill`."

---

## Effetti attesi sul gioco
- **Blitz:** revenant e servi non hanno un necromante vicino, quindi sono senza mente e corrono alla reliquia colpendo solo ciò che hanno davanti o chi contende la reliquia. Le unità non si bloccano a vicenda, quindi "sbarrare" significa piazzarsi esattamente sul loro percorso: va osservato nel collaudo di M5, perché al giocatore potrebbe sembrare arbitrario.
- **Caccia:** il gruppo avanza compatto alla velocità del necromante e caccia per tutta la battaglia. Uccidere il necromante spegne l'intero gruppo dove si trova: un premio per l'imboscata (si collega a D-000).
- **Necromante:** è un'unità a distanza (raggio 5), quindi arretra dai nemici vicini voltando le spalle e diventa più esposto alla pugnalata. È la conseguenza diretta della regola "le unità a distanza arretrano"; per escluderlo serve una scelta esplicita dell'umano.
- **Ratti:** mordono tre volte e poi si allontanano; sono un'arma a raffica, non un muro.
- **Arcieri:** arretrano e voltano le spalle, quindi il ladro rianimato o un servo veloce li puniscono.
