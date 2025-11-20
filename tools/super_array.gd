##Array Object that nests multiple sub-arrays, extra utility and more functionality.
##
##Every Array value also has a Key (String), Weight (float), Lock (bool) and Extra (Variant).
##Could be seen as a dictionary, but these sub-arrays seemlessly interact with eachother.
##
##@tutorial(Short overview): https://youtu.be/EVGFeJMQArM
##@experimental

extends Object

class_name SuperArray

##Data types within the SuperArray (sub-arrays)
enum DATA{
		MAIN,
		INDEX,
		WEIGHT,
		KEY,
		LOCK,
		EXTRA
	}

var data: Dictionary = {
	"main" : [] as Array,
	"index" : [] as PackedInt32Array,
	"weight" : [] as PackedFloat64Array,
	"lock": [] as Array[bool],
	"key" : [] as PackedStringArray,
	"extra": [] as Array
	}

var _refs: Dictionary = {}
	
var _baked: Dictionary = {}
	
var _calc: SuperArray_calc = SuperArray_calc.new(self)

##Can be created with an existing Array.
func _init(base_array: Array = []) -> void:
	data.main = base_array.duplicate()
	_calc.fill_empty()
	_calc.check()
	
func _to_string() -> String:
	var new_string: String = ""
	for n in data.main.size():
		new_string += " [%d]" % n
		var lock_string: String = "[UNLOCKED]"
		if data.lock[n]: lock_string = "[LOCKED]"
		new_string += lock_string
		new_string += " %s" % str(data.main[n])
		if !data.key[n].is_empty(): new_string += " (%s)" % data.key[n]
		new_string += ": %0.2f" % data.weight[n]
		if !data.extra[n] == null: new_string += " (extra: %s)" % str(data.extra[n])
		new_string += ","
	new_string.rstrip(",")
		
	return new_string
	
	
func _get(property: StringName) -> Variant:
	if property.is_valid_int() and int(property) < size():
		return data.main[int(property)]
	else: return null
	
	
##Appends value at the end of the SuperArray. Supports extra data with flexibly Typing.
##[codeblock]
##my_super.append(my_var)
###Adds my_var to the Array with default data.
##my_super.append(my_var,1.2,"important",true)
###Adds my_var to the Array with a custom weight of 1.2, key of "important" and locked = true.
##[/codeblock]
func append(the_value: Variant, ...extra_data: Array) -> void:
	data.main.append(the_value)
	var the_size: int = data.main.size()-1
	for item in extra_data:
		match typeof(item):
			TYPE_FLOAT: if data.weight.size() == the_size: data.weight.append(item)
			TYPE_STRING: if data.key.size() == the_size: data.key.append(item)
			TYPE_BOOL: if data.lock.size() == the_size: data.lock.append(item)
			_: if data.extra.size() == the_size: data.extra.append(item)
	_calc.fill_empty()
	_calc.check()


##Appends another array at the end of this SuperArray.
##Currently does not support extra data.
func append_array(array: Array) -> void:
	data.main.append_array(array)
	_calc.fill_empty()
	_calc.check()

##Appends another SuperArray at the end of this SuperArray.
func append_super_array(super_array: SuperArray) -> void:
	data.main.append_array(super_array.data.main)
	data.index.append_array(super_array.data.index)
	data.weight.append_array(super_array.data.weight)
	data.lock.append_array(super_array.data.lock)
	data.key.append_array(super_array.data.key)
	data.extra.append_array(super_array.data.extra)
	_calc.reset_index_array()
	_calc.check()
	

##Returns the last element of the array. If the array is empty or fully locked, fails and returns null.
##See also front(). Skips over locked values.
func back() -> Variant:
	for n in data.main.size():
		var the_index: int = (n+1)*-1
		if !data.lock[the_index]: return data.main[the_index]
	return null


##Returns a read-only Array for the requested Data Type.
##Intended for debugging. See also unpack().
func view(from_data: DATA = DATA.MAIN) -> Array:
	match from_data:
		DATA.MAIN:
			var new_array: Array = data.main.duplicate()
			new_array.make_read_only()
			return new_array
		DATA.INDEX:
			var new_array: Array = Array(data.index.duplicate())
			new_array.make_read_only()
			return new_array
		DATA.WEIGHT:
			var new_array: Array = Array(data.weight.duplicate())
			new_array.make_read_only()
			return new_array
		DATA.KEY:
			var new_array: Array = Array(data.key.duplicate())
			new_array.make_read_only()
			return new_array
		DATA.LOCK:
			var new_array: Array = Array(data.lock.duplicate())
			new_array.make_read_only()
			return new_array
		DATA.EXTRA:
			var new_array: Array = data.extra.duplicate()
			new_array.make_read_only()
			return new_array
	return []
	
	
