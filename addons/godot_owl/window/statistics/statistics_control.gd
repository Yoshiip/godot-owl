@tool
extends Control

@onready var DailyStatsItem := preload("res://addons/godot_owl/window/statistics/daily_stats_item.tscn")

enum Zoom {
	DAY,
	MONTH,
	YEAR
}

var zoom := Zoom.DAY
var zoom_date := []

var stats := {}

@onready var DayItem := preload("res://addons/godot_owl/window/statistics/month_view/day_item.tscn")
@onready var MonthButton := preload("res://addons/godot_owl/window/statistics/month_button.tscn")
@onready var DayNotInMonth := preload("res://addons/godot_owl/window/statistics/month_view/day_not_in_month.tscn")
@onready var DayChart := preload("res://addons/godot_owl/window/statistics/day_view/day_chart.tscn")

func _ready() -> void:
	zoom_date = get_today()
	refresh()

func get_today() -> Array[int]:
	var _today := Time.get_datetime_dict_from_system()
	return [
		_today.year,
		_today.month,
		_today.day,
	]

func refresh() -> void:
	$container/current_date/today.disabled = zoom_date == get_today()
	for child in $container/year_view.get_children():
		child.queue_free()
	for child in $container/month_view.get_children():
		child.queue_free()
	for child in $container/day_view/container.get_children():
		child.queue_free()
	
	$container/current_date/date.disabled = zoom == Zoom.YEAR
	
	$container/day_view.visible = false
	$container/month_view.visible = false
	$container/year_view.visible = false
	match zoom:
		Zoom.DAY:
			$container/day_view.visible = true
			$container/current_date/date.text = OwlUtils.format_day(zoom_date[0], zoom_date[1], zoom_date[2])
			
			var _total := 0
			if !(stats.has(zoom_date[0])
			&& stats[zoom_date[0]].has(zoom_date[1])
			&& stats[zoom_date[0]][zoom_date[1]].has(zoom_date[2])):
				$container/total.text = "No data for this day!"
				return
			var _values = stats[zoom_date[0]][zoom_date[1]][zoom_date[2]]
			
			var _tween := get_tree().create_tween().set_parallel()
			
			var _current_hour : int = Time.get_datetime_dict_from_system().hour
			
			for i in 24:
				var _day_chart := DayChart.instantiate()
				
				_total += _values.get(i, 0)
				_tween.tween_property(_day_chart.get_node("bar"), "anchor_top", 1.0 - (_values.get(i, 0) / 3600.0), 0.25)
				_day_chart.tooltip_text = str(i, "h - ", round(_values.get(i, 0) / 60), " min.")
				if _current_hour == i && zoom_date == get_today():
					_day_chart.modulate = Color("459e7a")
				$container/day_view/container.add_child(_day_chart)
			$container/total.text = str("Total: ", OwlUtils.format_timer_large(_total))
			
		Zoom.MONTH:
			$container/month_view.visible = true
			$container/current_date/date.text = OwlUtils.format_day(zoom_date[0], zoom_date[1])

			var _has_data := true
			if !(stats.has(zoom_date[0])
			&& stats[zoom_date[0]].has(zoom_date[1])):
				_has_data = false
			var _month_values = []
			if _has_data:
				_month_values = stats[zoom_date[0]][zoom_date[1]]
#
			for i in OwlUtils.DAYS_NAME:
				var _label := Label.new()
				_label.text = i.substr(0, 2) + '.'
				$container/month_view.add_child(_label)
			var _c := 0
			while _c != OwlUtils.weekday(zoom_date[0], zoom_date[1], 1) + 1:
				$container/month_view.add_child(DayNotInMonth.instantiate())
				_c += 1
			var _month_total := 0
			for day in range(1, OwlUtils.days_in_month(zoom_date[1], zoom_date[0]) + 1):
				var _total := 0
				if _month_values.has(day):
					for hour in _month_values[day]:
						_total += _month_values[day][hour]
				_month_total += _total
				var _day_item := DayItem.instantiate()
				_day_item.text = str(day)
				_day_item.modulate = lerp(Color.WHITE, Color("3df0a7"), float(_total) / (3600.0 * 4.0))
				_day_item.tooltip_text = OwlUtils.format_timer_large(_total)
				_day_item.pressed.connect(_day_button_pressed.bind(day))
				$container/month_view.add_child(_day_item)
			
			while $container/month_view.get_child_count() % 7 != 0:
				$container/month_view.add_child(DayNotInMonth.instantiate())
			
			$container/total.text = "Total for " + OwlUtils.MONTHS[zoom_date[1] - 1] + ": " + OwlUtils.format_timer_large(_month_total)
				
		Zoom.YEAR:
			$container/year_view.visible = true
			$container/current_date/date.text = OwlUtils.format_day(zoom_date[0])
			for month in OwlUtils.MONTHS.size():
				var _btn := MonthButton.instantiate()
				_btn.text = OwlUtils.MONTHS[month]
				_btn.tooltip_text = OwlUtils.format_timer_large(get_total_for_month(zoom_date[0], month + 1))
				_btn.pressed.connect(_month_button_pressed.bind(month + 1))
				$container/year_view.add_child(_btn)
			
			var _total := get_total_for_year(zoom_date[0])
			$container/total.visible = _total != 0
			$container/total.text = str("Total for ", zoom_date[0], ": ", OwlUtils.format_timer_large(_total))

func get_total_for_year(year : int) -> int:
	var _total := 0
	if !(stats.has(year)):
		return 0
	for month in 12:
		_total += get_total_for_month(year, month)
	return _total

func get_total_for_month(year : int, month : int) -> int:
	var _total := 0
	if !(stats.has(year) && stats[year].has(month)):
		return 0
	for day in OwlUtils.days_in_month(month, year):
		_total += get_total_for_day(year, month, day)
	return _total

func get_total_for_day(year : int, month : int, day : int) -> int:
	var _total := 0
	if !(stats.has(year) && stats[year].has(month) && stats[year][month].has(day)):
		return 0
	for hour in 24:
		_total += stats[year][month][day].get(hour, 0)
	return _total

func _day_button_pressed(day : int) -> void:
	zoom = Zoom.DAY
	zoom_date = [zoom_date[0], zoom_date[1], day]
	refresh()


func _month_button_pressed(month : int) -> void:
	zoom = Zoom.MONTH
	zoom_date = [zoom_date[0], month]
	refresh()


func _on_date_pressed() -> void:
	zoom += 1
	if zoom == Zoom.MONTH:
		zoom_date = [zoom_date[0], zoom_date[1]]
	elif zoom == Zoom.YEAR:
		zoom_date = [zoom_date[0]]
	refresh()


func _on_previous_pressed() -> void:
	match zoom:
		Zoom.DAY:
			zoom_date = OwlUtils.increment_day(zoom_date[0], zoom_date[1], zoom_date[2], -1)
		Zoom.MONTH:
			zoom_date = OwlUtils.increment_month(zoom_date[0], zoom_date[1], -1)
		Zoom.YEAR:
			zoom_date[0] -= 1
	refresh()


func _on_next_pressed() -> void:
	match zoom:
		Zoom.DAY:
			zoom_date = OwlUtils.increment_day(zoom_date[0], zoom_date[1], zoom_date[2], 1)
		Zoom.MONTH:
			zoom_date = OwlUtils.increment_month(zoom_date[0], zoom_date[1], 1)
		Zoom.YEAR:
			zoom_date[0] += 1
	refresh()


func _on_today_pressed() -> void:
	zoom = Zoom.DAY
	zoom_date = get_today()
	refresh()
