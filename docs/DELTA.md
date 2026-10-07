# Delta: scelte di comodo e visione finale

Registro delle scelte prese **per comodità della Fase 1** che il gioco finale potrebbe dover cambiare. La Fase 1 serve a capire se il puzzle di schieramento è divertente, quindi le scorciatoie sono legittime; questo file serve a non farle diventare definitive senza volerlo.

Per ogni voce:
- **Ora**: la scelta attuale.
- **Perché è comoda**: cosa ci fa risparmiare oggi.
- **Visione finale**: cosa potrebbe servire, secondo ciò che sappiamo del gioco completo (unità dark fantasy con volontà propria, n mappe, potenziamenti, stile Darkest Dungeon e Mordheim).
- **Soglia**: il segnale misurabile che impone di rivederla.
- **Costo del cambio**: stima di cosa toccherebbe.

Regole:
- Ogni nuova scelta di comodo entra qui nel momento in cui viene presa.
- Il report di fine milestone elenca le voci aggiunte o cambiate.
- Una voce si chiude solo quando la visione finale è implementata o quando l'umano decide che la scelta attuale è definitiva.

| ID | Area | Ora | Perché è comoda | Visione finale | Soglia | Costo del cambio | Stato |
|---|---|---|---|---|---|---|---|
| Δ-01 | Paradigma | Oggetti con componenti (`SimUnit` + volontà e abilità), niente ECS (`CLAUDE.md`) | Stile naturale di GDScript; leggibile; basta per decine di unità | Possibile ECS o motore in C#/C++ se crescono unità e sistemi | > ~200 unità contemporanee, oppure battaglia > ~2 s in headless, oppure mappe > ~128×128 | Alto: riscrittura di `src/sim/`; la verifica è possibile confrontando gli `state_hash` | aperta |
| Δ-02 | Percorsi | A* ricalcolato a ogni tick per ogni unità che si muove (D-020) | Semplice e sempre corretto | Campo di direzioni condiviso verso la reliquia, oppure cache dei percorsi | Battaglia > ~2 s, oppure mappe più grandi di 64×40 | Medio: solo la fase 3; i test di movimento devono restare verdi | aperta |
| Δ-03 | Determinismo | Float e `Vector2` nativi; determinismo solo sulla stessa macchina e versione (GDD §13) | Nessuna aritmetica a punto fisso | Replay condivisi, sfide asincrone o multiplayer richiedono determinismo fra piattaforme | Prima funzione che confronta simulazioni fra macchine diverse | Alto: aritmetica a punto fisso in tutta la simulazione | aperta |
| Δ-04 | Leader | Il necromante si riconosce dal tipo `necromancer` (D-021) | Una sola fazione con un solo leader | Più fazioni, ognuna con i propri leader e tipi di influenza | Seconda fazione o secondo tipo di leader | Basso: un'etichetta o un'abilità "leader" al posto del tipo | aperta |
| Δ-05 | Volontà | Una volontà per unità; il coraggio è un raggio fisso (`chase_radius`) | Prima versione misurabile del sistema | Morale dinamico con più cause combinate (ferite, alleati caduti, stress, avidità) | Primo potenziamento o tratto che modifica la volontà durante la battaglia | Medio: `SimWill` diventa una composizione di cause | aperta |
| Δ-06 | Impronta | Elenco fisso di campi nel §12 (D-002, D-023) | Formato semplice | Ogni entità descrive tutti i propri campi; l'impronta cresce da sola | Già superata: richiesta dell'umano del 7 ottobre 2026 | Basso | chiusa il 7 ottobre 2026 (D-024) |
| Δ-07 | Statistiche dei test | Statistiche delle unità trascritte in `test/support/test_worlds.gd` (D-017) | Permette i test prima di `data/units/` | Una sola fonte: `data/units/*.tres` | M4 | Basso | aperta, si chiude in M4 |
| Δ-08 | Collisioni | Le unità non si bloccano a vicenda (GDD §6.3) | Niente evitamento locale | Sbarramenti e formazioni potrebbero richiedere ingombro fisico | Collaudo M5: lo sbarramento del Blitz sembra arbitrario | Medio-alto: fase 3 e pathfinding | aperta, da osservare in M5 |
| Δ-09 | Arretramento | Il passo all'indietro controlla solo la cella di arrivo (D-022) | Niente pathfinding per arretrare | Arretramento lungo un percorso valido, senza sfiorare i muri | Arretramenti visibilmente innaturali nel collaudo | Basso | aperta |
| Δ-10 | Fotografia | La fase 4 copia lo stato di tutte le unità a ogni tick | Semplice e sicura per il calcolo simultaneo | Copia solo di chi attacca e dei vicini | Coincide con Δ-01 | Basso | aperta |