##Removes all elements from the SuperArray.
func clear():
	for data_type in data:
		data[data_type].clear()
	_calc.check()
	
	
##Packs multiple typed arrays into a SuperArray. Fills in missing data with default values.
##The given arrays should be correctly typed and of equal length. First entry is always the main array.
##[codeblock]
##var my_array: Array = [value1, value2, value3]
##var my_weights: PackedFloat64Array = [0.3, 1.0, 1.5]
##var my_keys: PackedStringArray = ["name", "age", "height"]
##var my_locks: Array[bool] = [false, false, true]
##
##my_super.pack(my_array, my_weights, my_keys, my_locks)
##[/codeblock]
func pack(the_values: Array, ...arrays: Array):
	var the_size: int = arrays[0].size()
	for array in arrays:
		if array.size() != the_size:
			push_error("size of packed arrays are not equal.")
			return
	clear()
	data.main = the_values
	for array in arrays:
		match typeof(array):
			TYPE_PACKED_FLOAT64_ARRAY: data.weight = array
			TYPE_PACKED_STRING_ARRAY: data.key = array
			_:
				if array is Array[bool]:
					data.lock = array
				else: data.extra = array
	_calc.fill_empty()
	_calc.check()


##Unpacks a SuperArray into its separate data types.
##Returns a Dictionary with DATA as the key with their matching typed Array
##[codeblock]
##{
##DATA.MAIN: Array,
##DATA.WEIGHT: PackedFloat64Array,
##DATA.KEY: PackedStringArray,
##DATA.LOCK: Array[bool],
##DATA.EXTRA: Array
##}
##[/codeblock]
func unpack() -> Dictionary:
	return {
		DATA.MAIN: data.main as Array,
		DATA.WEIGHT: PackedFloat64Array(data.weight),
		DATA.KEY: PackedStringArray(data.key),
		DATA.LOCK: data.lock as Array[bool],
		DATA.EXTRA: data.extra as Array
	}


##Returns the number of times an element is in the array. Skips over locked values.
##Can target different data types.
func count(the_value: Variant, data_type: DATA = DATA.MAIN) -> int:
	var the_count: int = 0
	match data_type:
		DATA.INDEX: push_error("Counting by INDEX not supported. Use SuperArray.size() instead.")
		_: the_count = find_all(the_value,data_type).size()
	return the_count


##Finds and removes the first occurrence of value from the array that is not locked. If value does not exist in the array or is locked, nothing happens.
##Can target different data types. To remove an element by index or to remove a locked element, use remove_at() instead.
func erase(the_value: Variant, data_type: DATA = DATA.MAIN) -> void:
	var the_index: int = find(the_value, data_type)
	if the_index == -1: return
	remove_at(the_index)
	_calc.reset_index_array()
	_calc.check()
	
	
##Finds and removes every occurrence of value from the array that is not locked. If values don't not exist in the array or are locked, nothing happens.
##Can target different data types. To remove elements by index or to remove locked elements, use remove_all_at() instead.
func erase_all(the_value: Variant, data_type: DATA = DATA.MAIN) -> void:
	var amount: int = count(the_value, data_type)
	for n in amount:
		erase(the_value,data_type)
	_calc.reset_index_array()
	_calc.check()
	

##Append the given value a set amount or times to the array.
##Currently does not support extra data.
func fill(the_value: Variant, amount: int) -> void:
	for n in amount:
		data.main.append(the_value)
	_calc.fill_empty()
	_calc.check()
	
	
##Calls the given Callable on each element in the SuperArray and returns a new, filtered SuperArray.
##Does not skip over locked elements. Callable argument is a SuperArray holding only the current element.
##[codeblock]
##func custom_filter(element: SuperArray):
##	if element.value().size < 5 and \
##	element.locked() and \
##	element.weight() > 1.0:
##		return true
##	return false
##
###Returns a new SuperArray containing only elements that have values with a size property less than 5,
###that are locked and that have a weight higher than 1.0.
##var new_super: SuperArray = my_super.filter(custom_filter)
##[/codeblock]
func filter(method: Callable) -> SuperArray:
	var new_super: SuperArray = SuperArray.new()
	for n in data.main.size():
		var temp_super: SuperArray = SuperArray.new()
		temp_super.append(data.main[n],data.weight[n],data.key[n],data.lock[n],data.extra[n])
		if method.call(temp_super):
			new_super.append(data.main[n],data.weight[n],data.key[n],data.lock[n],data.extra[n])
	return new_super


##Returns all values in the SuperArray that are locked / unlocked.
func filter_locked(is_locked: bool) -> Array:
	var new_array: Array = []
	for n in data.lock.size():
		if data.lock[n] == is_locked: new_array.append(data.main[n])
	return new_array


