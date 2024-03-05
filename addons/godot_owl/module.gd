@tool
extends MenuButton

var settings := OwlSettings.new()

const SAVE_PATH := "user://godot_owl.dat"
const FILE_SAVE_VERSION := 1

var total_time := 0
var session_time := 0
var daily_stats := {}

var paused := false
var focused := true
var unfocus_pause_timer := 0

@onready var BaseWindow := preload("res://addons/godot_owl/window/window.tscn")
@onready var StatisticsControl := preload("res://addons/godot_owl/window/statistics/statistics_control.tscn")
@onready var SettingsControl := preload("res://addons/godot_owl/window/settings/settings_control.tscn")

@onready var PauseTexture := preload("res://addons/godot_owl/icons/pause.png")

@onready var PausedIcon := preload("res://addons/godot_owl/icon_paused.png")
@onready var DefaultIcon := preload("res://addons/godot_owl/icon.png")

func _ready() -> void:
	if !Engine.is_editor_hint():
		queue_free()
	get_popup().connect("id_pressed", id_pressed)
	load_data()
	$timer.start()
	
	settings_updated()
	

func id_pressed(id : int) -> void:
	if id == 0:
		paused = !paused
		update_pause()
		if paused:
			get_popup().set_item_text(1, "Unpause")
		else:
			get_popup().set_item_text(1, "Pause")
	if id == 1:
		var _popup := BaseWindow.instantiate()
		_popup.title = "Statistics"
		var _statistics := StatisticsControl.instantiate()
		_statistics.stats = daily_stats
		_popup.add_child(_statistics)
		add_child(_popup)
	if id == 2:
		var _popup := BaseWindow.instantiate()
		_popup.title = "Settings"
		var _settings := SettingsControl.instantiate()
		_settings.main_node = self
		_popup.add_child(_settings)
		add_child(_popup)


func increment_current_date() -> void:
	var _time := Time.get_datetime_dict_from_system()
	if !daily_stats.has(_time.year):
		daily_stats[_time.year] = {}
	if !daily_stats[_time.year].has(_time.month):
		daily_stats[_time.year][_time.month] = {}
	if !daily_stats[_time.year][_time.month].has(_time.day):
		daily_stats[_time.year][_time.month][_time.day] = {}
	if !daily_stats[_time.year][_time.month][_time.day].has(_time.hour):
		daily_stats[_time.year][_time.month][_time.day][_time.hour] = 0


	daily_stats[_time.year][_time.month][_time.day][_time.hour] += 1

func update_pause() -> void:
	if (unfocus_pause_timer < settings.autopause_delay || focused) && !paused:
		icon = null
		$icon.modulate = Color("3df1a87f")
		$icon.texture = DefaultIcon
		get("theme_override_styles/normal").border_color = Color("3df1a87f")
	else:
		icon = PauseTexture
		$icon.texture = PausedIcon
		$icon.modulate = Color("ffa5007f")
		get("theme_override_styles/normal").border_color = Color("ffa5007f")

func _on_timer_timeout() -> void:
	if (unfocus_pause_timer < settings.autopause_delay || focused) && !paused:
		if focused:
			unfocus_pause_timer = 0
		else:
			unfocus_pause_timer += 1
		total_time += 1
		session_time += 1
		increment_current_date()
		
		if settings.low_distraction:
			text = ""
		else:
			text = OwlUtils.format_timer(total_time)
		get_popup().set_item_text(0, str("Total session time : ", OwlUtils.format_timer_large(session_time)))


func save_data() -> void:
	var _file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if _file != null:
		_file.store_16(FILE_SAVE_VERSION)
		_file.store_64(total_time)
		_file.store_var(daily_stats)
		_file.close()


func load_data() -> void:
	var _file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if _file != null:
		if FILE_SAVE_VERSION != _file.get_16():
			printerr("[!] Loaded file and plugin version are different")
		total_time = _file.get_64()
		daily_stats = _file.get_var()
		_file.close()


func _on_autosave_timeout() -> void:
	save_data()


func _notification(what) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			focused = true
			update_pause()
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			focused = false

func settings_updated() -> void:
	flat = settings.low_distraction
	custom_minimum_size.x = 28 if settings.low_distraction else 100
