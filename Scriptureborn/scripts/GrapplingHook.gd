extends Node2D
## GrapplingHook.gd - Система крюка-кошки с физической веревкой
## Реализует бросок, физику сегментов веревки и притяжение игрока

@export_group("Hook Parameters")
@export var hook_speed: float = 800.0
@export var max_hook_distance: float = 600.0
@export var retraction_speed: float = 1000.0

@export_group("Rope Physics")
@export var segment_count: int = 8
@export var segment_length: float = 15.0
@export var spring_stiffness: float = 40.0
@export var spring_damping: float = 5.0
@export var segment_mass: float = 0.1

@export_group("References")
@onready var hook_head: RigidBody2D = $HookHead
@onready var rope_visual: Line2D = $RopeVisual

# Состояния крюка
enum HookState { IDLE, FIRING, ATTACHED, RETRACTING }
var current_state: HookState = HookState.IDLE

# Физические объекты
var segments: Array[RigidBody2D] = []
var joints: Array[DampedSpringJoint2D] = []
var anchor_point: Vector2 = Vector2.ZERO
var is_anchored: bool = false

# Векторы для расчетов
var fire_direction: Vector2 = Vector2.RIGHT
var player_reference: CharacterBody2D

# Сигналы
signal hook_attached()
signal hook_detached()
signal hook_position_updated(position: Vector2)


func _ready() -> void:
	# Получаем ссылку на игрока (родительскую ноду)
	player_reference = get_parent() as CharacterBody2D
	
	# Инициализация веревки
	_initialize_rope()
	
	# Настройка визуала веревки
	_setup_rope_visual()
	
	# Начальное скрытие крюка
	hook_head.visible = false
	hook_head.set_physics_process(false)


func _initialize_rope() -> void:
	# Создание сегментов веревки
	for i in range(segment_count):
		var segment: RigidBody2D = RigidBody2D.new()
		segment.name = "Segment_%d" % i
		segment.mass = segment_mass
		segment.linear_damping = 2.0
		segment.angular_damping = 3.0
		
		# Установка collision layer и mask для сегментов
		segment.collision_layer = 3  # Layer 3: Grappling Hook
		segment.collision_mask = 2   # Mask 2: Walls/Obstacles
		
		# Добавление коллизии
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 3.0
		collision_shape.shape = shape
		segment.add_child(collision_shape)
		
		segments.append(segment)
		add_child(segment)
		
		# Соединение сегментов пружинами
		if i > 0:
			_create_spring_joint(segments[i - 1], segment)
	
	# Настройка головы крюка
	_setup_hook_head()


func _setup_hook_head() -> void:
	# Настройка головы крюка для броска
	hook_head.collision_layer = 3
	hook_head.collision_mask = 2
	hook_head.linear_damping = 1.0
	hook_head.angular_damping = 2.0
	
	# Подключение сигнала столкновения
	var collision_shape: CollisionShape2D = hook_head.get_node("CollisionShape2D")
	if collision_shape:
		# Используем body_entered сигнал от Area2D если есть
		pass


func _create_spring_joint(segment_a: RigidBody2D, segment_b: RigidBody2D) -> void:
	# Создание пружинного соединения между сегментами
	var joint: DampedSpringJoint2D = DampedSpringJoint2D.new()
	joint.node_a = segment_a.get_path()
	joint.node_b = segment_b.get_path()
	
	# Настройка физики пружины
	joint.stiffness = spring_stiffness
	joint.damping = spring_damping
	joint.rest_length = segment_length
	
	joints.append(joint)
	add_child(joint)


func _setup_rope_visual() -> void:
	# Настройка Line2D для визуализации веревки
	rope_visual.width = 3.0
	rope_visual.default_color = Color(0.7, 0.5, 0.3)  # Коричневый цвет веревки
	rope_visual.joint_mode = Line2D.LINE_JOINT_ROUND


func _physics_process(delta: float) -> void:
	match current_state:
		HookState.FIRING:
			_update_firing(delta)
		HookState.ATTACHED:
			_update_attached(delta)
		HookState.RETRACTING:
			_update_retracting(delta)
	
	# Обновление визуала веревки
	_update_rope_visual()


func _update_firing(delta: float) -> void:
	# Движение крюка вперед
	if hook_head:
		hook_head.linear_velocity = fire_direction * hook_speed
		
		# Проверка расстояния
		var distance_from_player: float = hook_head.global_position.distance_to(player_reference.global_position)
		if distance_from_player >= max_hook_distance:
			_start_retraction()


