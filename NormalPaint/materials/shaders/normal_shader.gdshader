shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture;
uniform sampler2D normal_tex : hint_normal;
uniform bool debug_view = true;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	//vec3 normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	//vec3 world_normal = (INV_VIEW_MATRIX * vec4(normal, 0.0)).xyz;
	//ALBEDO = normalize(world_normal);
	vec4 albedo = texture(albedo_texture, UV);
    vec3 nmap = texture(normal_tex, UV).rgb;

    //if (debug_view)
	{
        ALBEDO = albedo.rgb;
		NORMAL_MAP = nmap;
		NORMAL_MAP_DEPTH = 1.0;
    } 
	//else 
	//{
        //ALBEDO = vec3(0.8);
        //NORMAL_MAP = nmap;
        //NORMAL_MAP_DEPTH = 1.0;
    //}
}
