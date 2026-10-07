# Gilda Grigia — Regole di gioco, Fase 1 (v3)

Fonte di verità delle regole. Milestone in `MILESTONES.md`, test in `TESTS.md`. I valori numerici sono quelli iniziali: da M4 comandano i file in `data/`.

## 1. Scopo della fase
Capire se schierare unità contro un nemico parzialmente visibile è divertente da rigiocare. Le domande a cui rispondere sono al §14.

## 2. Ciclo di una battaglia
1. **Ricognizione**: la mappa è coperta dalla nebbia. Il giocatore ha 3 rivelazioni (§5.1).
2. **Schieramento**: il giocatore compra unità con il budget dello scenario e le piazza su celle calpestabili e visibili, senza nemici (§7). Nessuna distanza minima dal nemico: l'imboscata è una tattica voluta. Un'unità razionale si può comprare come guardia della reliquia, con un sovrapprezzo (§7).
3. **Battaglia**: tutto automatico. Il giocatore può solo mettere in pausa e cambiare velocità (1×, 2×, 4×).
4. **Risultato**: esito, motivo, unità perse, nemici uccisi, durata.

## 3. Fine della battaglia
Controllata nella fase 8 di ogni tick (§6.2), in quest'ordine:
1. **Vittoria** se non resta nessuna unità nemica viva.
2. **Sconfitta per annientamento** se non resta nessuna unità del giocatore viva (i ratti contano).
3. **Sconfitta per furto** se il timer della reliquia arriva a `STEAL_TICKS`.
   - Il timer aumenta di 1 nei tick in cui almeno un'unità nemica viva è entro `RELIC_ON_RADIUS` dal centro della reliquia **e** nessuna unità del giocatore viva è entro `RELIC_CONTEST_RADIUS`.
   - In ogni altro tick torna a 0. Vale qualunque unità nemica, anche diversa da tick a tick.
4. **Sconfitta per tempo** al tick `TIME_LIMIT_TICKS − 1`.

## 4. Mappa `temple_01`
File: `data/maps/temple_01.txt`, 64×40 celle, cella = 16 px. Anteprima: `docs/mappa_temple_01.png`.
Legenda: `#` muro (non calpestabile, blocca la vista) · `.` pavimento · `E` ingresso (pavimento) · `R` reliquia (pavimento). Coordinate `(x, y)` con origine in alto a sinistra, `y` verso il basso. Il centro della cella `(x, y)` è il punto `(x + 0.5, y + 0.5)`.

| Luogo | Area | Note |
|---|---|---|
| Reliquia | `(35,14)` | Centro del Cuore |
| Cuore | x 31–40, y 10–18 | All'inizio è visibile solo la parte entro 4 celle dalla reliquia |
| Sala sud | x 28–43, y 19–25 | Due pilastri; collega il Cuore all'ingresso principale |
| Ingresso principale | y 26, x 33–38 | Largo 6 |
| Corridoio est | y 13–14, x 41–53 | Largo 2, anticamera a x 46–50, y 11–16; ingresso est a x 53 |
| Santuario | x 21–29, y 12–17 | Stanza senza uscite, unita al Cuore da un varco di 2 celle (x 30, y 14–15) e visibile dalla reliquia |
| Cimitero | x 1–14, y 28–38 | Recinto con lapidi; uscite solo dal varco nord (x 8–9, y 27) e dal varco est (x 15, y 31–32) |
| Piazzale e campo | resto della mappa | Rovine sparse che bloccano la vista |

Percorsi A* fino alla reliquia: piazzale ~16 celle, esterno dell'ingresso est ~23, cimitero 37–47.

**Stanze.** Le aree con un nome (Cuore, Sala sud, Santuario, Cimitero…) sono anche dati dello scenario, come rettangoli di celle: servono alle guardie (§7). Oggi lo scenario definisce il Cuore, la stanza della reliquia.

## 5. Visione e distanze

### 5.1 Nebbia e rivelazioni
- All'inizio sono visibili le celle entro `HEART_VISION_RADIUS` dalla reliquia.
- Ogni rivelazione rende visibili le celle entro `REVEAL_RADIUS` dal punto scelto. La nebbia ignora i muri: è informazione dall'alto.
- Le celle rivelate restano visibili per tutto lo schieramento.
- Le unità nemiche nella nebbia sono nascoste. Su piazzale, esterno dell'ingresso est e cimitero c'è un indicatore di minaccia generico, mostrato anche se la zona è vuota.
- In battaglia la nebbia sparisce.