func _update_attached(delta: float) -> void:
	# Обработка состояния зацепа
	if not is_anchored:
		return
	
	# Применение силы к первому сегменту в сторону точки зацепа
	if segments.size() > 0:
		var first_segment: RigidBody2D = segments[0]
		var direction_to_anchor: Vector2 = (anchor_point - first_segment.global_position).normalized()
		var distance_to_anchor: float = first_segment.global_position.distance_to(anchor_point)
		
		# Плавное притяжение первого сегмента к точке зацепа
		if distance_to_anchor > segment_length:
			first_segment.apply_central_force(direction_to_anchor * spring_stiffness * 10)


func _update_retracting(delta: float) -> void:
	# Возврат крюка к игроку
	if hook_head:
		var direction_to_player: Vector2 = (player_reference.global_position - hook_head.global_position).normalized()
		hook_head.linear_velocity = direction_to_player * retraction_speed
		
		# Проверка достижения игрока
		var distance_to_player: float = hook_head.global_position.distance_to(player_reference.global_position)
		if distance_to_player < 20.0:
			_reset_hook()


func _update_rope_visual() -> void:
	# Обновление точек линии веревки
	var points: PackedVector2Array = PackedVector2Array()
	
	# Начало от игрока
	points.append(player_reference.global_position if player_reference else global_position)
	
	# Добавление позиций сегментов
	for segment in segments:
		points.append(segment.global_position)
	
	# Конец к голове крюка
	if hook_head and hook_head.visible:
		points.append(hook_head.global_position)
	
	rope_visual.points = points


func fire_hook(start_position: Vector2, direction: Vector2) -> void:
	# Запуск крюка
	if current_state != HookState.IDLE:
		return
	
	current_state = HookState.FIRING
	fire_direction = direction.normalized()
	
	# Телепортация головы крюка к игроку
	hook_head.global_position = start_position
	hook_head.visible = true
	hook_head.set_physics_process(true)
	hook_head.linear_velocity = fire_direction * hook_speed
	
	# Сброс позиций сегментов
	_reset_segments_positions(start_position)


func _reset_segments_positions(start_position: Vector2) -> void:
	# Расстановка сегментов вдоль направления броска
	for i in range(segments.size()):
		var segment: RigidBody2D = segments[i]
		var offset: float = (i + 1) * segment_length
		segment.global_position = start_position + fire_direction * offset
		segment.linear_velocity = Vector2.ZERO
		segment.angular_velocity = 0.0


func detach_hook() -> void:
	# Отцепка и возврат крюка
	match current_state:
		HookState.ATTACHED:
			is_anchored = false
			_start_retraction()
		HookState.FIRING:
			_start_retraction()
	
	hook_detached.emit()


func _start_retraction() -> void:
	# Начало возврата крюка
	current_state = HookState.RETRACTING
	is_anchored = false


func _reset_hook() -> void:
	# Полный сброс крюка в исходное состояние
	current_state = HookState.IDLE
	hook_head.visible = false
	hook_head.set_physics_process(false)
	hook_head.linear_velocity = Vector2.ZERO
	
	# Скрытие сегментов рядом с игроком
	for segment in segments:
		segment.linear_velocity = Vector2.ZERO
		segment.angular_velocity = 0.0


func get_grapple_force(player_position: Vector2) -> Vector2:
	# Расчет силы притяжения к точке зацепа
	if not is_anchored or current_state != HookState.ATTACHED:
		return Vector2.ZERO
	
	var direction_to_anchor: Vector2 = (anchor_point - player_position).normalized()
	var distance: float = player_position.distance_to(anchor_point)
	
	# Сила притяжения обратно пропорциональна расстоянию (закон Гука)
	var force_magnitude: float = max(0.0, (distance - segment_length)) * spring_stiffness * 0.5
	
	return direction_to_anchor * force_magnitude


func _on_hook_head_body_entered(body: Node2D) -> void:
	# Обработка столкновения головы крюка с препятствием
	if current_state == HookState.FIRING and body is StaticBody2D:
		_anchor_hook(body.global_position)


func _anchor_hook(collision_point: Vector2) -> void:
	# Закрепление крюка в точке столкновения
	current_state = HookState.ATTACHED
	is_anchored = true
	anchor_point = collision_point
	
	# Остановка головы крюка
	hook_head.linear_velocity = Vector2.ZERO
	hook_head.angular_velocity = 0.0
	
	hook_attached.emit()


# Геттеры для внешнего доступа
func get_hook_position() -> Vector2:
	if is_anchored:
		return anchor_point
	return hook_head.global_position if hook_head else Vector2.ZERO


func is_hook_active() -> bool:
	return current_state != HookState.IDLE