##Returns the index of the first occurrence of value in the SuperArray that is not locked, or -1 if there are none or they are locked.
##Can target different data types.
func find(the_value: Variant, data_type: DATA = DATA.MAIN) -> int:
	match data_type:
		DATA.MAIN:
			for n in data.main.size():
				if data.main[n] == the_value and !data.lock[n]: return n
		DATA.WEIGHT:
			for n in data.weight.size():
				if data.weight[n] == the_value and !data.lock[n]: return n
		DATA.KEY:
			for n in data.key.size():
				if data.key[n] == the_value and !data.lock[n]: return n
		DATA.LOCK: return data.lock.find(the_value)
		DATA.EXTRA:
			for n in data.extra.size():
				if data.extra[n] == the_value and !data.lock[n]: return n
		DATA.INDEX: push_error("Finding by INDEX not supported, it would just return the same index.")
	return -1


##Returns the indices of the values in the SuperArray that are not locked as a PackedInt32Array,
##or an empty array if there are none or they are locked.
##Can target different data types.
func find_all(the_value: Variant, data_type: DATA = DATA.MAIN) -> PackedInt32Array:
	var indices: PackedInt32Array = []
	match data_type:
		DATA.MAIN:
			for n in data.main.size():
				if data.main[n] == the_value and !data.lock[n]: indices.append(n)
		DATA.WEIGHT:
			for n in data.weight.size():
				if data.weight[n] == the_value and !data.lock[n]: indices.append(n)
		DATA.KEY:
			for n in data.key.size():
				if data.key[n] == the_value and !data.lock[n]: indices.append(n)
		DATA.LOCK:
			for n in data.lock.size():
				if data.lock[n] == the_value: indices.append(n)
		DATA.EXTRA:
			for n in data.extra.size():
				if data.extra[n] == the_value and !data.lock[n]: indices.append(n)
		DATA.INDEX: push_error("Finding by INDEX not supported, it would just return the same index.")
		
	return indices


##Returns the value in SuperArray at index. Does not respect lock.
func value(the_index: int = 0) -> Variant:
	return data.main[the_index]
	

##Returns the values in SuperArray as an array, at the incides provided in a PackedInt32Array.
##Has the option to respect locks. Leave empty to return all valid values.
func values(index_array: PackedInt32Array = [], respect_locks: bool = false) -> Array[Variant]:
	var values_array: Array = []
	if index_array.is_empty(): index_array = data.index
	for n in index_array:
		if respect_locks and data.lock[n]: continue
		values_array.append(data.main[n])
	return values_array
	
	
##
##Returns the value in SuperArray for specific value in data. Skips over locks.
##[codeblock]
###Can be used to fetch a variable by key.
##my_var = my_super.value_from("the_key", SuperArray.DATA.KEY)
##[/codeblock]
func value_from(the_value: Variant, data_type: DATA) -> Variant:
	var the_index: int = find(the_value, data_type)
	return data.main[the_index]
	
	
##Returns the key in SuperArray at index. Does not skip over lock.
func key(the_index: int = 0) -> String:
	return data.key[the_index]
	
	
##Returns the key in SuperArray for specific value. Skips over locks.
##[codeblock]
###Can be used to fetch a key by value.
##my_key = my_super.key_from_value(my_var)
##[/codeblock]
func key_from_value(the_value: Variant) -> String:
	var the_index: int = find(the_value, DATA.MAIN)
	return data.key[the_index]
	
	
##Returns the weight in SuperArray at index. Does not skip over lock.
func weight(the_index: int = 0) -> float:
	return data.weight[the_index]
	
	
##Returns the weight in SuperArray for specific value. Skips over locks.
##[codeblock]
###Can be used to fetch a weight by value.
##my_weight = my_super.weight_from_value(my_var)
##[/codeblock]
func weight_from_value(the_value: Variant) -> float:
	var the_index: int = find(the_value, DATA.MAIN)
	return data.weight[the_index]
	
	
##Returns the locked state in SuperArray at index.
func locked(the_index: int = 0) -> bool:
	return data.lock[the_index]
	
	
##Returns the locked state in SuperArray for specific value.
func locked_value(the_value: Variant) -> bool:
	var the_index: int = find(the_value, DATA.MAIN)
	return data.lock[the_index]
	
	
##Returns the extra value in SuperArray at index. Does not skip over lock.
func extra(the_index: int = 0) -> Variant:
	return data.extra[the_index]
	
	
