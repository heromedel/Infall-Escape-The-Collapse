class_name LogBook
extends RefCounted
## A run's log file in user://logs. Every entry is two lines: a machine line with every field, and a line a
## person can read, written from it (coding rule 10).

var _path: String


static func open_for_run(seed_number: int) -> LogBook:
	var book := LogBook.new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	book._path = "user://logs/run-%d.log" % seed_number
	return book


func write(kind: String, fields: Dictionary, readable: String) -> void:
	var file: FileAccess
	if FileAccess.file_exists(_path):
		file = FileAccess.open(_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:
		file = FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		return
	var stamp := Time.get_datetime_string_from_system()
	file.store_line("%s %s %s" % [stamp, kind, JSON.stringify(fields)])
	file.store_line("    " + readable)


func folder() -> String:
	return ProjectSettings.globalize_path("user://logs")
