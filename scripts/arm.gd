extends Node2D

@export var upper_length: float:
	set(value):
		$Elbow.position.x = value
		upper_length = value
@export var lower_length: float

@export var target: Node2D

# whether the arm is going clockwise or counter clockwise
var turn_direction := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var target_distance := global_position.distance_to(target.global_position)
	target_distance = clamp(target_distance, abs(upper_length - lower_length), lower_length + upper_length)

	var target_angle := global_position.angle_to_point(target.global_position)

	self.rotation = _angle_in_triangle(upper_length, target_distance, lower_length) * turn_direction + target_angle

	$Elbow.rotation = PI + _angle_in_triangle(upper_length, lower_length, target_distance) * turn_direction

	# adds some variation by flipping the direction the elbow will turn when it is not noticeable
	if is_zero_approx(angle_difference($Elbow.rotation, PI)) or is_zero_approx(angle_difference($Elbow.rotation, 0)):
		turn_direction *= -1


# returns the angle, in radians, of the angle opposite to c in a triangle defined by
# side lengths a, b, and c.
# google law of cosines
# will get mad at you if it is not a real triangle
func _angle_in_triangle(a: float, b: float, c: float) -> float:
	return acos((a ** 2 + b ** 2 - c ** 2) / (2 * a * b))
