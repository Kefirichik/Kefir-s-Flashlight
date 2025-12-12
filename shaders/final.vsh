#version 330 core

layout(location = 0) in vec4 vaPosition;

out vec2 texcoord;

void main() {
    gl_Position = vec4(vaPosition.xy * 2.0 - 1.0, 0.0, 1.0);
    texcoord = vaPosition.xy;
}
