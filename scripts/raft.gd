extends CharacterBody2D

var mouse_delta := Vector2.ZERO
var mouse_pos := Vector2.ZERO

@export var sensitivity := 1.0
@export var dragging_sensitivity := 0.25 # sensetivity when mouse is down
@export var drag := 5.0
@export var raft_mass := 2.5 # how hard it is to move the raft when pushing against walls
@export var max_paddle_distance := 100.0
@export var min_paddle_distance := 10.0

@onready var paddle : CharacterBody2D = $Paddle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# makes sure the paddle doesn't go too far by clamping the mousedelta within the acceptable donut
	var future_paddle_pos = paddle.position
	future_paddle_pos += mouse_delta
	future_paddle_pos = future_paddle_pos.normalized() * clamp(future_paddle_pos.length(), min_paddle_distance, max_paddle_distance)
	mouse_delta = future_paddle_pos - paddle.position

	# lmb pressed
	if Input.is_action_pressed("drop_paddle"):
		$Paddle/Sprite2D.modulate = Color.GRAY
		# moves the raft in the opposite direction as the mouse movment
		velocity = -mouse_delta / delta
		_move_and_slide_just_raft()
	else:
		$Paddle/Sprite2D.modulate = Color.WHITE
		# move the paddle
		paddle.velocity = mouse_delta / delta
		paddle.move_and_slide()
		# if the paddle hits a wall, this loop will run for each collision
		for i in paddle.get_slide_collision_count():
			var collision: KinematicCollision2D = paddle.get_slide_collision(i)
			# finds the velocity that the raft should be, based on how much remaining collision
			# there was when the paddle hit the wall
			var collision_velocity := -collision.get_remainder() / delta / raft_mass
			# does some vector math to combine the current and collision velocities
			if velocity.dot(collision_velocity.normalized()) < collision_velocity.length():
				velocity = (
						collision_velocity + 
						velocity.cross(collision_velocity.normalized()) * 
						collision_velocity.normalized().orthogonal()
				)
		# applies drag
		velocity = velocity * exp(-drag * delta)
		_move_and_slide_just_raft()

	mouse_delta = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += (
				event.relative * 
				(dragging_sensitivity if Input.is_action_pressed("drop_paddle") else sensitivity)
		)


# moves the raft but not the paddle
func _move_and_slide_just_raft() -> void:
	var paddle_transform := paddle.global_transform
	move_and_slide()
	paddle.global_transform = paddle_transform
