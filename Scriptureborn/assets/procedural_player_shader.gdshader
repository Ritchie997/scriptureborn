extends ShaderMaterial
## procedural_player_shader.gdresource - Процедурная текстура для игрока
## Создает визуальный эффект с помощью шейдера без внешних ассетов

shader_type canvas_item;

// Параметры для настройки в инспекторе
uniform float noise_scale : 0.1 = 0.1;
uniform float animation_speed : 1.0 = 1.0;
uniform vec4 base_color : hint_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform vec4 accent_color : hint_color = vec4(0.8, 0.9, 1.0, 1.0);

void fragment() {
	// Получение координат фрагмента
	vec2 uv = UV;
	
	// Центрирование координат
	uv -= 0.5;
	
	// Создание круглой формы для игрока
	float circle = smoothstep(0.5, 0.48, length(uv));
	
	// Генерация процедурного шума
	float noise_val = sin(uv.x * 10.0 + TIME * animation_speed) * 
	                  cos(uv.y * 10.0 + TIME * animation_speed * 0.7);
	noise_val = noise_val * 0.5 + 0.5;
	
	// Смешивание цветов на основе шума
	vec3 final_color = mix(base_color.rgb, accent_color.rgb, noise_val);
	
	// Применение альфа-канала от формы круга
	COLOR = vec4(final_color, circle * base_color.a);
}
