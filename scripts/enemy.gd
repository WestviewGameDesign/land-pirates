@icon("res://assets/enemy_flag.svg")
extends CharacterBody2D

signal activate()
signal deactivate()

@export var mode_indicator: Node2D

var is_ragdoll := false:
	get:
		return is_ragdoll
	set(v):
		if mode_indicator != null:
			mode_indicator.self_modulate = (
				Color(1.0, 0.5, 0.5) if v else Color(0.5, 1.0, 0.5)
			)
		if v:
			deactivate.emit()
		else:
			activate.emit()
		is_ragdoll = v
var is_ragdoll_temporary := false
var _temp_fc: int = 0

@export var weight: float = 1.0
@export var baseHealth: float = 20.0

var health := baseHealth

@export_group("Temp. Ragdoll Options")

## Linear damping values for stumbling.
@export var linear_damp_alive: float = 5.0

## Angular damping values for stumbling.
@export var angular_damp_alive: float = 4.0

## When stumbling (temporarily in a ragdoll), return normal operation if
## traveling at this speed or less
@export var max_resume_speed: float = 0.2

@onready var _resume_squared := pow(max_resume_speed, 2)

@export_group("Ragdoll Options")

## Linear damping value for full ragdoll (i.e. dead)
@export var linear_damp: float = 1.25
## Angular damping value for full ragdoll (i.e. dead)
@export var angular_damp: float = 1.0

var twn: Tween

func _activate():
	print("ACTIVATING")
	if twn:
		twn.kill()
	twn = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	var center := (get_viewport().size as Vector2i) / 2
	twn.tween_property(self, "position", Vector2(center), 0.2)
	twn.tween_property(self, "rotation", 0.0, 0.2)


func _deactivate():
	if twn:
		twn.kill()


# Called when the node enters the scene tree for the first time.
func _ready():
	activate.connect(_activate)
	deactivate.connect(_deactivate)
	_activate()


var _timer := 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func get_ragdoll() -> RigidBody2D:
	if is_ragdoll:
		return get_parent() as RigidBody2D
	return null


## Become a ragdoll. This will parent the current node to a RigidBody2D.
func ragdoll(linear: float, angular: float) -> RigidBody2D:
	if is_ragdoll:
		return get_ragdoll()
	is_ragdoll = true
	is_ragdoll_temporary = false
	var rb2 := RigidBody2D.new()
	rb2.global_position = global_position
	rb2.gravity_scale = 0.0  # we're looking from above so there's no gravity
	rb2.linear_damp = linear
	rb2.angular_damp = angular
	
	add_sibling(rb2)
	
	await get_tree().process_frame  # give tree time to update

	# Locate collision shapes and polygons that also need to be re-parented
	var shape_childs := find_children("*", "CollisionShape2D", false, false)
	print(shape_childs)
	for child in shape_childs:
		child.reparent(rb2)
	var poly_childs := find_children("*", "CollisionPolygon2D", false, false)
	print(poly_childs)
	for child in poly_childs:
		child.reparent(rb2)
		
	reparent(rb2)
	
	return rb2

## Undoes the actions of ragdoll().
func unragdoll():
	if not is_ragdoll:
		return
	var rb := get_ragdoll()
	is_ragdoll = false
	# Move any existing children
	for child in rb.get_children():
		if child == self:
			continue
		# take over the child
		child.reparent(self)
	# Swap out the ragdoll
	reparent(rb.get_parent())
	rb.queue_free()


func _process_temp_ragdoll():
	if _temp_fc > 0:
		_temp_fc -= 1
		return
	# Get the current velocity.
	var rb := get_ragdoll()
	if rb == null:
		return
	if rb.linear_velocity.length_squared() <= _resume_squared:
		# Return to normal operation.
		await unragdoll()
		print("Temporary rag-doll cancelled")


func _physics_process(delta):
	if is_ragdoll:
		if is_ragdoll_temporary:
			_process_temp_ragdoll()


func ragdoll_and_wait(linear: float, angular: float) -> RigidBody2D:
	var need_await := not is_ragdoll
	var response := await ragdoll(linear, angular)
	if need_await:
		# the RigidBody needs to settle for a few frames before it can be
		# launched correctly
		await get_tree().physics_frame
		await get_tree().physics_frame
	return response


func yeet(force: Vector2, torq: float, temporary: bool = false):
	var launchable := await ragdoll_and_wait(
		linear_damp_alive if temporary else linear_damp,
		angular_damp_alive if temporary else angular_damp
	)
	is_ragdoll_temporary = temporary
	_temp_fc = 3
	launchable.apply_impulse(force)
	launchable.apply_torque_impulse(torq)
	


func _input(event: InputEvent):
	if event.is_action_pressed("debug_key2"):
		unragdoll()
	elif event.is_action_pressed("debug_key"):
		health -= 1
		var center: Vector2i = get_viewport().size as Vector2i
		var base_angle := -PI/2
		var variance := randf_range(-(PI/8.0), PI/8.0)
		var scaling := randf_range(800.0, 1500.0)
		yeet(
			Vector2.from_angle(base_angle + variance) * scaling,
			randf_range(-10000, 10000),
			health > 0  # Temporary
		)
