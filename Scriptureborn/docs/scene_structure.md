# Scriptureborn - Структура проекта и сцены

## Дерево сцены (Main.tscn)

```
Node2D (Main)
├── Camera2D
├── ColorRect (Arena Background)
├── StaticBody2D (Walls)
│   └── CollisionShape2D
├── StaticBody2D (Obstacles)
│   ├── CollisionShape2D (Obstacle1)
│   ├── CollisionShape2D (Obstacle2)
│   └── CollisionShape2D (Obstacle3)
├── CharacterBody2D (Player)
│   ├── CollisionShape2D
│   ├── ColorRect (Visual)
│   │   └── ShaderMaterial (Procedural Texture)
│   ├── GrapplingHook (Node2D)
│   │   ├── RigidBody2D (HookHead)
│   │   │   └── CollisionShape2D
│   │   └── Line2D (RopeVisual)
│   └── WeaponSpawn (Marker2D)
└── ProjectileManager (Node2D)
```

## Физические слои (Physics Layers)

### Layer Bitmasks:
- **Layer 1**: Player
- **Layer 2**: Walls/Obstacles  
- **Layer 3**: Grappling Hook
- **Layer 4**: Projectiles

### Collision Masks:
- **Player** (Layer 1): Mask = 2 (столкновения со стенами)
- **Walls** (Layer 2): Mask = 1, 3, 4 (столкновения с игроком, крюком, снарядами)
- **Hook** (Layer 3): Mask = 2 (столкновения только со стенами)
- **Projectile** (Layer 4): Mask = 2 (столкновения только со стенами)

## Параметры физики веревки

### DampedSpringJoint2D настройки:
- **stiffness**: 40.0 (жесткость пружины)
- **damping**: 5.0 (затухание колебаний)
- **rest_length**: 15.0 (длина сегмента в покое)

### Сегменты веревки:
- **Количество**: 8 сегментов
- **Масса каждого**: 0.1 (легкие для инерции)
- **Linear Damping**: 2.0 (воздушное сопротивление)
- **Angular Damping**: 3.0 (затухание вращения)

## Управление

- **WASD**: Перемещение игрока
- **ЛКМ**: Бросок/притяжение крюка
- **ПКМ**: Выстрел снарядом
- **Пробел**: Отцепка крюка (альтернатива)
