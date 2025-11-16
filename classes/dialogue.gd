##Simple way to turn a RichTextLabel into a Dialogue box.
##Introduces 3 main functions and 2 signals:
##[codeblock]
##Display(String) #display dialogue string
##Buffer(PackedStringArray) #load a dialogue buffer
##Next() #display next dialogue string in buffer
##
##func _on_update(code: error_code): #called when dialogue updates
##	print(code)
##
##func _on_end(): #called when end of buffer is reached
##	queue_free()
##[/codeblock]

extends RichTextLabel

class_name Dialogue

##Emits an update whenever the [code]error_code[/code] gets updated. Relevant if you need to track
##the status of the dialogue text.
signal Update(code: error_code)
##Emits when the end of the dialogue buffer is reached. Can be used to close the Dialogue box.
signal End

##Possible error codes while processing dialogue text.
enum error_code {
	DONE, ##Full dialogue cycle finished.
	IN_ANIMATION, ##Currently in an animation cycle for the dialogue text.
	START, ##Starting the dialogue cycle.
	ERROR, ##Something went wrong.
	END ##End of dialogue buffer is reached
}

var current_code: error_code:
	set(value):
		current_code = value
		Update.emit(current_code)
		if current_code == error_code.END:
			End.emit()

##Can take any Dictionary to format the Dialogue strings.
var format_dictionary: Dictionary = {}

##Array of text that gets loaded into the Dialogue. Use func [code]Buffer(new_dialogue_buffer)[/code]
##instead of accessing this directly (unless you need to read data from it).
var dialogue_buffer: PackedStringArray = []

@export var animated_text: bool = false
@export_range(0.1,3.0,0.1,"or_greater") var animation_speed: float = 0.5
##Should the next dialogue text wait for the current animation to finish.
@export var await_animation: bool = false

##Pass in a string of text to display in the Dialogue.
##[codeblock]
##Display("Hello World")
###Loads "Hello World" in the Dialogue using the current settings.
##[/codeblock]
func Display(new_dialogue_text: String) -> error_code:
	if await_animation and current_code == error_code.IN_ANIMATION:
		return current_code
	
	clear()
	current_code = error_code.START
	new_dialogue_text.format(format_dictionary)
	
	if !animated_text:
		text = new_dialogue_text
	else:
		visible_ratio = 0.0
		text = new_dialogue_text
		current_code = error_code.IN_ANIMATION
		for characters_progress in 101:
			visible_ratio = float(characters_progress)/100
			await get_tree().create_timer(animation_speed/100,false).timeout
	
	current_code = error_code.DONE
	return current_code

##Loads in a buffer of text for the Dialogue, gets triggered using Next().
##Accepts PackedStringArray, Array, String. A normal String gets separated by every new line.
##Can choose to override the existing buffer or append to it.
##[codeblock]
##var new_buffer: PackedStringArray = ["Hello world!","How are you?"]
##var new_buffer: Array = ["Hello world!","How are you?"]
##var new_buffer: String = "Hello world!\nHow are you?"
##
##Buffer(new_buffer)
func Buffer(new_dialogue_buffer: Variant, append_to_existing: bool = true) -> error_code:
	if !append_to_existing: dialogue_buffer.clear()
	match typeof(new_dialogue_buffer):
		
		TYPE_PACKED_STRING_ARRAY:
			dialogue_buffer += new_dialogue_buffer.duplicate()
		
		TYPE_ARRAY:
			for item in new_dialogue_buffer:
				dialogue_buffer.append(str(item))
		
		TYPE_STRING:
			var split_buffer: PackedStringArray = new_dialogue_buffer.split("\n",false)
			dialogue_buffer += split_buffer
		
		_: 
			push_error("No valid variable gives for the dialogue buffer. Recieved: ",
				type_string(typeof(new_dialogue_buffer)),": ",new_dialogue_buffer)
			return error_code.ERROR
		
	return error_code.DONE

##Displays the next line of dialogue in the buffer.
func Next() -> error_code:
	if await_animation and current_code == error_code.IN_ANIMATION:
		return current_code
	if dialogue_buffer.is_empty():
		current_code = error_code.END
		return current_code
	
	var next_dialogue_string: String = dialogue_buffer[0]
	dialogue_buffer.remove_at(0)
	Display(next_dialogue_string)
		
	return error_code.DONE
