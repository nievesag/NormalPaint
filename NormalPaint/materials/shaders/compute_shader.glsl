#[compute]
#version 450

layout(set = 0, binding = 0, std430) readonly buffer parameters {
    float width;
    float height;
    float mask_w;
    float mask_h;
    float cx;
    float cy;
    float diameter;
    float radius;
    float brush_strength;
    vec4 color;
}
params;

layout(set = 0, binding = 1, rgba32f) uniform image2D image; // mascara

layout(set = 0, binding = 2, rgba32f) uniform image2D image_1; // textura

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

void main() {
    ivec2 local = ivec2(gl_GlobalInvocationID.xy);

    float x = float(params.cx - params.radius + local.x);
    float y = float(params.cy - params.radius + local.y);

    int px = int(mod( ( mod(x, float(params.width)) + float(params.width)), float(params.width) ));
    int py = int(mod( ( mod(y, float(params.height)) + float(params.height)), float(params.height) ));

    // normalizamos la pos local dentro de 0-1
	// max evita dividir entre 0 si el diametro fuese 1
    float u = clamp(float(local.x) / float(max(1, params.diameter - 1)), 0.0, 1.0);
    float v = clamp(float(local.y) / float(max(1, params.diameter - 1)), 0.0, 1.0);

    // convertimos esa posición normalizada a coordenadas reales dentro de la máscara del brush
	// si u = 0.0 -> mx = 0
	// si u = 1.0 -> mx = mask_w - 1 
    int mx = int(floor((u * float(params.mask_w - 1)) + 0.5));
	int my = int(floor((v * float(params.mask_h - 1)) + 0.5));

    float mask_value = clamp(imageLoad(image, local).r, 0.0, 1.0) * params.brush_strength;

    if (mask_value <= 0.0)
    {
        return;
    }

    vec4 base = imageLoad(image_1, ivec2(px, py));
    vec4 output_color = mix(base, params.color, mask_value);
    imageStore(image_1, ivec2(px, py), output_color);

    //vec4 color = imageLoad(image, uv);
    //vec4 multiplier = vec4(params.r, params.g, params.b, 1.0);

    //vec4 output_color = color * multiplier;
    //imageStore(image, uv, output_color);
}