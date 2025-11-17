##Static Class, can't instantiate.
##
##Used for debugging and understanding complex Dictionaries / Arrays.
##Simply call [code]Deconstruct.go(my_var)[/code] in your script at runtime, output is in the terminal.
@abstract
class_name Deconstruct

static var offset: int = -1

##Currently accepts Array and Dictionary. Use the Layers argument to specify how deep the deconstruct goes.
##This is simply to minimize the output when things are very nested.
static func go(input: Variant, layers: int = 10):
	match typeof(input):
		TYPE_DICTIONARY:
			_init_deconstruct()
			_deconstruct_dict(input, layers+1)
			print_rich("[hr]")
		TYPE_ARRAY:
			_init_deconstruct()
			_deconstruct_array(input, layers)
			print_rich("[hr]")
		_:
			push_error("Cannot deconstruct ",input," of type ",type_string(typeof(input)))

static func _init_deconstruct():
	offset = -1
	print_rich("[hr]")
	print_rich("[color=SKY_BLUE]■ : Dictionary Key[/color]")
	print_rich("[color=GREEN_YELLOW]■ : Array Value[/color]")
	print_rich("[color=CORNSILK]■ : Dictionary Value[/color]")
	print_rich("[hr]")

static func _deconstruct_dict(dict, layers):
	if layers <= 0: return
	offset += 1
	layers -= 1
	
	for item in dict.keys():
		match typeof(dict[item]):
			TYPE_DICTIONARY:
				print_rich("[color=SKY_BLUE]%s﹂▶ [b]%s[/b] (%s)[/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))])
				_deconstruct_dict(dict[item], layers)
			TYPE_ARRAY:
				print_rich("[color=SKY_BLUE]%s﹂▶ [b]%s[/b] (%s)[/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))])
				_deconstruct_array(dict[item], layers)
			_:
				if layers <= 0: continue
				print_rich("[color=SKY_BLUE]%s﹂▶ [b]%s[/b] (%s) : [/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))] +
					"[color=CORNSILK][i]%s[/i] (%s)[/color]"%[str(dict[item]),type_string(typeof(dict[item]))])
	offset -= 1
	layers += 1

static func _deconstruct_array(array, layers):
	if layers <= 0: return
	offset += 1
	layers -= 1
	
	for item in array:
		match typeof(item):
			TYPE_DICTIONARY:
				_deconstruct_dict(item, layers)
			TYPE_ARRAY:
				_deconstruct_array(item, layers)
			_:
				if layers <= 0: continue
				print_rich("[color=GREEN_YELLOW]%s﹂▶ [i]%s[/i] (%s)[/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))])
	offset -= 1
	layers += 1
