extends Area2D
## Projectile.gd - Снаряд с механикой возврата (бумеранг)
## Летит в цель, при отсутствии попадания разворачивается и возвращается к игроку

@export_group("Projectile Parameters")
@export var speed: float = 600.0
@export var return_speed: float = 800.0
@export var max_flight_time: float = 1.5  # Время полета до возврата
@export var damage: float = 25.0

@export_group("Visual")
@export var trail_color: Color = Color(1.0, 0.8, 0.2)  # Золотистый цвет
@export var trail_width: float = 4.0

# Ссылки на ноды
@onready var trail: Line2D = $Trail
@onready var sprite: ColorRect = $Sprite

# Состояния снаряда
enum ProjectileState { FLYING, RETURNING, HIT }
var current_state: ProjectileState = ProjectileState.FLYING

# Векторы и таймеры
var direction: Vector2 = Vector2.RIGHT
var player_reference: CharacterBody2D
var flight_timer: float = 0.0
var has_returned: bool = false

# Сигналы
signal projectile_hit(position: Vector2, damage: float)
signal projectile_returned()


func _ready() -> void:
	# Получение ссылки на игрока через группу или поиск
	player_reference = get_node_or_null("../../Player") as CharacterBody2D
	
	# Настройка коллизий
	collision_layer = 4  # Layer 4: Projectiles
	collision_mask = 2   # Mask 2: Walls/Obstacles
	
	# Подключение сигнала столкновения
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Настройка визуала
	_setup_visuals()


func _setup_visuals() -> void:
	# Настройка трейла (следа)
	if trail:
		trail.width = trail_width
		trail.default_color = trail_color
		trail.joint_mode = Line2D.LINE_JOINT_ROUND


func _physics_process(delta: float) -> void:
	match current_state:
		ProjectileState.FLYING:
			_update_flying(delta)
		ProjectileState.RETURNING:
			_update_returning(delta)
		ProjectileState.HIT:
			_update_hit(delta)
	
	# Обновление визуального следа
	_update_trail()


func _update_flying(delta: float) -> void:
	# Полет снаряда вперед
	position += direction * speed * delta
	
	# Увеличение таймера полета
	flight_timer += delta
	
	# Поворот снаряда по направлению движения
	rotation = direction.angle()
	
	# Проверка времени полета для возврата
	if flight_timer >= max_flight_time and not has_returned:
		_start_return()


func _update_returning(delta: float) -> void:
	# Возврат к игроку
	if not player_reference:
		return
	
	var direction_to_player: Vector2 = (player_reference.global_position - global_position).normalized()
	position += direction_to_player * return_speed * delta
	
	# Плавный поворот к игроку
	var target_rotation: float = direction_to_player.angle()
	rotation = lerp_angle(rotation, target_rotation, 10.0 * delta)
	
	# Проверка достижения игрока
	var distance_to_player: float = global_position.distance_to(player_reference.global_position)
	if distance_to_player < 30.0:
		_on_return_complete()


func _update_hit(delta: float) -> void:
	# Обработка состояния попадания (затухание)
	modulate.a = lerp(modulate.a, 0.0, 5.0 * delta)
	
	if modulate.a < 0.1:
		queue_free()


func _update_trail() -> void:
	# Добавление точки в след
	if trail:
		var new_point: Vector2 = position
		trail.add_point(new_point)
		
		# Ограничение длины следа
		if trail.get_point_count() > 20:
			trail.remove_point(0)


func _start_return() -> void:
	# Начало возврата снаряда
	current_state = ProjectileState.RETURNING
	has_returned = true
	
	# Визуальный эффект разворота
	_create_turn_effect()


func _create_turn_effect() -> void:
	# Создание визуального эффекта при развороте
	# Можно добавить частицы или изменение цвета
	modulate = Color(1.0, 1.0, 0.5)  # Светлее при развороте


func _on_return_complete() -> void:
	# Завершение возврата
	projectile_returned.emit()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Обработка столкновения с физическим телом
	if body is StaticBody2D or body is RigidBody2D:
		_handle_hit(body.global_position)


func _on_area_entered(area: Area2D) -> void:
	# Обработка столкновения с другой областью
	if area.is_in_group("enemies") or area.is_in_group("destructible"):
		_handle_hit(area.global_position)


func _handle_hit(hit_position: Vector2) -> void:
	# Обработка попадания
	current_state = ProjectileState.HIT
	
	# Испускание сигнала о попадании
	projectile_hit.emit(hit_position, damage)
	
	# Остановка движения
	set_physics_process(false)


# Публичные методы для инициализации
func initialize(spawn_position: Vector2, fire_direction: Vector2, player: CharacterBody2D) -> void:
	global_position = spawn_position
	direction = fire_direction.normalized()
	player_reference = player
	flight_timer = 0.0
	has_returned = false
	current_state = ProjectileState.FLYING
	modulate = Color.WHITE
	
	# Сброс вращения
	rotation = direction.angle()


# Геттеры
func get_projectile_position() -> Vector2:
	return global_position


func is_returning() -> bool:
	return current_state == ProjectileState.RETURNING


func get_damage() -> float:
	return damage
