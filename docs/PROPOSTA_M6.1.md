# Proposta M6.1 — Corpi solidi e catena alimentare

Stato: **da approvare**. Quando l'umano la approva, i testi delle sezioni A–D entrano in `GDD_fase1.md`, `TESTS.md`, `data/` e `CLAUDE.md`, e questo file si cancella.

Origine: richieste dell'umano dell'8 ottobre 2026, dopo M5.
1. **Corpi solidi per tutti**, alleati compresi, ma come caratteristica opzionale: in futuro spettri o potenziamenti come lo "scatto fasico" renderanno attraversabili certe unità o tutte.
2. **Catena alimentare.** Il ratto diventa uno sciame da nutrire: il suo danno cresce con lo sciame e si riproduce solo se sazio. Il coniglio è una preda: cibo per i ratti e carne per il necromante. Visione: "se vuoi lo sciame infinito di ratti devi bilanciare nutrimento e sovrappopolazione".

Il report di bilanciamento di M6 si esegue dopo M6.1.

---

## A. Testo per il GDD

### §6.3 Movimento: ingombro (sostituisce i punti Ingombro, Percorso, Razziatori)
- **Corpi solidi.** Ogni unità ha il dato `solid` (vero per default). Un'unità solida viva occupa la cella che contiene la sua posizione. Un'unità solida non può entrare in una cella occupata da un'altra unità solida viva, **di qualunque fazione**: il passo si ferma al bordo di quella cella. Un'unità non solida attraversa tutte le celle e non blocca nessuno.
- **Interruttore.** La costante `BODY_BLOCKING` (vero) accende l'ingombro; se è falsa nessuno blocca nessuno.
- **Percorso.** A* considera come ostacoli, oltre ai muri, le celle occupate da unità solide all'inizio della fase 3, salvo la cella di partenza e quella di destinazione. Se un percorso così non esiste, l'unità usa il percorso che ignora le unità.
- **Bloccato da un nemico.** Come prima: chi usa il percorso che ignora le unità si ferma al primo nemico. Un razziatore accetta come bersaglio il primo nemico che gli sbarra la strada.
- **Bloccato da un alleato: scambio.** Se un'unità che usa il percorso che ignora le unità sta per entrare nella cella di un alleato solido, i due **si scambiano di posto**: ognuno prende la posizione dell'altro, nello stesso tick. Lo scambio avviene al massimo una volta per unità per tick, e solo se l'alleato non si è già mosso o scambiato in quel tick.
- **Schieramento.** Al massimo un'unità solida per cella.

### §6.5 Attacco (aggiunta)
- Un'unità con danno 0 non attacca.
- Un rianimato attacca sempre, con danno mai inferiore a 1.

