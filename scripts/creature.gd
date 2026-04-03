extends GameObject
class_name Creature

# Health system
@export var max_health: float = 3.0
var health: float

# AI state (override in subclasses)
enum State { IDLE, PATROL, FLEE, DEAD }
var state: State = State.PATROL

# Sleep optimization
var is_awake: bool = true

# Who last hit us (used for flee direction)
var last_attacker: Node2D = null

signal died

func _ready():
	super._ready()
	health = max_health
	category = "fauna"
	
	# Connect VisibleOnScreenNotifier2D if present
	var notifier = get_node_or_null("VisibleOnScreenNotifier2D")
	if notifier:
		notifier.screen_entered.connect(_on_screen_entered)
		notifier.screen_exited.connect(_on_screen_exited)

func _physics_process(delta):
	if not is_awake or state == State.DEAD:
		return
	_update_ai(delta)

func _update_ai(_delta: float):
	"""Override in subclasses to implement movement/behavior per state."""
	pass

func take_damage(amount: float, attacker: Node2D = null):
	if state == State.DEAD:
		return
	health -= amount
	last_attacker = attacker
	if health <= 0:
		die()
	else:
		state = State.FLEE

func die():
	state = State.DEAD
	died.emit()
	_on_death()

func _on_death():
	"""Override in subclasses for death behavior (drop loot, remove, etc.)."""
	queue_free()

func activate_use(_target_action: String, _efficiency: float = 1.0):
	"""Override GameObject.activate_use — weapons deal damage instead of harvesting."""
	player = get_tree().get_first_node_in_group("player")
	take_damage(1.0, player)

func use_finished_callback():
	"""Override — creatures handle death in die(), not here."""
	pass

func is_interactable() -> bool:
	return state != State.DEAD

func _on_screen_entered():
	is_awake = true

func _on_screen_exited():
	is_awake = false