### 5.2 Linea di vista
- Due punti sono in vista se il segmento tra i due non attraversa celle muro. Algoritmo: supercover (tutte le celle toccate dal segmento).
- Se il segmento passa esattamente per lo spigolo comune a due celle diagonali e almeno una delle due è muro, la vista è bloccata.
- Serve linea di vista per notare un nemico, per qualunque attacco e per rianimare.

### 5.3 Distanze
Euclidee, in celle, tra le posizioni delle unità. Le posizioni sono continue.

## 6. Simulazione

### 6.1 Convenzioni
- **Tick**: 20 al secondo, numerati da 0. Il tick 0 è il primo eseguito dopo "Via". Gli eventi "ogni N tick" avvengono ai tick multipli di N maggiori di 0.
- **Secondi → tick**: `round(secondi × 20)`, minimo 1, calcolato al caricamento.
- **ID**: interi crescenti a partire da 1, assegnati in quest'ordine: gruppo Blitz e poi Caccia nell'ordine dello scenario (§9), unità del giocatore nell'ordine della strategia, poi le unità create in battaglia nell'ordine in cui nascono. Un'unità rianimata riceve un nuovo ID.
- **Numeri interi**: vita e danno sono interi. I moltiplicatori si applicano per primi, con arrotondamento per difetto; poi le riduzioni fisse; il danno finale è almeno 1.
- **Età**: le unità schierate partono con età `NEWBORN_COOLDOWN_TICKS` (quindi subito idonee alla riproduzione); le unità nate in battaglia partono da 0.
- **Ricariche**: ogni unità ha i propri timer. La ricarica dell'attacco scende di 1 a ogni tick e non si azzera cambiando bersaglio. All'inizio è a 0 (pronta).

### 6.2 Pipeline del tick
Fasi in ordine; in ogni fase le unità si processano per ID crescente.
1. **Stati**: timer e ricariche scendono; entrate e uscite dalla fuga (§7, goblin).
2. **Bersagli**: scelta o ricalcolo (§6.4).
3. **Movimento**: le unità si spostano; l'orientamento di chi si muove diventa la direzione di movimento.
4. **Attacchi**: si scatta una **fotografia** dello stato (posizioni, orientamenti, vita). Per ogni unità con ricarica a 0, bersaglio vivo, a portata e in vista, si calcola il danno usando solo la fotografia. Calcolati tutti i danni, gli attaccanti si girano verso il proprio bersaglio e la loro ricarica riparte.
5. **Danni**: applicati tutti insieme. Due unità possono uccidersi a vicenda.
6. **Morti**: le unità con vita ≤ 0 diventano `DEAD` e lasciano un cadavere (§6.7).
7. **Abilità periodiche**: prima la rianimazione, poi il pasto dei ratti (§6.8), poi la riproduzione dei ratti.
8. **Fine battaglia**: §3.

### 6.3 Movimento
- AStarGrid2D, 8 direzioni, senza tagliare gli angoli (diagonale solo se le due celle ortogonali sono libere).
- **Ingombro.** Ogni unità viva occupa la cella che contiene la sua posizione. Un'unità non può entrare in una cella occupata da un'unità **nemica** viva: il passo si ferma al bordo di quella cella. **Fra alleati non c'è ingombro**: si attraversano e possono stare nella stessa cella.
- **Percorso.** A* considera come ostacoli, oltre ai muri, le celle occupate da nemici all'inizio della fase 3, salvo la cella di destinazione. Così chi si muove aggira i nemici che trova sulla strada. Se un percorso così non esiste, l'unità usa il percorso che ignora le unità e si ferma al primo nemico che la blocca.
- **Razziatori.** Un'unità che senza bersaglio marcia verso la reliquia (oggi: ogni unità con `NecroBoundWill`) evita la mischia: cerca sempre prima il percorso che aggira i nemici. Se non esiste, il primo nemico che le sbarra il percorso diventa un bersaglio accettato, anche se la sua volontà non lo accetterebbe, e la strada se la apre combattendo.
- **Difensori.** Le unità che tengono una posizione si mettono in mezzo e attaccano chi notano (§6.4, §6.8).
- Velocità in celle al secondo, quindi `velocità / 20` celle per tick lungo il percorso.

