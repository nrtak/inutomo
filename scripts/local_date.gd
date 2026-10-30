class_name LocalDate
extends RefCounted

static func valid(value: Variant) -> bool:
	if not value is String or value.length() != 10 or value[4] != "-" or value[7] != "-":
		return false
	var parts = value.split("-")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	var year = int(parts[0])
	var month = int(parts[1])
	var day = int(parts[2])
	if year < 1970 or month < 1 or month > 12 or day < 1:
		return false
	var leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
	return value == "%04d-%02d-%02d" % [year,month,day] and day <= [31,29 if leap else 28,31,30,31,30,31,31,30,31,30,31][month-1]