### §6.8 e §7 Ratto (sostituisce costo, danno, riproduzione, fame)
- Costo **100**.
- **Danno = numero di ratti vivi del suo sciame, lui compreso**, contati nella fotografia: ratti del giocatore collegati a catena entro `SWARM_RADIUS`. Da solo fa 1, in uno sciame di 10 fa 10. I moltiplicatori e le riduzioni del §6.1 si applicano dopo, come per tutti.
- **Riproduzione solo da sazi**: una coppia è idonea se entrambi i ratti sono sazi (oltre a vivi e con l'età minima).
- **Tetto** `RAT_CAP` = 50.
- **Fame, ordine delle prede del ratto affamato:**
  1. un **cadavere** con integrità ≥ 1 entro il raggio d'ingaggio e in vista (come oggi);
  2. un **invasore della tana**: un nemico notato entro `SWARM_LEASH_RADIUS` dalla tana;
  3. la **preda più facile**: fra i nemici e i **conigli** notati, quello con meno vita; a parità il più vicino, poi l'ID più basso.
- I ratti affamati cacciano anche i conigli vivi, pur essendo alleati.

### §7 Coniglio (nuova unità)
| Unità | ID | Costo | Vita | Danno | Int. att. | Raggio att. | Tipo att. | Vel. | Ingaggio | Insegue | Razionale | Integrità | Volontà | Abilità |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Coniglio | `rabbit` | 100 | 5 | 0 | 1,0 s | 1 | `melee` | 3,5 | 0 | — | no | 1 | `PreyWill` | `WanderBehavior`, `BreedAbility` |

- **`PreyWill`**: non accetta mai bersagli; senza bersaglio vaga a sciame legato alla sua tana, come un ratto sazio.
- Gli sciami si formano solo fra unità dello **stesso tipo**: i conigli con i conigli, i ratti con i ratti.
- **Riproduzione** a coppie, come i ratti, ai tick multipli di `BREED_PERIOD_TICKS` (5 s), con tetto `RABBIT_CAP` = 100.
- È **cibo** per i ratti (integrità 1, un morso) e **carne** per il necromante (rialzato con 25 di vita e danno 1).
- **Conta come unità del giocatore** per l'annientamento (§3) e per la contesa della reliquia.

### §10 Costanti nuove o cambiate
- `BODY_BLOCKING` = vero, `RAT_CAP` = 50, `RABBIT_CAP` = 100.

### §11 e schieramento
- Validazione: al massimo un'unità solida per cella.

---

## B. Test

### Nuovi
| ID | Livello | Regola | Situazione | Atteso |
|---|---|---|---|---|
| T46 | Mondo | Alleati solidi (§6.3) | `goblin` con IA attiva in `(5,5)`; `goblin` con IA spenta in `(7,5)`; `undead` con IA spenta in `(9,5)` | Fino al tick 60 il primo goblin non entra mai nella cella `(7,5)`; dopo il tick 60 l'undead ha meno di 80 di vita |
| T47 | Mondo | Scambio fra alleati (§6.3) | Muri nelle righe y = 4 e y = 6 da x = 3 a x = 12 (corridoio largo 1). `goblin` A schierato in `(11,5)`, `goblin` B schierato in `(4,5)`, IA attiva. Prima del tick 0 il test mette A in `(4,5)` e B in `(11,5)` | Dopo il tick 200 entrambi sono entro 0,5 dal proprio punto di schieramento |
| T48 | Mondo | Unità non solide (§6.3) | Come T36, ma il servo ha `solid` = falso | Fino al tick 60 il goblin ha 45 di vita; il servo passa nella cella del goblin almeno una volta e dopo il tick 100 ha x > 11 |
| T49 | Funzione | Danno dello sciame (§7) | Danno di un `rat` da solo; danno di un `rat` con altri 2 ratti a catena (distanze 2 e 2) contro un `undead` | 1 e 3 |
| T50 | Mondo | Riproduzione solo da sazi (§7) | Copia delle regole con `RAT_DIGEST_TICKS` = 50. 2 `rat` con IA spenta in `(5,5)` e `(7,5)` | Dopo il tick 100 ci sono ancora 2 ratti |
| T51 | Mondo | Conigli (§7) | 2 `rabbit` con IA spenta in `(5,5)` e `(7,5)`; `undead` con IA spenta in `(6,6)` | Dopo il tick 100 ci sono 3 conigli; dopo il tick 200 l'undead ha ancora 80 di vita |
| T52 | Mondo | Il ratto caccia il coniglio (§7) | Copia delle regole con `RAT_DIGEST_TICKS` = 10. `rat` del giocatore con IA attiva in `(5,5)`, senza `WanderBehavior`; `rabbit` con IA spenta in `(7,5)` | Entro il tick 100 il coniglio è morto e il suo cadavere è stato mangiato (nessun cadavere) |
| T53 | Mondo | Invasore della tana (§7) | Copia delle regole con `RAT_DIGEST_TICKS` = 10. `rat` con IA attiva in `(5,5)`, senza `WanderBehavior`; `servant` con IA spenta in `(7,5)` (entro la tana); `rabbit` con IA spenta in `(5,8)` | Dopo il tick 20 il bersaglio del ratto è il servo |
| T54 | Mondo | Coniglio rianimato (§6.5) | Dado neutralizzato. `necromancer` con IA spenta in `(5,5)`; `rabbit` con IA spenta in `(7,5)`. Prima del tick 0 il test porta a 0 la vita del coniglio | Dopo il tick 0 esiste un `rabbit` `ENEMY` con 25 di vita e danno 1 |

### Da rivedere per le nuove regole
- **T08 e T09**: i ratti si riproducono solo da sazi (nascono sazi per 200 tick) e il tetto passa a 50. T08: dopo il tick 200 restano **3** ratti, perché i genitori hanno fame e il neonato da solo non fa coppia. T09: dopo il tick 100 sono 21; dopo il tick 200 sono **50**, perché si accoppiano i 15 neonati ancora sazi, fino al tetto; fino al tick 1000 mai più di 50.
- **T37** (alleati che si attraversano) è sostituito da T46.
- **T31** e **T41** mettono più unità nella stessa cella: restano validi come situazioni di partenza (il test le crea direttamente), ma i valori attesi vanno ricontrollati con l'ingombro fra alleati.

## C. Dati
- `data/rules.tres`: `body_blocking`, `rat_cap` = 50, `rabbit_cap` = 100.
- `data/units/rat.tres`: costo 100. `data/units/rabbit.tres`: nuovo. Campo `solid` in `UnitData`, vero per default.
- `data/scenarios/temple_01.tres`: `rabbit` fra le unità acquistabili.

## D. `CLAUDE.md`, identificatori canonici
- Unità: aggiungere `rabbit`.
- Volontà: aggiungere `PreyWill`.

---

## Effetti attesi sul gioco
- **Ingorghi e formazioni.** Con gli alleati solidi le formazioni contano davvero: un varco tappato da alleati è chiuso anche per i tuoi, salvo scambio.
- **Ratti economici ma affamati.** Uno sciame grande morde forte, ma per restare grande deve mangiare: senza cadaveri o conigli smette di riprodursi.
- **Conigli: nutrimento e rischio.** Una conigliera nutre i ratti, ma è anche carne per il necromante.
- **Tappo economico.** Un coniglio costa 100 e conta per la contesa della reliquia: un branco di conigli sulla reliquia può fermare un furto. Va osservato nel report.
- **Prestazioni.** Fino a 150 unità del giocatore (50 ratti e 100 conigli), oltre la soglia di Δ-01 (~200 unità con i nemici). Si misura subito dopo l'implementazione.