##Returns the extra value in SuperArray for specific value. Skips over locks.
##[codeblock]
###Can be used to fetch any custom data by value.
##my_var_path = my_super.extra_from_value(my_var)
##[/codeblock]
func extra_from_value(the_value: Variant) -> Variant:
	var the_index: int = find(the_value, DATA.MAIN)
	return data.extra[the_index]


##Returns the index of the first element in the array that causes method to return true, or -1 if there are none.
##Does not skip over locked elements. Callable argument is a SuperArray holding only the current element.
##[codeblock]
##func custom_finder(element: SuperArray):
##	if element.value().size < 5 and \
##	element.locked() and \
##	element.weight() > 1.0:
##		return true
##	return false
##
###Returns the first index of elements that has a value with a size property less than 5,
###that is locked and that has a weight higher than 1.0.
##var first_index: int = my_super.find_custom(custom_finder)
##[/codeblock]
func find_custom(method: Callable) -> int:
	for n in data.main.size():
		var temp_super: SuperArray = SuperArray.new()
		temp_super.append(data.main[n],data.weight[n],data.key[n],data.lock[n],data.extra[n])
		if method.call(temp_super):
			return n
	return -1


##Returns true if the array contains the given value. Skips over locks.
##Can target different data types.
func has(the_value: Variant, data_type: DATA = DATA.MAIN) -> bool:
	var the_index: int = find(the_value, data_type)
	if the_index == -1: return false
	return true
	
	
##Inserts a new element (the_value) at a given index (position) in the SuperArray. position should be between 0 and the array's size().
##Supports extra data with flexibly Typing.
##[codeblock]
##my_super.insert(5,my_var)
###Adds my_var to the Array at position 5 with default data.
##my_super.append(5,my_var,1.2,"important",true)
###Adds my_var to the Array at position 5 with a custom weight of 1.2, key of "important" and locked = true.
##[/codeblock]
func insert(position: int, the_value: Variant, ...extra_data: Array) -> void:
	data.main.insert(position, the_value)
	for item in extra_data:
		if typeof(item) == TYPE_FLOAT:
			data.weight.insert(position, item)
			extra_data.erase(item)
			break
	for item in extra_data:
		if typeof(item) == TYPE_STRING:
			data.key.insert(position, item)
			extra_data.erase(item)
			break
	for item in extra_data:
		if typeof(item) == TYPE_BOOL:
			data.lock.insert(position, item)
			extra_data.erase(item)
			break
	if !extra_data.is_empty():
		data.extra.insert(position, extra_data[0])
	_calc.insert_empty(position)
	_calc.reset_index_array()
	_calc.check()
	
	
##Returns true if the SuperArray is empty. See also size().
func is_empty() -> bool:
	return data.main.is_empty()
	
	
##Returns the maximum value contained in the SuperArray, if all elements can be compared. Otherwise, returns null. See also min().
func max() -> Variant:
	return data.main.max()
	
	
##Returns the maximum weight contained in the SuperArray. See also min_weight().
func max_weight() -> float:
	return Array(data.weight).max()
	
	
##Returns the maximum weighted value contained in the SuperArray. See also min_weighted_value().
##Skips over locks.
func max_weighted_value() -> Variant:
	var the_weight: float = Array(data.weight).max()
	return value_from(the_weight,DATA.WEIGHT)
	
	
##Returns the minimum value contained in the SuperArray, if all elements can be compared. Otherwise, returns null. See also max().
func min() -> Variant:
	return data.main.min()
	
	
##Returns the minimum weight contained in the SuperArray. See also max_weight().
func min_weight() -> float:
	return Array(data.weight).min()
	
	
##Returns the minimum weighted value contained in the SuperArray. See also max_weighted_value().
##Skips over locks.
func min_weighted_value() -> Variant:
	var the_weight: float = Array(data.weight).min()
	return value_from(the_weight,DATA.WEIGHT)
	
	
##Returns a random value from the SuperArray that is not locked.
##Returns null if the array is empty or locked. See also pop_random() and pick_random_weighted().
func pick_random() -> Variant:
	var temp_array: Array = filter_locked(false)
	if temp_array.is_empty(): return null
	return temp_array.pick_random()
	
	
##Similar to pick_random(), but also removes the element from the SuperArray.
##See also pop_random_weighted().
func pop_random() -> Variant:
	var the_value: Variant = pick_random()
	var the_index: int = find(the_value)
	remove_at(the_index)
	_calc.reset_index_array()
	_calc.check()
	return the_value
	
	
##Returns a random value from the SuperArray that is not locked, respecting the weight of each value.
##Returns null if the array is empty or locked. See also pop_random_weighted().
func pick_random_weighted() -> Variant:
	var temp_array: Array = filter_locked(false)
	if temp_array.is_empty(): return null
	var temp_weight_array: Array = []
	for item in temp_array:
		temp_weight_array.append(weight_from_value(item))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var rand_index: int = rng.rand_weighted(temp_weight_array)
	_calc.check()
	return temp_array[rand_index]
	
	
