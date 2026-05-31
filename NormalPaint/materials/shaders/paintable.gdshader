shader_type spatial;

uniform sampler2D main : source_color; 
uniform sampler2D paint : source_color; 

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
    ALBEDO = texture(main, UV).rgb * 0.5 + texture(paint, UV).rgb * 0.5;
}