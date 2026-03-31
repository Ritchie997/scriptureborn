extends CharacterBody2D
## Player.gd - Основной контроллер игрока
## Обрабатывает движение, поворот к курсору и интеграцию с крюком и оружием

@export_group("Movement Parameters")
@export var speed: float = 300.0
@export var acceleration: float = 15.0
@export var friction: float = 20.0

@export_group("References")
@onready var grappling_hook: Node2D = $GrapplingHook
@onready var weapon_spawn: Marker2D = $WeaponSpawn
@onready var visual: ColorRect = $Visual

# Вектор ввода направления
var input_direction: Vector2 = Vector2.ZERO

# Сигналы для связи с другими системами
signal hook_fired(position: Vector2)
signal hook_retracted()
signal projectile_fired(spawn_position: Vector2, direction: Vector2)
signal player_died()

# Состояния игрока
enum PlayerState { IDLE, MOVING, GRAPPLED }
var current_state: PlayerState = PlayerState.IDLE


func _ready() -> void:
	# Инициализация ссылок на дочерние ноды
	_setup_signals()
	

func _setup_signals() -> void:
	# Подключение сигналов от крюка
	if grappling_hook:
		grappling_hook.connect("hook_attached", _on_hook_attached)
		grappling_hook.connect("hook_detached", _on_hook_detached)


func _physics_process(delta: float) -> void:
	_handle_input()
	_apply_movement(delta)
	_rotate_towards_mouse()
	
	# Применение гравитации от крюка если он зацеплен
	_apply_grapple_force(delta)
	
	move_and_slide()
	_update_state()


func _handle_input() -> void:
	# Получение ввода WASD
	input_direction = Vector2.ZERO
	input_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# Нормализация диагонального движения
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()
	
	# Обработка ввода для крюка (ЛКМ)
	if Input.is_action_just_pressed("left_click"):
		_fire_grappling_hook()
	
	# Обработка ввода для выстрела (ПКМ)
	if Input.is_action_just_pressed("right_click"):
		_fire_weapon()
	
	# Отцепка крюка (Пробел или повторное ЛКМ если уже зацеплен)
	if Input.is_action_just_pressed("ui_space") or \
	   (Input.is_action_just_pressed("left_click") and current_state == PlayerState.GRAPPLED):
		_detach_hook()


func _apply_movement(delta: float) -> void:
	# Плавное ускорение и торможение
	if input_direction != Vector2.ZERO:
		# Ускорение в направлении ввода
		velocity = velocity.lerp(input_direction * speed, acceleration * delta)
	else:
		# Торможение при отсутствии ввода
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)


func _rotate_towards_mouse() -> void:
	# Поворот игрока лицом к курсору мыши
	var mouse_position: Vector2 = get_global_mouse_position()
	var direction_to_mouse: Vector2 = (mouse_position - global_position).normalized()
	
	# Используем look_at для поворота всей ноды игрока
	look_at(mouse_position)
	
	# Корректировка визуала (если нужно)
	if visual:
		visual.rotation = 0  # Сбрасываем вращение визуала если нужно


func _apply_grapple_force(delta: float) -> void:
	# Применение силы притяжения от крюка
	if current_state == PlayerState.GRAPPLED and grappling_hook:
		var grapple_force: Vector2 = grappling_hook.get_grapple_force(global_position)
		if grapple_force != Vector2.ZERO:
			velocity += grapple_force * delta


func _fire_grappling_hook() -> void:
	# Запуск крюка в сторону курсора
	if grappling_hook and current_state != PlayerState.GRAPPLED:
		var mouse_position: Vector2 = get_global_mouse_position()
		var direction: Vector2 = (mouse_position - global_position).normalized()
		grappling_hook.fire_hook(global_position, direction)
		hook_fired.emit(mouse_position)


func _fire_weapon() -> void:
	# Выстрел снарядом в сторону курсора
	var mouse_position: Vector2 = get_global_mouse_position()
	var spawn_position: Vector2 = weapon_spawn.global_position if weapon_spawn else global_position
	var direction: Vector2 = (mouse_position - spawn_position).normalized()
	
	# Испускаем сигнал для менеджера снарядов
	projectile_fired.emit(spawn_position, direction)


func _detach_hook() -> void:
	# Отцепка крюка
	if grappling_hook:
		grappling_hook.detach_hook()
		hook_retracted.emit()


func _update_state() -> void:
	# Обновление состояния игрока
	if current_state == PlayerState.GRAPPLED:
		return
	
	if input_direction != Vector2.ZERO:
		current_state = PlayerState.MOVING
	else:
		current_state = PlayerState.IDLE


# Обработчики сигналов от крюка
func _on_hook_attached() -> void:
	current_state = PlayerState.GRAPPLED


func _on_hook_detached() -> void:
	current_state = PlayerState.IDLE


# Публичные методы для внешнего доступа
func get_player_position() -> Vector2:
	return global_position


func is_grappled() -> bool:
	return current_state == PlayerState.GRAPPLED


func take_damage(amount: float) -> void:
	# Заглушка для получения урона
	print("Player took damage: ", amount)
	player_died.emit()