##Similar to pick_random_weighted(), but also removes the element from the SuperArray.
##See also pop_random().
func pop_random_weighted() -> Variant:
	var the_value: Variant = pick_random_weighted()
	var the_index: int = find(the_value)
	remove_at(the_index)
	_calc.check()
	return the_value
	
	
##Unlocks every element in the SuperArray. See also lock_all()
func unlock_all() -> void:
	for n in data.lock.size():
		data.lock[n] = false
	
	
##Locks every element in the SuperArray. See also unlock_all()
func lock_all() -> void:
	for n in data.lock.size():
		data.lock[n] = true
	
	
##Removes and returns the value of the SuperArray at index position.
##Does not skip locks. See also pop_key().
func pop_at(position: int) -> Variant:
	var the_value: Variant = data.main[position]
	remove_at(position)
	_calc.check()
	return the_value
	
	
##Removes and returns the value of the SuperArray with key.
##Does not skip locks. See also pop_at().
func pop_key(the_key: String) -> Variant:
	var the_value: Variant = value_from(the_key,DATA.KEY)
	var the_index: int = data.main.find(the_value)
	remove_at(the_index)
	_calc.check()
	return the_value
	
	
##Removes and returns the last value of the SuperArray.
##Skips over locks.
func pop_back() -> Variant:
	var the_index: int = -1
	for n in data.main.size():
		the_index = (n+1)*-1
		if !data.lock[the_index]: break
	var the_value: Variant = pop_at(the_index)
	return the_value
	

##Similar to append() and insert(), but at position 0.
func append_front(the_value: Variant, ...extra_data: Array) -> void:
	data.main.push_front(the_value)
	var the_size: int = data.main.size()-1
	for item in extra_data:
		match typeof(item):
			TYPE_FLOAT: if data.weight.size() == the_size: data.weight.push_front(item)
			TYPE_STRING: if data.key.size() == the_size: data.key.push_front(item)
			TYPE_BOOL: if data.lock.size() == the_size: data.lock.push_front(item)
			_: if data.extra.size() == the_size: data.extra.push_front(item)
	_calc.insert_empty(0)
	_calc.reset_index_array()
	
	
	
##Removes the element from the SuperArray at the given index (position). If the index is out of bounds, this method fails.
##If you need to return the removed element, use pop_at(). To remove an element by value, use erase() instead.
func remove_at(position: int) -> void:
	for data_type in data:
		data[data_type].remove_at(position)
	_calc.reset_index_array()
	
	
##Reverses the order of all elements in the array.
func reverse() -> void:
	for data_type in data:
		data[data_type].reverse()
	_calc.reset_index_array()
	
	
##Sets the value of the element at the given index to the given value.
##This will not change the size of the array, it only changes the value at an index already in the array.
##Does not support extra data types, for that see also set_key(), set_weight(), set_extra(), lock() and unlock().
##You can also set a value by key, see set_value_from_key().
func set_value(the_index: int, the_value: Variant) -> void:
	data.main.set(the_index, the_value)
	
	
##Sets the value of the element with given key to the given value.
##This will not change the size of the array, it only changes the value already in the array.
##Does not skip over locks. See also set_value().
func set_value_from_key(the_key: String, the_value: Variant) -> void:
	var the_index: int = data.keys.find(the_key)
	data.main.set(the_index, the_value)
	
	
##Sets the weight of the element at the given index to the given weight.
##This will not change the size of the array, it only changes the weight at an index already in the array.
##Does not support extra data types, for that see also set_key(), set_value(), set_extra(), lock() and unlock().
##You can also set a weight by value or change the weight by float, see set_weight_from_value() and change_weight().
func set_weight(the_index: int, the_weight: float) -> void:
	data.weight.set(the_index, the_weight)
	
	
##Sets the weight of the element with given value to the given weight.
##This will not change the size of the array, it only changes the weight already in the array.
##Does not skip over locks. See also set_weight().
func set_weight_from_value(the_value: Variant, the_weight: float) -> void:
	var the_index: int = data.main.find(the_value)
	data.weight.set(the_index, the_weight)
	
	
##Sets the key of the element at the given index to the given key.
##This will not change the size of the array, it only changes the key at an index already in the array.
##Does not support extra data types, for that see also set_weight(), set_value(), set_extra(), lock() and unlock().
##You can also set a weight by value, see set_key_from_value().
func set_key(the_index: int, the_key: String) -> void:
	data.key.set(the_index, the_key)
	
	
