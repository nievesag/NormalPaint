#[compute]
#version 450

layout(set = 0, binding = 0, rgba32f) uniform image2D image;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec4 color = imageLoad(image, uv);
}