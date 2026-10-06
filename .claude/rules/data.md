---
paths:
  - "data/**"
  - "tools/strategies/**"
---

# Dati

- In M4 trascrivi i valori iniziali dal GDD (§7, §8, §10) in `data/units/*.tres`, `data/scenarios/temple_01.tres` e `data/rules.tres`. Da quel momento i `.tres` sono la fonte dei numeri e il GDD riporta solo i valori di partenza.
- Non cambiare un valore per far vincere o perdere una strategia. Il bilanciamento lo decide l'umano, dopo aver visto i numeri.
- `data/maps/` e `tools/strategies/` sono forniti dall'umano e protetti in scrittura.
- Un nuovo campo in una Resource richiede una regola nel GDD che lo usi. Se la regola non c'è, chiedi.
