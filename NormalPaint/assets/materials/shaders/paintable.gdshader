shader_type spatial;

uniform sampler2D main : source_color; 
uniform sampler2D paint : source_color; 

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec4 main_tex = texture(main, UV);
    vec4 paint_tex = texture(paint, UV);
    
    vec3 final = mix(main_tex.rgb, paint_tex.rgb, paint_tex.a);
    
    ALBEDO = final;
}