### 6.4 Ingaggio e bersaglio
- Un'unità **nota** i nemici vivi entro il proprio raggio di ingaggio e in vista.
- **Scelta**: il nemico notato più vicino; a parità, meno vita; poi ID più basso. Eccezione per il ladro (§7).
- Un'unità **con bersaglio** lo ricalcola ogni `RETARGET_TICKS` tick dal proprio ultimo calcolo, oppure subito se il bersaglio muore o non è più notato. Un'unità **senza bersaglio** cerca a ogni tick.

### 6.5 Attacco e orientamento
- Si attacca se il bersaglio è entro il raggio d'attacco e in vista. Il **tipo d'attacco** è un dato dell'unità, indipendente dal raggio: `melee` (corpo a corpo) o `ranged` (a distanza). Un'unità con la lancia può avere raggio > 1 ed essere `melee`.
- **Orientamento iniziale**: unità del giocatore rivolte nella direzione opposta alla reliquia (sulla cella della reliquia, verso sud); unità nemiche rivolte verso la reliquia. Da ferma, un'unità mantiene l'ultimo orientamento.
- **Alle spalle**: nella fotografia, `dot(orientamento_bersaglio, pos_attaccante − pos_bersaglio) < 0`. A distanza 0 non è mai alle spalle.

### 6.6 Comportamento senza bersaglio
- **Unità con `HoldGroundWill`: pattuglia.** Ai tick multipli di `PATROL_PERIOD_TICKS` ogni unità senza bersaglio sceglie con l'RNG, in ordine di ID, una cella calpestabile senza nemici il cui centro dista ≤ `PATROL_RADIUS` dal suo punto di schieramento, preferendo le celle senza alleati, e ci va. Le guardie pattugliano invece dentro la stanza dell'oggetto sorvegliato, una volta raggiunta (§7). Prima della prima scelta, e dopo aver avuto un bersaglio, torna al punto di schieramento. La pattuglia è tarabile: oggi i valori sono costanti di regola; più avanti la taratura apparterrà alle entità grigie.
- **Ratti**: vagano (§7).
- **Unità nemiche**: avanzano verso la reliquia.
- Quali bersagli un'unità accetta di inseguire lo decide la sua volontà (§6.8).

### 6.7 Morte e cadaveri
- Un cadavere resta per `CORPSE_TICKS` tick nella posizione della morte.
- **Integrità.** Ogni unità ha un'integrità (§7, §8): quanto corpo resta da mangiare o da rianimare. Un goblin, pelle e ossa, ha 1; un revenant, carne impregnata di magia, ha molto; un paladino, uomo allenato in carne e ossa, moltissimo. Il cadavere parte con l'integrità dell'unità morta, che per un rianimato è già diminuita (§8). Un cadavere arrivato a integrità 0 sparisce.
- **Alla morte** (fase 6, in ordine di ID), per ogni unità, rianimati compresi:
  - se la sua integrità è 0 non lascia cadavere (per esempio un ratto);
  - altrimenti si tira il **dado della rianimabilità** con l'RNG. Il cadavere è rianimabile con probabilità `vita massima / (vita massima + K)`, dove `K = REANIMATE_K_BASE + x`. Il termine x raccoglie le condizioni del corpo (fede, malattia…), fuori dalla Fase 1: oggi x = 0. Più vita, più probabile.
  - Un cadavere non rianimabile resta visibile per lo stesso tempo, ma il necromante lo ignora.

### 6.8 Volontà di combattere
Ogni unità ha esattamente un componente di volontà. La volontà decide quali nemici notati (§6.4) l'unità accetta come bersaglio. Un bersaglio che la volontà non accetta più viene abbandonato subito, come uno non più notato. La scelta fra i bersagli accettati segue la regola comune del §6.4.

| Componente | Unità | Bersagli accettati |
|---|---|---|
| `HoldGroundWill` | `goblin` `archer` `thief` `paladin` | Nemici con `distanza(punto di schieramento, nemico) ≤ chase_radius + raggio d'attacco`, in linea d'aria. `chase_radius` è una statistica dell'unità (§7): il suo coraggio. |
| `HungerWill` | `rat` del giocatore | Da affamato: qualunque nemico notato, senza limite, se non ha un cadavere da mangiare. Da sazio: nessuno. |
| `NecroBoundWill` | `servant` `undead` `revenant` `necromancer` e ogni rianimato | Entro `NECRO_INFLUENCE_RADIUS` da un `necromancer` vivo: qualunque nemico notato, senza limite (caccia). Fuori: solo i nemici già entro il proprio raggio d'attacco e quelli che contendono la reliquia, cioè entro `RELIC_CONTEST_RADIUS` dal suo centro (senza mente: non deviano, salvo per difendere il furto). |

