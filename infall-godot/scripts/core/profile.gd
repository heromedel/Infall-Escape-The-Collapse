class_name Profile
extends RefCounted
## What carries over between runs: which starting ships are unlocked (GDD 7C: other starts unlock later).

const PATH := "user://profile.cfg"


static func unlocked() -> Array:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return []
	return file.get_value("profile", "unlocked", [])


static func unlock(key: String) -> bool:
	var list := unlocked()
	if list.has(key):
		return false
	list.append(key)
	var file := ConfigFile.new()
	file.load(PATH)
	file.set_value("profile", "unlocked", list)
	file.save(PATH)
	return true
