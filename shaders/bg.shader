shader_type canvas_item;

float circle (in vec2 _st, in float _radius)
{
	vec2 dist = _st - vec2(0.5);
	return 1.0 - smoothstep(_radius-(_radius*0.01), _radius+(_radius*0.01), dot(dist,dist) * 4.0);
}

float random (in vec2 _st)
{
	return fract(sin(dot(_st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise (in vec2 _st) 
{
	vec2 i = floor(_st);
	vec2 f = fract(_st);

	// Four corners in 2D of a tile
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	vec2 u = f * f * (3.0 - 2.0 * f);
	
	return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


float fbm ( in vec2 _st)
{
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	
	mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
	for (int i = 0; i < 15; ++i)
	{
		v += a * noise(_st);
		_st = rot * _st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

uniform float time_multiplier = 1.0;

void fragment()
{
	vec2 st = UV.xy;
	//vec3 color = vec3(circle(st, 0.8));
	
	vec3 color = vec3(0.0);

	vec2 q = vec2(0.0);
	q.x = fbm(st + 0.0 * TIME);
	q.y = fbm(st + vec2(1.0));

	vec2 r = vec2(0.0);
	r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2) + 0.05 * TIME * time_multiplier);
	r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8) + 0.025 * TIME * time_multiplier);

	float f = fbm(st + r);

	color = mix(vec3(0.0, 0.25, 0.75), vec3(0.0, 0.55, 0.75), clamp((f * f) * 4.0, 0.0, 1.0));
	color = mix(color, vec3(0.0, 0.5, 0.75), clamp(length(q), 0.0, 1.0));
	color = mix(color, vec3(0.5, 0.25, 0.25), clamp(length(r), 0.0, 1.0));

	vec3 new_color = (f * f * f + 0.6 * f * f + 0.5 * f) * color;
	
	//COLOR = vec4(new_color, circle(1.0 - st, 0.8));
	COLOR = vec4(new_color, 1.0);
	
}