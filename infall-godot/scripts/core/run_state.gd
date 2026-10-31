class_name RunState
extends RefCounted
## One run: the squad, the shared Mawjig pool (GDD 4E), the galaxy and where the squad is in it.

var seed_value: int = 0
var mawjig: int = 1211
var squad: Array[Ship] = []


## Pays from the squad's pool. Returns false, and pays nothing, when there isn't enough.
func spend(cents: int) -> bool:
	if cents > mawjig:
		return false
	mawjig -= cents
	return true


func earn(cents: int) -> void:
	mawjig += cents
