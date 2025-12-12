#version 330 core

in vec3 vaPosition;
in vec4 vaColor;
in vec2 vaUV0;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 chunkOffset;

out vec2 texcoord;
out vec4 color;

void main() {
    texcoord = vaUV0;
    color = vaColor;
    
    gl_Position = gbufferProjection * gbufferModelView * vec4(vaPosition + chunkOffset, 1.0);
}
