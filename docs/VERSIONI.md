# Versioni e toolchain

Verificate in M1 su Windows 11 con Git Bash.

| Voce | Valore |
|---|---|
| Godot (`"$GODOT" --version`) | `4.7.2.stable.official.ed1daf0bf` (build standard, non .NET; eseguibile `_console`) |
| GdUnit4 | 6.2.1 (`addons/gdUnit4/plugin.cfg`); richiede Godot ≥ 4.5 |
| `--import` disponibile | Sì: `"$GODOT" --headless --path . --import` importa ed esce con 0 |
| Comando test GdUnit4 headless | `"$GODOT" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://test -rd res://reports/raw/gdunit` |
| Codice di uscita GdUnit4 con soli warning | 101 (nodi orfani), verificato con un test temporaneo. Altri codici: 0 successo, 100 errori o fallimenti, 105 errori di script in fase di scoperta (verificato), 103 headless senza `--ignoreHeadlessMode` |

Note:
- Il trucco `-d --remote-debug tcp://127.0.0.1:0` di `addons/gdUnit4/runtest.sh` in Godot 4.7 scrive due righe `ERROR:` (porta non valida): `tools/check.sh` non usa `-d`, quindi non serve.
- L'import headless genera i file `.uid` e `.import`, anche in `addons/`: sono versionati.
