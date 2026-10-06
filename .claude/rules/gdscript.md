---
paths:
  - "**/*.gd"
---

# GDScript

- Solo sintassi Godot 4: `@export`, `@onready`, `await`, `signal.emit()`, `super()`. Mai `export`, `onready`, `yield`, `.connect("signal", obj, "method")`.
- Tipizza tutto: parametri, ritorni, variabili (`var hp: int = 0`), array tipizzati (`Array[SimUnit]`).
- Una classe per file, con `class_name` uguale al nome del file in PascalCase (`sim_unit.gd` → `SimUnit`).
- Nei file sotto `src/sim/` niente `Node`, `get_tree()`, `_process`, `_physics_process`, segnali dell'albero: solo `RefCounted` e `Resource`.
- Costanti numeriche di gioco lette da `data/`, mai letterali nello script. Sono ammessi solo 0, 1 e indici.
