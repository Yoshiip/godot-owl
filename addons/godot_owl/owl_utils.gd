@tool
class_name OwlUtils

extends Node

static func format_timer(seconds : int) -> String:
	return "%02d:%02d:%02d" % [floor(seconds / 3600), fmod(floor(seconds / 60), 60), seconds % 60]


static func format_timer_large(seconds : int) -> String:
	return "%02dh %02dm %02ds" % [floor(seconds / 3600), fmod(floor(seconds / 60), 60), seconds % 60]


static func today() -> String:
	var _t := Time.get_datetime_dict_from_system()
	return "%02d-%02d-%02d" % [_t.year, _t.month, _t.day]


static func weekday(year: int, month: int, day : int) -> int:
	if month < 3:
		month += 12
		year -= 1
	var J : int = floor(year / 100)
	var K : int = year % 100
	return ((day + (13 * (month + 1)) / 5 + K + (K / 4) + (J / 4) - 2 * J) - 3) % 7


static func days_in_month(month: int, year: int) -> int:
	var days_per_month = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

	if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
		days_per_month[2] = 29

	return days_per_month[month]

static var MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
static var DAYS_NAME := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

static func format_day(year : int, month = 0, day = 0) -> String:
	var _text := ""
	if month != 0:
		_text += str(MONTHS[(month - 1) % 12], ' ')
	if day != 0:
		_text += str(DAYS_NAME[(weekday(year, month, day) + 1) % 7], ' ', day, ' ')
	return str(_text, year)

static func increment_day(year : int, month : int, day : int, increment : int) -> Array:
	day += increment
	
	while day <= 0:
		day += days_in_month(month, year)
		month -= 1
		while month <= 0:
			month += 12
			year -= 1
	
	
	while day > days_in_month(month, year):
		day -= days_in_month(month, year)
		month += 1
		while month > 12:
			month -= 12
			year += 1
	
	return [year, month, day]

static func increment_month(year : int, month : int, increment : int) -> Array:
	month += increment
	while month <= 0:
		month += 12
		year -= 1
	while month > 12:
		month -= 12
		year += 1
	
	return [year, month]