##Sets the key of the element with given value to the given weight.
##This will not change the size of the array, it only changes the key already in the array.
##Does not skip over locks. See also set_key().
func set_key_from_value(the_value: Variant, the_key: String) -> void:
	var the_index: int = data.main.find(the_value)
	data.key.set(the_index, the_key)
	
	
##Sets the extra value of the element at the given index to the given extra value.
##This will not change the size of the array, it only changes the extra value at an index already in the array.
##Does not support extra data types, for that see also set_weight(), set_value(), set_key(), lock() and unlock().
##You can also set a weight by value, see set_extra_from_value().
func set_extra(the_index: int, the_extra_value: Variant) -> void:
	data.extra.set(the_index, the_extra_value)
	
	
##Sets the extra value of the element with given value to the given weight.
##This will not change the size of the array, it only changes the extra value already in the array.
##Does not skip over locks. See also set_extra().
func set_extra_from_value(the_value: Variant, the_extra_value: Variant) -> void:
	var the_index: int = data.main.find(the_value)
	data.extra.set(the_index, the_extra_value)
	
	
##Locks a value. This disables it from being found in various functions and essentially "hides" it.
##See also lock_at(), unlock() and lock_switch().
func lock(the_value: Variant) -> void:
	var the_index: int = data.main.find(the_value)
	data.lock[the_index] = true
	
	
##Locks the value at given index. This disables it from being found in various functions and essentially "hides" it.
##See also lock(), unlock_at() and lock_switch().
func lock_at(the_index: int) -> void:
	data.lock[the_index] = true
	
	
##Unlocks a value. This enables it to found in various functions and essentially "shows" it.
##See also unlock_at(), lock() and lock_switch().
func unlock(the_value: Variant) -> void:
	var the_index: int = data.main.find(the_value)
	data.lock[the_index] = false
	
	
##Unlocks the value at given index. This enables it to be found in various functions and essentially "shows" it.
##See also unlock(), lock_at() and lock_switch().
func unlock_at(the_index: int) -> void:
	data.lock[the_index] = false
	
	
##Switches the lock on a value.
##See also unlock, lock() and lock_switch_at().
func lock_switch(the_value: Variant) -> void:
	var the_index: int = data.main.find(the_value)
	data.lock[the_index] = not data.lock[the_index]
	
	
##Switches the lock on the value at given index.
##See also unlock, lock() and lock_switch_at().
func lock_switch_at(the_index: int) -> void:
	data.lock[the_index] = not data.lock[the_index]
	
	
##Returns the number of elements in the SuperArray. Empty SuperArrays always return 0. See also is_empty().
func size() -> int:
	return data.main.size()
	
	
##Shuffles all elements of the array in a random order.
func shuffle() -> void:
	var index_dict: Dictionary = _calc.create_index_dict()
	data.main.shuffle()
	var new_index_array: Array = _calc.create_matching_index_array(index_dict)
	_calc.sort_matching_data(new_index_array)
	_calc.check()
	
	
##Sorts the main array in ascending order. The final order is dependent on the "less than" (<) comparison between values.
##See also sort_by_weight() and sort_custom().
func sort() -> void:
	var index_dict: Dictionary = _calc.create_index_dict()
	data.main.sort()
	var new_index_array: Array = _calc.create_matching_index_array(index_dict)
	_calc.sort_matching_data(new_index_array)
	_calc.check()
	
	
##Sorts the main array in ascending order. The final order is dependent on the "less than" (<) comparison between values.
##See also sort() and sort_custom().
func sort_by_weight() -> void:
	var index_dict: Dictionary = _calc.create_index_dict_weights()
	data.weight.sort()
	var new_index_array: Array = _calc.create_matching_index_array_weights(index_dict)
	_calc.sort_matching_data_weights(new_index_array)
	_calc.check()
	
	
##Returns a new SuperArray containing this SuperArray's elements, from index begin (inclusive) to end (exclusive).
#func slice(begin: int, end: int) -> SuperArray:
	#var new_super: SuperArray = SuperArray.new()
	#new_super.append(
		#data.main.slice(begin,end),
		#data.weight.slice(begin,end),
		#data.key.slice(begin,end),
		#data.lock.slice(begin,end),
		#data.extra.slice(begin,end)
	#)
	#_calc.reset_index_array()
	#_calc.check()
	#return new_super
	
	
