# Proposta M5.1 — Ingombro, pattuglia, guardia

Stato: **da approvare**. Quando l'umano la approva, i testi delle sezioni A–D entrano in `GDD_fase1.md`, `TESTS.md`, `data/` e `CLAUDE.md`, e questo file si cancella.

Origine: collaudo di M5 (7 ottobre 2026). Le unità si attraversano (GDD §6.3), quindi nessuno può sbarrare niente: il Blitz corre alla reliquia e ci resta. L'umano chiede che alleati e nemici non si sovrappongano, che chi attacca e chi difende si comportino in modo diverso davanti a un ostacolo, che i difensori pattuglino invece di restare fermi, e una guardia della reliquia a pagamento. Chiude Δ-08.

I numeri marcati con **(?)** sono valori iniziali proposti.

---

## A. Testo per il GDD

### §6.3 Movimento (sostituisce "Nessuna collisione tra unità: possono sovrapporsi")
- **Ingombro.** Ogni unità viva occupa la cella che contiene la sua posizione. Un'unità non può entrare in una cella occupata da un'unità **nemica** viva: il passo si ferma al bordo di quella cella. **Fra alleati non c'è ingombro**: si attraversano e possono stare nella stessa cella.
- **Percorso.** A* considera come ostacoli, oltre ai muri, le celle occupate da nemici all'inizio della fase 3, salvo la cella di destinazione. Così chi si muove aggira i nemici che trova sulla strada. Se un percorso così non esiste, l'unità usa il percorso che ignora le unità e si ferma al primo nemico che la blocca.
- **Razziatori.** Un'unità che senza bersaglio marcia verso la reliquia (oggi: ogni unità con `NecroBoundWill`) evita la mischia: cerca sempre prima il percorso che aggira i nemici. Se non esiste, sceglie come bersaglio il primo nemico che le sbarra il percorso, anche se la sua volontà non lo accetterebbe, e se lo apre combattendo.
- **Difensori.** Le unità che tengono una posizione si mettono in mezzo e attaccano chi notano, come prima (§6.4, §6.8).

### §6.6 Comportamento senza bersaglio (aggiornato)
- **Unità con `HoldGroundWill`: pattuglia.** Ai tick multipli di `PATROL_PERIOD_TICKS` ogni unità senza bersaglio sceglie con l'RNG, in ordine di ID, una cella calpestabile senza nemici il cui centro dista ≤ `PATROL_RADIUS` dal suo punto di schieramento, preferendo le celle senza alleati, e ci va. Prima della prima scelta, e dopo un combattimento, torna al punto di schieramento.
- Ratti e unità nemiche come prima.
- La pattuglia è **tarabile**: oggi i valori sono costanti di regola; più avanti la taratura apparterrà alle entità grigie (Δ-18).

### §2 e §7 Guardia della reliquia (nuova opzione di schieramento)
- Allo schieramento il giocatore può comprare un'unità **razionale** come **guardia**, pagando `ceil(costo × (1 + GUARD_COST_RATIO))`.
- "La reliquia è più importante della tua vita": la guardia
  - ha come punto di schieramento il **centro della reliquia**: ovunque la si schieri, il suo compito è tornarci, esplorando la mappa lungo la strada;
  - **non insegue**: accetta come bersaglio solo i nemici già entro il proprio raggio d'attacco;
  - **non fugge mai**;
  - pattuglia entro `GUARD_PATROL_RADIUS` dalla reliquia.
- **Razionale** è un dato dell'unità (`rational`). Solo le unità razionali possono ricevere ordini; la guardia è il primo e, in Fase 1, l'unico. Più avanti le entità grigie e i potenziamenti daranno ordini anche alle unità non razionali (Δ-17, Δ-19).

### §7 e §8 Nuova colonna "Razionale"
| Unità | Razionale |
|---|---|
| `rat` | no |
| `goblin` `archer` `thief` `paladin` | sì |
| `servant` `undead` `revenant` | no |
| `necromancer` | sì |

### §8 Rianimazione (aggiunta)
- Se la cella del cadavere è occupata da un nemico del rianimato, il rianimato nasce nella prima cella senza nemici: si cerca in anelli via via più ampi, in ordine di riga e colonna, senza RNG.

### §9 Casualità (aggiunta)
- Anche la scelta della cella di pattuglia usa l'RNG.

