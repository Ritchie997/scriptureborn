extends Node2D
## Main.gd - Главная сцена игры
## Инициализирует арену, игрока и настройки проекта

@export_group("Arena Settings")
@export var arena_size: Vector2 = Vector2(1000, 1000)
@export var wall_thickness: float = 50.0
@export var obstacle_count: int = 5

@export_group("Camera Settings")
@export var camera_zoom: float = 1.0
@export var camera_follow_speed: float = 5.0

# Ссылки на ноды
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var projectile_manager: Node2D = $ProjectileManager

# Вектор для слежения камеры
var camera_target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Настройка проекта
	_setup_project_settings()
	
	# Создание арены
	_create_arena()
	
	# Подключение сигналов от игрока
	if player:
		player.projectile_fired.connect(_on_player_projectile_fired)
	
	# Инициализация позиции камеры
	camera_target_position = player.global_position if player else Vector2.ZERO


func _setup_project_settings() -> void:
	# Настройка физики проекта
	PhysicsServer2D.set_active(true)
	
	# Установка гравитации (для 2D сверху гравитация не нужна, но оставим для совместимости)
	ProjectSettings.set("physics/2d/default_gravity", 0.0)


func _create_arena() -> void:
	# Создание границ арены
	_create_walls()
	
	# Создание препятствий
	_create_obstacles()


func _create_walls() -> void:
	# Создание стен по периметру арены
	var walls_parent: Node2D = Node2D.new()
	walls_parent.name = "Walls"
	add_child(walls_parent)
	
	var half_size: Vector2 = arena_size * 0.5
	
	# Верхняя стена
	_create_wall_segment(walls_parent, Vector2(0, -half_size.y), Vector2(arena_size.x, wall_thickness))
	
	# Нижняя стена
	_create_wall_segment(walls_parent, Vector2(0, half_size.y), Vector2(arena_size.x, wall_thickness))
	
	# Левая стена
	_create_wall_segment(walls_parent, Vector2(-half_size.x, 0), Vector2(wall_thickness, arena_size.y))
	
	# Правая стена
	_create_wall_segment(walls_parent, Vector2(half_size.x, 0), Vector2(wall_thickness, arena_size.y))


func _create_wall_segment(parent: Node2D, position: Vector2, size: Vector2) -> void:
	# Создание отдельного сегмента стены
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = position
	
	# Добавление коллизии
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	
	# Настройка физических слоев
	wall.collision_layer = 2  # Layer 2: Walls
	wall.collision_mask = 7   # Mask 1,2,3: Player, Walls, Hook
	
	wall.add_child(collision_shape)
	parent.add_child(wall)


func _create_obstacles() -> void:
	# Создание случайных препятствий на арене
	var obstacles_parent: Node2D = Node2D.new()
	obstacles_parent.name = "Obstacles"
	add_child(obstacles_parent)
	
	var half_size: Vector2 = arena_size * 0.5 - Vector2(100, 100)  # Отступ от стен
	
	for i in range(obstacle_count):
		# Случайная позиция и размер
		var random_pos: Vector2 = Vector2(
			randf_range(-half_size.x, half_size.x),
			randf_range(-half_size.y, half_size.y)
		)
		
		var random_size: Vector2 = Vector2(
			randf_range(50, 150),
			randf_range(50, 150)
		)
		
		# Создание препятствия
		var obstacle: StaticBody2D = StaticBody2D.new()
		obstacle.position = random_pos
		
		# Добавление коллизии
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = random_size
		collision_shape.shape = shape
		
		# Настройка физических слоев
		obstacle.collision_layer = 2
		obstacle.collision_mask = 7
		
		obstacle.add_child(collision_shape)
		obstacles_parent.add_child(obstacle)


func _process(delta: float) -> void:
	# Слежение камеры за игроком
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	if not player or not camera:
		return
	
	# Плавное слежение за игроком
	camera_target_position = lerp(camera_target_position, player.global_position, camera_follow_speed * delta)
	camera.position = camera_target_position


func _on_player_projectile_fired(spawn_position: Vector2, direction: Vector2) -> void:
	# Обработка выстрела игрока
	if projectile_manager:
		projectile_manager.fire_projectile(spawn_position, direction)


# Утилитарные функции
func get_arena_bounds() -> Rect2:
	# Получение границ арены
	return Rect2(-arena_size * 0.5, arena_size)


func reset_game() -> void:
	# Перезапуск игры
	if player:
		player.global_position = Vector2.ZERO
	
	camera_target_position = Vector2.ZERO