##Sorts the array using a custom Callable. Similar to filter() and find_custom().
##Method is called as many times as necessary, receiving two SuperArray as arguments holding only the 2 elements it's comparing.
##The function should return true if the first element should be before the second one, otherwise it should return false.
##[codeblock]
##func custom_sorter(element_1: SuperArray, element_2: SuperArray):
##	if element_1.weight() < element_2.weight() and \
##	element_1.value().size > element_2.value().size:
##		return true
##	return false
##
###The custom sort will put values with a lower weight and bigger size property before others.
##my_super.custom_sort(custom_sorter)
##[/codeblock]
func sort_custom(method: Callable) -> void:
	var at_index: int = 0
	var loop: int = 0
	const max_loops: int = 100
	while at_index < data.main.size()-2 or loop < max_loops:
		for n: int in data.main.size()-1:
			loop += 1
			at_index = n
			var temp_super_1: SuperArray = SuperArray.new()
			var temp_super_2: SuperArray = SuperArray.new()
			temp_super_1.append(data.main[n],data.weight[n],data.key[n],data.lock[n],data.extra[n])
			temp_super_2.append(data.main[n+1],data.weight[n+1],data.key[n+1],data.lock[n+1],data.extra[n+1])
			if !method.call(temp_super_1, temp_super_2):
				swap_at_index(n,n+1)
				break
	_calc.check()
	_calc.reset_index_array()
	
	
##Calls the given Callable on each element in the SuperArray to adjust the weight to the returned float.
##Does not skip over locked elements. Callable argument is a SuperArray holding only the current element.
##[codeblock]
##func custom_weights(element: SuperArray):
##	if element.key() == "higher": return element.weight() + 0.1
##	if element.key() == "lower": return element.weight() - 0.1
##	if element.key() == "stable": return 1.0
##	return element.weight()
##
###The weights with key "higher" are increased by 0.1, "lower" decreased by 0.1, "stable" returns to 1.0.
##my_super.set_weight_custom(custom_weights)
##[/codeblock]
func set_weight_custom(method: Callable) -> void:
	for n: int in data.main.size():
		var temp_super: SuperArray = SuperArray.new()
		temp_super.append(data.main[n],data.weight[n],data.key[n],data.lock[n],data.extra[n])
		data.weight[n] = method.call(temp_super)
	_calc.check()
	
	
##Stores a reference in memory to the current SuperArray. This keeps track of all the current values and their order.
##Does NOT duplicate the SuperArray values, so will return null values if values have deteriorated.
##Also see load_reference().
func store_reference(ref_key: String) -> void:
	var new_super: SuperArray = SuperArray.new()
	for n in data.main.size():
		new_super.append(data.main[n],data.weight[n],
		data.key[n],data.lock[n],data.extra[n])
	_calc.reset_index_array()
	_refs[ref_key] = new_super.data
	
	
##Loads a reference from memory to the current SuperArray, deleting the current SuperArray.
##Does NOT duplicate the SuperArray from memory, so will return changes to the values if loaded in again later.
##To changed that, enable duplicate. Also see store_reference().
func load_reference(ref_key: String, duplicate: bool = false) -> void:
	if !duplicate: data = _refs[ref_key]
	else: data = _refs[ref_key].duplicate()
	_calc.check()
	
	
##Swaps 2 elements in the SuperArray at index 1 and index 2, without changing the size of the Arrays.
func swap_at_index(index_1: int, index_2: int) -> void:
	var temp
	for data_type in data:
		temp = data[data_type][index_1]
		data[data_type][index_1] = data[data_type][index_2]
		data[data_type][index_2] = temp
	_calc.reset_index_array()
	_calc.check()
	
	
##Moves an element in the SuperArray from original index to final index.
func move_to_index(original_index: int, final_index: int) -> void:
	for data_type in data:
		if original_index > final_index:
			data[data_type].insert(final_index, data[data_type][original_index])
			data[data_type].remove_at(original_index+1)
		else:
			data[data_type].insert(final_index+1, data[data_type][original_index])
			data[data_type].remove_at(original_index)
	_calc.reset_index_array()
	_calc.check()
	
	
##Bakes a custom callable into this SuperArray. Used to make repetitive tasks easier.
##Also useful to keep code cleaner without making new funcs. Call using bake("name").
##[codeblock]
##my_super.bake("make_bigger", func(my_super):
##		for item in my_super:
##			if item.locked(): continue
##			item.value().size += 3
##			print(item.key())
##	)
###When called, will increase the size of all unlocked elements by 3 and print their keys.
##my_super.baked("make_bigger")
##[/codeblock]
func bake(callable_name: String, function: Callable,...args: Array) -> void:
	var new_callable: Callable = function
	for item in args:
		new_callable = new_callable.bind(item)
	_baked[callable_name] = new_callable
	
	
##Calls a baked-in function. Takes optional arguments. See also bake().
func baked(baked_name: String, ...args: Array) -> void:
	if args.is_empty(): _baked[baked_name].call()
	else: 
		var temp_callable = _baked[baked_name]
		for item in args:
			temp_callable = temp_callable.bind(item)
		temp_callable.call()
	_calc.check()
	
	
