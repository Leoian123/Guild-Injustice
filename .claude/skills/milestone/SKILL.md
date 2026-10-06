---
name: milestone
description: Esegue una milestone della Fase 1 dall'inizio al report finale. Usare quando l'umano chiede di lavorare su M1…M6.
argument-hint: "M<n>"
disable-model-invocation: true
allowed-tools: Bash(bash tools/check.sh) Bash(bash tools/check.sh *) Bash(git status *) Bash(git diff *) Bash(git add *) Bash(git commit *)
---

Esegui la milestone **$0**.

## 1. Contesto
1. Leggi la voce $0 in `docs/MILESTONES.md`: obiettivo, sezioni del GDD, test, criterio di chiusura.
2. Leggi solo le sezioni del GDD e le voci di `docs/TESTS.md` indicate lì.
3. Leggi in `docs/DECISIONI.md` le voci `da confermare`: se una blocca $0, mettila tra le domande del report.
4. Se la milestone precedente non è chiusa, fermati e dillo.

## 2. Piano
Scrivi un piano breve: file da creare o modificare, test da implementare, domande già note. Se il criterio di chiusura richiede il collaudo umano, dillo nel piano.

## 3. Lavoro
- Procedi a piccoli passi. Dopo ogni passo esegui `bash tools/check.sh`; se è verde, fai commit con `$0: <cosa>`.
- Implementa i test di regola indicati esattamente come in `docs/TESTS.md`.
- Ambiguità che cambiano l'esito: annotale in `docs/DECISIONI.md` come `da confermare` e prosegui sulle parti indipendenti. Dettagli tecnici: decidi e annota come `confermata`.

## 4. Verifica
1. `bash tools/check.sh` deve passare.
2. Usa il subagente `gdd-reviewer` per confrontare il diff della milestone con le sezioni del GDD coinvolte. Correggi solo le difformità che riguardano l'esito delle battaglie o i criteri di chiusura.
3. Riesegui `bash tools/check.sh`.

## 5. Report
Scrivi in chat, in quest'ordine:
1. **Fatto**: file principali e cosa fanno.
2. **Verifica**: ultima riga di riepilogo di `tools/check.sh` (test passati/totali).
3. **Decisioni**: ID da `docs/DECISIONI.md` aggiunti in questa milestone.
4. **Domande**: tutte le voci `da confermare`, ognuna con le opzioni.
5. **Per chiudere**: cosa serve dall'umano (risposte, collaudo). Se non serve niente, scrivi che $0 è chiusa.
