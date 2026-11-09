class_name Species
extends RefCounted
## The GATOS Species setting (GV 7A): `GATOS Species: Terrans > Tabbys`. With Terrans, the default, the GATOS are
## humans, the Galactic Alliance of Terran Occupied Systems; with Tabbys they are cats, of Tabby Occupied Systems,
## the HalfMechs kitten-like and the Senti holographic cats. Text says both ways as {gatos:Terran words|Tabby words},
## e.g. "{gatos:children|kittens}", and is filled in when shown, so changing the setting mid-run changes it.

static var _pattern: RegEx = null


static func tabbys() -> bool:
	return Settings.get_value("gatos_species", "Terrans") == "Tabbys"


static func words(text: String) -> String:
	if not text.contains("{gatos:"):
		return text
	if _pattern == null:
		_pattern = RegEx.create_from_string("\\{gatos:([^|}]*)\\|([^}]*)\\}")
	return _pattern.sub(text, "$2" if tabbys() else "$1", true)
