extends Node
## SaveManager - persistent storage via ConfigFile at user://save.cfg
## (works on web too). Carries a schema_version for graceful migration.

const SAVE_PATH := "user://save.cfg"
const SCHEMA_VERSION := 1


## Returns saved meta merged over `defaults`; falls back to defaults on any
## problem (missing file, corrupt data, future schema we don't understand).
func load_meta(defaults: Dictionary) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return defaults
	var version := int(cfg.get_value("save", "schema_version", 0))
	if version > SCHEMA_VERSION or version <= 0:
		push_warning("Save schema %d unknown (ours: %d) - starting fresh." % [version, SCHEMA_VERSION])
		return defaults
	# version 1 (current). Future migrations: transform older sections here.
	var meta := defaults.duplicate(true)
	for key: String in defaults:
		meta[key] = cfg.get_value("meta", key, defaults[key])
	return meta


func save_meta(meta: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "schema_version", SCHEMA_VERSION)
	for key: String in meta:
		cfg.set_value("meta", key, meta[key])
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save game (err %d)" % err)
