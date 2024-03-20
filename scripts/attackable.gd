@tool
class_name Attackable
extends Node2D


# TODO: switch 'from' to a AttackSource type or something
func accept(from: Node, force: Vector2, src_weight: float, damage: int):
	push_error("Attackable$_accept: no implementation was defined.")


func _refresh_tree():
	update_configuration_warnings()


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().tree_changed.connect(_refresh_tree)
	if Engine.is_editor_hint():
		return
	pass # Replace with function body.


var hitbox: Area2D = null


func _get_configuration_warnings():
	var warns: Array[String] = []
	hitbox = null
	var named_hitbox := find_child("hitbox", true)
	if named_hitbox == null or not (named_hitbox is Area2D):
		if named_hitbox != null:
			warns.append("Node named \"hitbox\" is not Area2D.")
		var auto_hitbox: Array[Node] = find_children("*", "Area2D", false)
		if auto_hitbox.size() == 0:
			warns.append("No hitbox detected.\nAdd an Area2D to this node or name an existing Area2D \"hitbox\".")
		elif auto_hitbox.size() > 1:
			warns.append("Could not determine which Area2D is the hitbox implicitly.\nName the hitbox \"hitbox\".")
		else:
			hitbox = auto_hitbox[0] as Area2D
	else:
		hitbox = named_hitbox
	
	return warns

func _editor_process(delta: float) -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_editor_process(delta)
		return
	pass
