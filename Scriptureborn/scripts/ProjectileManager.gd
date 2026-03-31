extends Node2D
## ProjectileManager.gd - Менеджер снарядов
## Отвечает за создание, пулинг и управление жизненным циклом снарядов

@export_group("Projectile Settings")
@export var projectile_scene: PackedScene
@export var max_projectiles: int = 20
@export var enable_pooling: bool = true

# Пул снарядов
var projectile_pool: Array[Area2D] = []
var active_projectiles: Array[Area2D] = []

# Ссылка на игрока
var player_reference: CharacterBody2D


func _ready() -> void:
	# Инициализация пула снарядов
	if enable_pooling:
		_initialize_projectile_pool()
	
	# Поиск игрока для ссылок
	player_reference = get_node_or_null("../Player") as CharacterBody2D


func _initialize_projectile_pool() -> void:
	# Создание пула снарядов
	for i in range(max_projectiles):
		var projectile: Area2D = _create_projectile()
		projectile.visible = false
		projectile.set_physics_process(false)
		projectile_pool.append(projectile)


func _create_projectile() -> Area2D:
	# Создание нового снаряда
	var projectile: Area2D
	
	if projectile_scene:
		projectile = projectile_scene.instantiate() as Area2D
	else:
		# Создание снаряда программно если сцена не задана
		projectile = _create_default_projectile()
	
	add_child(projectile)
	return projectile


func _create_default_projectile() -> Area2D:
	# Программное создание снаряда по умолчанию
	var projectile: Area2D = Area2D.new()
	
	# Добавление скрипта
	var script: GDScript = load("res://scripts/Projectile.gd") if ResourceLoader.exists("res://scripts/Projectile.gd") else null
	if script:
		projectile.set_script(script)
	
	# Добавление визуала
	var sprite: ColorRect = ColorRect.new()
	sprite.size = Vector2(16, 8)
	sprite.color = Color(1.0, 0.8, 0.2)
	sprite.position = Vector2(-8, -4)
	projectile.add_child(sprite)
	
	# Добавление коллизии
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(16, 8)
	collision_shape.shape = shape
	projectile.add_child(collision_shape)
	
	# Добавление трейла
	var trail: Line2D = Line2D.new()
	trail.name = "Trail"
	projectile.add_child(trail)
	
	return projectile


func fire_projectile(spawn_position: Vector2, direction: Vector2) -> void:
	# Выстрел снарядом
	var projectile: Area2D = _get_available_projectile()
	
	if projectile:
		active_projectiles.append(projectile)
		projectile.visible = true
		projectile.set_physics_process(true)
		
		# Инициализация снаряда
		if projectile.has_method("initialize"):
			projectile.call("initialize", spawn_position, direction, player_reference)
		
		# Подключение сигналов
		if projectile.has_signal("projectile_hit"):
			projectile.connect("projectile_hit", _on_projectile_hit.bind(projectile))
		if projectile.has_signal("projectile_returned"):
			projectile.connect("projectile_returned", _on_projectile_returned.bind(projectile))


func _get_available_projectile() -> Area2D:
	# Получение доступного снаряда из пула или создание нового
	if enable_pooling and projectile_pool.size() > 0:
		return projectile_pool.pop_front()
	else:
		return _create_projectile()


func _return_projectile_to_pool(projectile: Area2D) -> void:
	# Возврат снаряда в пул
	if enable_pooling:
		projectile.visible = false
		projectile.set_physics_process(false)
		projectile_pool.append(projectile)
	else:
		projectile.queue_free()


func _on_projectile_hit(hit_position: Vector2, damage: float, projectile: Area2D) -> void:
	# Обработка попадания снаряда
	print("Projectile hit at: ", hit_position, " Damage: ", damage)
	
	# Удаление из активных
	if projectile in active_projectiles:
		active_projectiles.erase(projectile)
	
	# Возврат в пул после небольшой задержки (для анимации попадания)
	await get_tree().create_timer(0.5).timeout
	_return_projectile_to_pool(projectile)


func _on_projectile_returned(projectile: Area2D) -> void:
	# Обработка возврата снаряда
	print("Projectile returned to player")
	
	# Удаление из активных
	if projectile in active_projectiles:
		active_projectiles.erase(projectile)
	
	# Возврат в пул
	_return_projectile_to_pool(projectile)


func get_active_projectile_count() -> int:
	# Получение количества активных снарядов
	return active_projectiles.size()


func clear_all_projectiles() -> void:
	# Очистка всех снарядов
	for projectile in active_projectiles:
		_return_projectile_to_pool(projectile)
	
	active_projectiles.clear()
