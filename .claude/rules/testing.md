---
paths:
  - "test/**"
---

# Test

- I test di regola sono definiti in `docs/TESTS.md`, con livello, situazione e valore atteso. Implementali esattamente, un test GdUnit4 per voce, con l'ID nel nome (`test_T04_backstab_from_behind`).
- Rispetta il livello indicato:
  - **Funzione**: chiama direttamente la funzione della regola (calcolo del danno, linea di vista, conteggio delle nascite) con dati costruiti nel test.
  - **Mondo**: `World` minimo su mappa di test, con unità `ai_enabled = false` dove indicato (vedi `docs/TESTS.md`, "Modalità di test").
  - **Simulazione**: scenario e strategia reali tramite la stessa API di `tools/sim.sh`.
- Se un test contraddice il GDD, non toccare né il test né la regola: segnala la contraddizione nel report e aspetta.
- Per varianti di unità nei test crea `UnitData` dentro il test. Non modificare quelle in `data/`.
- Il test di determinismo (T01) non si rimuove e non si disattiva mai.
