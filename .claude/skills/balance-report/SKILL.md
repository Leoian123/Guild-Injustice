---
name: balance-report
description: Esegue le strategie di riferimento sui seed indicati e produce un report di bilanciamento per combinazione di varianti. Usare dopo M6 o quando l'umano chiede numeri di bilanciamento.
argument-hint: "[da-a, default 1-100]"
disable-model-invocation: true
allowed-tools: Bash(bash tools/sim.sh *)
---

Produci un report di bilanciamento sui seed `$ARGUMENTS` (se vuoto, `1-100`).

## Regola principale
Non modificare dati, regole o codice di gioco durante questo lavoro. Misuri e riporti; le decisioni le prende l'umano.

## Passi
1. Per ogni file in `tools/strategies/` esegui il batch con `bash tools/sim.sh --scenario temple_01 --strategy <file> --seeds <range> --out reports/raw/<nome>.jsonl`.
2. Per ogni strategia calcola, **per combinazione di varianti** (`A-A`, `A-B`, `B-A`, `B-B`): vittorie/partite, motivo della sconfitta più frequente, durata media in secondi, sopravvissuti medi del giocatore.
3. Calcola il **valore dell'informazione**: per ogni combinazione, tasso di vittoria di `s1i_sciame_informato` meno quello di `s1_sciame_e_lame`.
4. Segnala le strategie senza casualità interna (senza ratti): per loro ogni combinazione ha un solo esito e il totale sui seed non è significativo.
5. Scrivi `reports/BILANCIAMENTO_<AAAA-MM-GG>.md` con:
   - una tabella strategia × combinazione;
   - la tabella del valore dell'informazione;
   - fino a 5 osservazioni fattuali (es. "s2 perde sempre per furto nella variante B-*");
   - le domande del GDD §14 a cui i numeri danno una risposta, e quelle che restano aperte.
6. In chat riporta solo il percorso del report e le due tabelle.