##Should only be used while looping in super_values, returns the current index.
func index() -> int:
	return data.index[0]
	
	
##Changes the weight of the element at the given index with the given weight.
##This will not change the size of the array, it only changes the weight at an index already in the array.
##You can also change a weight by value or set the weight to a float, see change_weight_from_value() and set_weight().
func change_weight(the_index: int, amount: float) -> void:
	data.weight.set(the_index, weight(the_index) + amount)
	
	
##Changes the weight of the element with given value with the given weight.
##This will not change the size of the array, it only changes the weight already in the array.
##Does not skip over locks. See also change_weight().
func change_weight_from_value(the_value: Variant, amount: float) -> void:
	var the_index: int = data.main.find(the_value)
	data.weight.set(the_index, weight(the_index) + amount)
	
	
var _iter_index: int = 0
	
	
func _iter_init(iter):
	_iter_index = 0
	return !data.main.is_empty()
	
	
func _iter_get(iter):
	var temp_super: SuperArray = SuperArray.new()
	temp_super.append(data.main[_iter_index],data.weight[_iter_index],data.key[_iter_index],
	data.lock[_iter_index],data.extra[_iter_index])
	temp_super.data.index = [data.index[_iter_index]]
	iter = temp_super
	return iter
		
		
func _iter_next(iter):
	_iter_index += 1
	return _iter_index < data.main.size()
		
		
#______________________________________________________________________________
	
	
	
	
class SuperArray_calc:
	
	var data: Dictionary
	
	func _init(super_array: SuperArray) -> void:
		data = super_array.data

	func fill_empty() -> void:
		while data.index.size() < data.main.size():
			data.index.append(data.index.size())
		while data.weight.size() < data.main.size():
			data.weight.append(1.0)
		while data.lock.size() < data.main.size():
			data.lock.append(false)
		while data.key.size() < data.main.size():
			data.key.append("")
		while data.extra.size() < data.main.size():
			data.extra.append(null)

	func insert_empty(position: int) -> void:
		if data.index.size() < data.main.size():
			data.index.insert(position,data.index.size())
		if data.weight.size() < data.main.size():
			data.weight.insert(position,1.0)
		if data.lock.size() < data.main.size():
			data.lock.insert(position,false)
		if data.key.size() < data.main.size():
			data.key.insert(position,"")
		if data.extra.size() < data.main.size():
			data.extra.insert(position,null)

	func reset_index_array() -> void:
		for n in data.index.size():
			if data.index[n] != n: data.index[n] = n

	func create_index_dict() -> Dictionary:
		var dict: Dictionary
		for n in data.main.size():
			dict[data.main[n]] = n
		return dict
		
	func create_index_dict_weights() -> Dictionary:
		var dict: Dictionary
		for n in data.weight.size():
			dict[data.weight[n]] = n
		return dict
		
	func create_matching_index_array(dict: Dictionary) -> Array:
		var index_array: Array = []
		for n in data.main.size():
			index_array.append(dict[data.main[n]])
			dict.erase(data.main[n])
		return index_array
		
	func create_matching_index_array_weights(dict: Dictionary) -> Array:
		var index_array: Array = []
		for n in data.weight.size():
			index_array.append(dict[data.weight[n]])
			dict.erase(data.weight[n])
		return index_array

	func sort_matching_data(new_index_array: Array) -> void:
		var new_key: PackedStringArray = []
		var new_weight: PackedFloat64Array = []
		var new_lock: Array[bool] = []
		var new_extra: Array = []
		for new_index in new_index_array:
			new_key.append(data.key[new_index])
			new_weight.append(data.weight[new_index])
			new_lock.append(data.lock[new_index])
			new_extra.append(data.extra[new_index])
		data.key = new_key
		data.weight = new_weight
		data.lock = new_lock
		data.extra = new_extra
		
	func sort_matching_data_weights(new_index_array: Array) -> void:
		var new_key: PackedStringArray = []
		var new_main: Array = []
		var new_lock: Array[bool] = []
		var new_extra: Array = []
		for new_index in new_index_array:
			new_key.append(data.key[new_index])
			new_main.append(data.main[new_index])
			new_lock.append(data.lock[new_index])
			new_extra.append(data.extra[new_index])
		data.key = new_key
		data.main = new_main
		data.lock = new_lock
		data.extra = new_extra
	
	func check() -> void:
		var the_size: int = data.main.size()
		assert(the_size == data.index.size())
		assert(the_size == data.key.size())
		assert(the_size == data.weight.size())
		assert(the_size == data.lock.size())
		assert(the_size == data.extra.size())