**Fame del ratto: lo spazzino.** Mordere non sazia: sazia mangiare un cadavere.
- Ogni ratto nasce **sazio** (schierato o nato in battaglia) per `RAT_DIGEST_TICKS` tick. Il timer scende nella fase 1; a 0 il ratto è **affamato**.
- **Sazio**: non ha bersaglio; vaga a sciame restando vicino alla sua tana (§7) e si riproduce.
- **Affamato**: cerca cibo. Se nota un cadavere con integrità ≥ 1 (entro il proprio raggio d'ingaggio e in vista; il più vicino, a parità l'ID più basso dell'unità morta) ci va e non accetta bersagli. Altrimenti accetta qualunque nemico notato e vaga a sciame senza limiti.
- **Pasto** (fase 7, dopo la rianimazione): un ratto affamato entro 1 cella dal suo cadavere lo mangia: l'integrità del cadavere scende di 1 e il ratto torna sazio per `RAT_DIGEST_TICKS` tick. I ratti mangiano in ordine di ID; a integrità 0 il cadavere sparisce.
- Un ratto rianimato non ha fame: ha `NecroBoundWill`.

**Influenza del necromante.** La distanza si misura dalla posizione dell'unità a quella del necromante vivo più vicino, senza bisogno di vista. Il necromante è sempre entro la propria influenza. Se tutti i necromanti muoiono, i non morti restano senza mente fino alla fine della battaglia. Con la volontà `FearlessTrait` non cambia: i non morti non fuggono mai.

**Guinzaglio dell'influenza.** Nella fase 3 un'unità sotto influenza non fa un passo che la porterebbe oltre `NECRO_INFLUENCE_RADIUS` dal necromante vivo più vicino: se succederebbe, resta ferma in quel tick, mantenendo bersaglio e orientamento. Le unità si processano per ID crescente e il necromante ha un ID più basso dei suoi non morti, quindi si muove prima e i suoi non morti si regolano sulla sua nuova posizione. Il gruppo avanza compatto alla velocità del necromante. Il guinzaglio non trattiene chi è già fuori dall'influenza: resta senza mente finché non rientra nel raggio per conto suo.

**Corpo a corpo e distanza (kiting).** Vale per tutte le unità, secondo il tipo di attacco:
- **Corpo a corpo** (tipo `melee`): ingaggia, cioè si avvicina al bersaglio finché è a portata e in vista (§6.3, §6.5).
- **A distanza** (tipo `ranged`): nella fase 3, se la ricarica dell'attacco è > 0 e c'è un nemico vivo entro `KITE_RADIUS`, l'unità arretra invece di muoversi altrimenti. Si sposta in linea retta, alla propria velocità, in direzione opposta al nemico vivo più vicino; a parità di distanza conta l'ID più basso. Il passo si annulla, e l'unità resta ferma, se la nuova posizione cade in una cella muro oppure, per un'unità con `HoldGroundWill`, se la porta oltre `chase_radius` dal punto di schieramento. Arretrando, l'orientamento diventa la direzione del movimento, quindi l'unità volta le spalle al nemico (§7, ladro).
- **Eccezione del necromante**: arretra solo se non ha più non morti intorno, cioè nessun'altra unità viva con `NecroBoundWill` entro `NECRO_INFLUENCE_RADIUS`. Rianimati compresi. Finché il suo gruppo vive, tiene la posizione e lascia che siano i servi a proteggerlo.

## 7. Unità del giocatore
Budget dello scenario: **2457**.

**Schieramento.** Più unità alleate possono stare nella stessa cella; nessuna unità del giocatore può essere schierata in una cella con un nemico visibile.

**Guardia della reliquia.** Allo schieramento il giocatore può comprare un'unità **razionale** come **guardia**, pagando `ceil(costo × (1 + GUARD_COST_RATIO))`. "La reliquia è più importante della tua vita": la guardia
- ha come posto la **stanza dell'oggetto sorvegliato**: per la reliquia il Cuore (le stanze sono dati dello scenario, §4). Ovunque la si schieri, il suo compito è raggiungere la stanza, esplorando la mappa lungo la strada;
- appena entra nella stanza sceglie con l'RNG una cella della stanza calpestabile, senza nemici, senza alleati e non già scelta da un'altra guardia, e ci va; poi pattuglia **dentro la stanza** (§6.6), con le stesse preferenze. Così le guardie non si ammucchiano;
- non insegue: accetta come bersaglio solo i nemici già entro il proprio raggio d'attacco;
- non fugge mai.
- Dopo l'MVP l'oggetto sorvegliato potrà essere un'unità (un ladro che fa da guardia a un arciere).

**Razionale** è un dato dell'unità: solo le unità razionali possono ricevere ordini, e in Fase 1 l'unico ordine è la guardia. Più avanti le entità grigie e i potenziamenti daranno ordini anche alle unità non razionali.

| Unità | ID | Costo | Vita | Danno | Int. att. | Raggio att. | Tipo att. | Vel. | Ingaggio | Insegue | Razionale | Integrità | Volontà | Abilità |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ratto | `rat` | 158 | 20 | 3 | 0,8 s | 1 | `melee` | 3,0 | 4 | — | no | 0 | `HungerWill` | `WanderBehavior`, `BreedAbility` |
| Goblin | `goblin` | 254 | 45 | 7 | 1,0 s | 1 | `melee` | 2,5 | 5 | 6 | sì | 1 | `HoldGroundWill` | `PackCourageAbility` |
| Arciere | `archer` | 300 | 35 | 12 | 1,5 s | 6 | `ranged` | 1,8 | 7 | 4 | sì | 1 | `HoldGroundWill` | `PointBlankPenalty` |
| Ladro | `thief` | 420 | 40 | 6 | 1,0 s | 1 | `melee` | 3,2 | 7 | 8 | sì | 1 | `HoldGroundWill` | `BackstabAbility` |
| Paladino | `paladin` | 1900 | 400 | 25 | 1,4 s | 1 | `melee` | 1,2 | 4 | 5 | sì | 16 | `HoldGroundWill` | `ArmorAbility` |

"Insegue" è `chase_radius`, in celle (§6.8).

**Ratto, l'animale tollerato.** Il giocatore sceglie solo dove liberarli: non tengono la posizione, ma il punto in cui sono liberati è la loro **tana**; i neonati prendono la tana del primo genitore. Da sazi restano vicino alla tana a riprodursi, da affamati escono a cercare cibo (§6.8).
- *Vagabondaggio a sciame*: i ratti del giocatore con `WanderBehavior`, vivi e senza bersaglio (sazi compresi), formano sciami. Due ratti sono nello stesso sciame se distano ≤ `SWARM_RADIUS`, anche attraverso altri ratti (a catena); un ratto isolato è uno sciame da solo. Ai tick multipli di `WANDER_PERIOD_TICKS`, in ogni sciame (sciami in ordine di ID più basso) ogni ratto vota con l'RNG, in ordine di ID, una delle 8 direzioni (N, NE, E, SE, S, SO, O, NO). Vince la più votata; a parità, quella votata dal ratto con ID più basso fra le pari. Ogni ratto dello sciame va verso la propria posizione + direzione × `WANDER_RADIUS`, accorciando il tratto se un muro taglia la linea, e ci resta fino al voto successivo. Per un ratto **sazio** la meta si accorcia inoltre verso la tana fino a stare entro `SWARM_LEASH_RADIUS` da essa. Un ratto che ottiene un bersaglio, o che va a mangiare, abbandona la meta.
- *Riproduzione*: ai tick multipli di `BREED_PERIOD_TICKS`, ogni coppia di ratti del giocatore idonei a distanza ≤ `BREED_RADIUS` genera un ratto. Idoneo = vivo ed età ≥ `NEWBORN_COOLDOWN_TICKS`. Coppie processate in ordine (ID minore, poi ID maggiore). Le nascite si fermano quando i ratti vivi del giocatore **raggiungono** `RAT_CAP`. Il neonato nasce al centro di una cella **libera** del quadrato 3×3 intorno alla cella del punto medio della coppia, scelta con l'RNG fra le libere (in ordine di riga e colonna). Libera = calpestabile e senza unità vive. Se il 3×3 non ha celle libere, il neonato nasce nell'anello successivo (il bordo del 5×5), poi in quello dopo, e così via. Qui "libera" vale anche per gli alleati, per distribuire le nascite; per il resto valgono le regole d'ingombro del §6.3.

**Goblin, coraggio di gruppo.**
- Con almeno `COURAGE_MIN_ALLIES` altri goblin entro `COURAGE_RADIUS`: danno × (1 + `COURAGE_BONUS`).
- Entra in `FLEE` se non ha goblin alleati entro `COURAGE_RADIUS`, ha vita < `FLEE_HP_RATIO` del massimo e non è in ricarica di fuga. In fuga corre verso la reliquia e non attacca; può essere colpito.
- Esce dalla fuga quando arriva entro 1 cella dalla reliquia, oppure quando ha di nuovo almeno `COURAGE_MIN_ALLIES` goblin entro `COURAGE_RADIUS`. All'uscita il punto di schieramento diventa la posizione attuale e non può rientrare in fuga per `FLEE_COOLDOWN_TICKS`.

**Arciere, tiro ravvicinato.** Se un nemico qualsiasi è entro `POINT_BLANK_RADIUS`, il suo danno è × `POINT_BLANK_MULT`. Senza vista sul bersaglio si muove finché la ottiene.

**Ladro, pugnalata.**
- Colpo alle spalle: danno × `BACKSTAB_MULT`.
- Bersaglio preferito: tra i nemici notati, quelli isolati (nessun loro alleato entro `ISOLATION_RADIUS`); fra questi il più vicino, poi meno vita, poi ID. Se nessuno è isolato, regola comune.
- **Bersaglio fermo** (stato diverso da `MOVE` e `FLEE`): si avvicina al punto 1 cella dietro al bersaglio (opposto al suo orientamento), anche quando il bersaglio è già a portata. **Prima si posiziona, poi colpisce**: finché il punto alle spalle non è muro, il ladro attacca solo quando è alle spalle (§6.5) e non spreca il colpo pronto in un attacco frontale. Se quel punto è muro, va diretto sul bersaglio e attacca normalmente.
- **Bersaglio in movimento** (stato `MOVE` o `FLEE`: cammina, arretra, fugge): il ladro gli va addosso e colpisce appena è a portata, anche di fronte. Appena il bersaglio si ferma, torna a riposizionarsi alle spalle. Se l'arciere arretra, il ladro lo segue.

**Paladino, corazza.** Ogni colpo ricevuto è ridotto di `ARMOR_REDUCTION`. Se nella fotografia almeno `SURROUND_COUNT` nemici vivi sono entro `SURROUND_RADIUS`, la riduzione non si applica.

## 8. Fazione nemica: Non morti del Necromante

| Unità | ID | Vita | Danno | Int. att. | Raggio att. | Tipo att. | Vel. | Ingaggio | Razionale | Integrità | Abilità |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Servo del necromante | `servant` | 30 | 5 | 1,0 s | 1 | `melee` | 3,0 | 5 | no | 1 | `FearlessTrait` |
| Non morto | `undead` | 80 | 8 | 1,3 s | 1 | `melee` | 1,5 | 4 | no | 3 | `FearlessTrait` |
| Revenant | `revenant` | 250 | 18 | 1,2 s | 1 | `melee` | 2,2 | 5 | no | 10 | `FearlessTrait` |
| Necromante | `necromancer` | 120 | 10 | 2,0 s | 5 | `ranged` | 1,3 | 6 | sì | 2 | `FearlessTrait`, `ReanimateAbility` |

**Necromante, rianimazione.** Ricarica di `REANIMATE_COOLDOWN_TICKS`, pronta all'inizio. Quando è pronta e c'è un cadavere rianimabile (§6.7) entro `REANIMATE_RADIUS` e in vista, rianima quello con l'**integrità più alta**, cioè quello che darà il rianimato più forte: per lui i servitori sono scudi di carne. A parità sceglie il più vicino, poi l'ID più basso. Un cadavere è rianimabile se ha integrità ≥ 1 e ha superato il dado (§6.7), anche se i ratti lo stanno mangiando. Poi la ricarica riparte. Vale per qualunque cadavere, anche dei propri servi.
- **Il dardo.** Quando non rianima, il necromante attacca a distanza come le altre unità. Nella fase 4 di un tick in cui la rianimazione è pronta e c'è un cadavere rianimabile entro il raggio e in vista, non attacca: in quel tick rianima.
- **Rianimazione a catena.** Rianimare toglie 1 di integrità. Il rianimato ha vita massima (e vita) pari a `integrità del cadavere × INTEGRITY_HP` e integrità pari a quella del cadavere − 1; quando ricade, il suo cadavere parte da quel valore. Esempio: paladino 400 di vita e integrità 16; rianimato 400 e integrità 15; poi 375 e 14… Un goblin (integrità 1) si rialza una volta con 25 di vita e poi non lascia cadavere. I ratti che mangiano un cadavere ne riducono l'integrità, e quindi la forza del rianimato. Danno, tempi, raggi e velocità restano quelli dell'unità originale. Sta nella fazione nemica e ha solo `FearlessTrait`: perde tutte le altre abilità. Un arciere rianimato tira ancora (il raggio è una statistica), ma senza `PointBlankPenalty`; un ratto rianimato non si riproduce e non conta nel tetto; un paladino rianimato non ha corazza.
- Si comporta come un'unità nemica: avanza verso la reliquia.

- **Cella occupata.** Se la cella del cadavere è occupata da un nemico del rianimato, il rianimato nasce al centro della prima cella calpestabile senza suoi nemici, cercando in anelli via via più ampi, in ordine di riga e colonna, senza RNG.

**Volontà.** Ogni unità nemica ha `NecroBoundWill` (§6.8), compresi i rianimati: la volontà non è un'abilità, quindi il rianimato non la perde.

**`FearlessTrait`**: l'unità non entra mai in `FLEE`.

## 9. Scenario `temple_01`
Prima della ricognizione l'RNG estrae la variante Blitz (A o B), poi la variante Caccia (A o B). Tutte le unità nemiche partono subito verso la reliquia.

**Blitz**: 2 Revenant + 5 Servi.
- **A, piazzale**: Revenant `(34,30)` `(37,30)`; Servi `(33,32)` `(35,32)` `(36,32)` `(38,32)` `(35,33)`.
- **B, fianco est**: Revenant `(58,13)` `(58,15)`; Servi `(60,12)` `(60,14)` `(60,16)` `(61,13)` `(61,15)`.

**Caccia**: 1 Necromante + 5 Non morti, sempre al cimitero.
- **A, ventaglio**: Necromante `(8,33)`; Non morti `(4,30)` `(12,30)` `(3,34)` `(12,34)` `(8,37)`.
- **B, colonna**: Necromante `(8,37)`; Non morti `(5,29)` `(11,29)` `(8,31)` `(4,33)` `(12,33)`.

Le unità sono elencate nell'ordine di assegnazione degli ID.

**Casualità**: solo scelta delle varianti, vagabondaggio dei ratti, cella di nascita dei ratti, cella di pattuglia (§6.6) e dado della rianimabilità (§6.7, un tiro per ogni morte che lascia cadavere). Danni e bersagli sono deterministici.

## 10. Costanti di regola (`data/rules.tres`)

| Costante | Valore | | Costante | Valore |
|---|---|---|---|---|
| `TICK_RATE` | 20 | | `COURAGE_RADIUS` | 3,0 |
| `RETARGET_TICKS` | 10 | | `COURAGE_MIN_ALLIES` | 2 |
| `NECRO_INFLUENCE_RADIUS` | 8,0 | | `COURAGE_BONUS` | 0,3 |
| `RELIC_ON_RADIUS` | 0,5 | | `FLEE_HP_RATIO` | 0,5 |
| `RELIC_CONTEST_RADIUS` | 1,5 | | `FLEE_COOLDOWN_TICKS` | 100 |
| `STEAL_TICKS` | 100 | | `POINT_BLANK_RADIUS` | 1,0 |
| `TIME_LIMIT_TICKS` | 6000 | | `POINT_BLANK_MULT` | 0,5 |
| `CORPSE_TICKS` | 400 | | `BACKSTAB_MULT` | 4 |
| `REVEALS` | 3 | | `ISOLATION_RADIUS` | 3,0 |
| `REVEAL_RADIUS` | 6,0 | | `ARMOR_REDUCTION` | 5 |
| `HEART_VISION_RADIUS` | 4,0 | | `SURROUND_COUNT` | 4 |
| `WANDER_PERIOD_TICKS` | 20 | | `SURROUND_RADIUS` | 1,5 |
| `WANDER_RADIUS` | 3,0 | | `REANIMATE_COOLDOWN_TICKS` | 120 |
| `BREED_PERIOD_TICKS` | 100 | | `REANIMATE_RADIUS` | 6,0 |
| `BREED_RADIUS` | 3,0 | | `RAT_CAP` | 24 |
| `NEWBORN_COOLDOWN_TICKS` | 100 | | `KITE_RADIUS` | 2,0 |
| `SWARM_RADIUS` | 3,0 | | `GUARD_COST_RATIO` | 0,10 |
| `PATROL_PERIOD_TICKS` | 60 | | `PATROL_RADIUS` | 2,0 |
| `SWARM_LEASH_RADIUS` | 4,0 | | `RAT_DIGEST_TICKS` | 200 |
| `INTEGRITY_HP` | 25 | | `REANIMATE_K_BASE` | 1,0 |

## 11. Contratto di `tools/sim.sh`
Wrapper bash di `tools/run_sim.gd` (estende `SceneTree`, argomenti da `OS.get_cmdline_user_args()`).

**Argomenti**: `--scenario <id>`, `--strategy <file.json>`, `--seed <n>` oppure `--seeds <da>-<a>`, `--out <file.jsonl>`.

**Strategia**: `{ name, description, reveals: [[x,y],…], units: [{type, cell:[x,y]},…] }`. In alternativa `by_variant: { "A-A": {reveals, units}, "A-B": …, "B-A": …, "B-B": … }` (chiave = variante Blitz, trattino, variante Caccia): si usa la voce della combinazione estratta.

Ogni unità della strategia può avere `"guard": true` (§7).

**Validazione**: costo ≤ budget (sovrapprezzo delle guardie compreso), al massimo `REVEALS` rivelazioni, ogni unità su cella calpestabile e visibile (§5.1) e senza nemici, guardie solo per unità razionali. Se fallisce: codice di uscita 2 e motivo su stderr.

**Uscita**: una riga JSON per battaglia nel file `--out` (JSON Lines). Su stdout solo un riepilogo leggibile, perché Godot vi scrive anche il proprio banner.
```json
{"scenario":"temple_01","strategy":"s1_sciame_e_lame","seed":42,
 "variant":{"blitz":"A","hunt":"B"},"result":"win","reason":"enemies_dead",
 "ticks":1234,"survivors":{"player":{"rat":12},"enemy":{}},
 "events":[{"tick":87,"type":"death","unit":14,"detail":"undead"}],
 "state_hash":"…"}
```
`reason`: `enemies_dead` · `player_dead` · `relic_stolen` · `timeout`. Tipi di evento: `death` · `reanimate` · `birth` · `flee_start` · `flee_end` · `relic_timer_reset`.

Il riepilogo del batch riporta vittorie/partite in totale e per combinazione di varianti.

## 12. `state_hash`
**Principio**: l'hash contiene **tutto** ciò che può influenzare un tick successivo. Due simulazioni con lo stesso hash si comportano in modo identico da quel momento in poi.

**Ogni entità descrive sé stessa.** Mondo, unità, volontà, cadaveri, e in futuro abilità e potenziamenti, sono entità di stato. Ognuna produce la propria descrizione con tutti i suoi campi, nell'ordine in cui sono dichiarati, e include le descrizioni delle entità che contiene: il mondo contiene unità e cadaveri in ordine di ID, l'unità contiene la sua volontà. Un campo nuovo entra nell'hash da solo. Si esclude un campo solo dichiarandolo, e solo se non è stato della battaglia: regole e mappa (input fissi), dati derivati da essi, buffer azzerati a ogni tick.

`state_hash` = SHA-256 (esadecimale) della descrizione del mondo. I valori sono scritti in forma esatta: float e vettori senza arrotondamento, booleani `1`/`0`, enum come numero, l'RNG con il suo `state`. Un test di guardia cambia un campo alla volta di ogni tipo di entità e verifica che l'hash cambi.

## 13. Fuori perimetro
Gestione della gilda, run e progressione, archetipi del capo, sistema completo di paura/disciplina/avidità (qui solo codardia dei goblin, ratti incontrollati e la volontà del §6.8), interventi del giocatore in battaglia, altre mappe o fazioni, grafica e audio definitivi, salvataggi, determinismo tra piattaforme.

## 14. Domande della fase
1. Le 3 rivelazioni creano una scelta interessante? Misura: vittorie di `s1i` meno vittorie di `s1`, per combinazione.
2. Leggere la disposizione cambia lo schieramento? Misura: come sopra, separando le varianti Caccia A e B.
3. Esiste più di una strategia vincente con 2457 monete?
4. I ratti incontrollati sono un'arma o un rischio? Il necromante li punisce abbastanza?
5. Guardare la battaglia è teso o noioso? (Solo collaudo umano.)