### §10 Costanti nuove
- `PATROL_PERIOD_TICKS` = 60 **(?)** (3 s), `PATROL_RADIUS` = 2,0 **(?)**, `GUARD_PATROL_RADIUS` = 1,0 **(?)**, `GUARD_COST_RATIO` = 0,10.

### §11 Strategie
- Ogni unità della strategia può avere `"guard": true`. La validazione verifica che le guardie siano razionali e conta il loro sovrapprezzo nel budget.

### Schieramento (§2)
- Più unità alleate possono stare nella stessa cella; nessuna unità del giocatore può essere schierata in una cella con un nemico visibile.

---

## B. Nuovi test per `docs/TESTS.md`

| ID | Livello | Regola | Situazione | Atteso |
|---|---|---|---|---|
| T35 | Mondo | Ingombro (§6.3) | `servant` con IA attiva in `(5,5)`, senza necromante (marcia verso la reliquia); `goblin` con IA spenta in `(10,5)` | Fino al tick 100 il servo non è mai nella cella del goblin. Dopo il tick 100 il servo ha x > 11 |
| T36 | Mondo | Razziatore senza altra via (§6.3) | Muri nella colonna x = 10, da y = 1 a y = 10, tranne `(10,5)`; `servant` con IA attiva in `(5,5)`, senza necromante; `goblin` con IA spenta in `(10,5)`, nel varco | Fino al tick 60 il servo non è mai nella cella del goblin. Dopo il tick 60 il bersaglio del servo è il goblin e il goblin ha meno di 45 di vita |
| T37 | Mondo | Alleati senza ingombro (§6.3) | `goblin` con IA attiva in `(5,5)`; `goblin` con IA spenta in `(7,5)`; `undead` con IA spenta in `(9,5)` | Entro il tick 30 il primo goblin si trova almeno una volta nella cella `(7,5)` |
| T38 | Mondo | Pattuglia (§6.6) | `goblin` con IA attiva in `(5,5)`, nessun nemico entro il suo raggio d'ingaggio | Dopo il tick 59 il goblin è nel punto di schieramento. Entro il tick 119 se ne è allontanato almeno una volta. Fino al tick 600 non è mai a più di `PATROL_RADIUS` + 1 dal punto di schieramento |
| T39 | Mondo | Guardia (§7) | `goblin` **guardia** con IA attiva in `(5,5)`, con 20 di vita; `servant` con IA spenta in `(5,8)` | Fino al tick 200 il goblin non entra mai in `FLEE` e il servo ha 30 di vita. Dopo il tick 200 il goblin è più vicino alla reliquia che all'inizio |
| T40 | Funzione | Costo della guardia (§7) | Costo di un `rat` e di un `paladin` guardia; validità di un `rat` guardia | 174 e 2090; il `rat` guardia non è valido (non razionale) |
| T41 | Mondo | Rianimato in cella occupata (§8) | Dado neutralizzato. `necromancer` con IA spenta in `(5,5)`; `rat` con IA spenta in `(8,5)` e `goblin` con IA spenta in `(8,5)`, entrambi del giocatore. Prima del tick 0 il test porta a 0 la vita del ratto | Dopo il tick 0 esiste un `rat` `ENEMY` in una cella a distanza di Chebyshev 1 da `(8,5)`, diversa da quella del goblin |

---

## C. Dati
- `data/rules.tres`: le costanti del §10.
- `data/units/*.tres`: campo `rational`.

## D. `CLAUDE.md`
Nessun nuovo identificatore canonico: "guardia" è un'opzione di schieramento, non un componente.

---

## Effetti attesi sul gioco
- **Sbarramento vero.** Un muro di ratti in un varco costringe il Blitz ad aggirarlo o, se non c'è altra via, a masticarlo.
- **Varchi e strettoie contano.** Il Cuore ha tre accessi (sala sud, corridoio est, santuario chiuso): tapparli diventa una strategia.
- **Mischia più lenta.** Con portata 1 colpiscono solo i vicini di lato (4 posti intorno a un bersaglio). I muri reggono di più.
- **Difensori vivi.** La pattuglia sparge le unità nella zona invece di ammucchiarle.
- **Guardie a pagamento.** Un tappo che non scappa e non si lascia attirare fuori, per il 10% in più.
- **Prestazioni.** Due griglie A* (una per fazione) aggiornate a ogni tick: costo contenuto; si misura in M6 (Δ-02).
