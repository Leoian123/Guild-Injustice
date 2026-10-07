---
paths:
  - "src/sim/**"
  - "tools/**"
---

# Determinismo della simulazione

Obiettivo: stesso input + stesso seed + stessa macchina e versione = stesso `state_hash`. Il determinismo tra piattaforme diverse non è richiesto: usa float normali.

- Il tick lo avanza `World.step()`, a 20 tick/s. Mai `_process`, mai `delta`.
- Un solo `RandomNumberGenerator`, creato da `World` con il seed e passato esplicitamente. Mai `randf()`, `randi()`, `randomize()`, `Array.shuffle()`, `pick_random()`.
- Usa l'RNG solo dove lo prevede il GDD §9 (varianti, vagabondaggio a sciame, celle di nascita, cella di pattuglia, dado della rianimabilità), nell'ordine in cui il GDD descrive gli eventi.
- Le unità si iterano sempre per ID crescente. Ogni ordinamento termina con il confronto sull'ID: `sort_custom` non è stabile.
- Segui la pipeline del GDD §6.2. La fase attacchi legge una fotografia dello stato, i danni si applicano tutti insieme.
- Le Resource caricate sono condivise: `SimUnit` copia i valori da `UnitData` alla creazione e non scrive mai sulla Resource.
- I secondi del GDD diventano tick al caricamento dei dati, una volta sola.
- La view può interpolare e separare graficamente le unità sovrapposte; la simulazione non sa che esiste.
- `state_hash` segue il GDD §12. Se aggiungi un campo allo stato, aggiungilo all'hash.
