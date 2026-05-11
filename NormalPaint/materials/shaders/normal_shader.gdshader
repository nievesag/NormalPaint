shader_type spatial;
render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	//vec3 normal1 = NORMAL;
	
	vec3 normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(normal, 0.0)).xyz;
	//world_normal = world_normal.normalized();
	//vec3 view_normal = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;
	
	ALBEDO = normalize(world_normal);
	
	//vec3 normal = texture(normal_roughness_texture, SCREEN_UV).rgb;
	//ALBEDO = normal;
}