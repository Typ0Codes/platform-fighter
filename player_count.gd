extends HSlider



func _ready() -> void:
	pass 



func _process(delta: float) -> void:
	$Label.text = "Player Count: " + str(value)


func _on_changed() -> void:
	$Label.text = "Player Count: " + str(value)
