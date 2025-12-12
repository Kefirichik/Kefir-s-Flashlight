#version 330 core

// Modern Attributes
in vec3 vaPosition;
in vec4 vaColor;
in vec2 vaUV0;
in ivec2 vaUV2; 
in vec3 vaNormal;
in vec3 mc_Entity; 

// Iris Uniforms
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 chunkOffset;
uniform mat4 gbufferModelViewInverse;

// Outputs to Fragment Shader
out vec2 texcoord;
out vec2 lmcoord;
out vec3 Normal;
out vec4 Color;
out float blockId;

void main() {
    texcoord = vaUV0;
    Color = vaColor;
    
    blockId = mc_Entity.x;

    Normal = normalize(mat3(gbufferModelView) * vaNormal);

    lmcoord = (vaUV2 * 33.05 / 32.0) - (1.05 / 32.0);

    vec4 position = vec4(vaPosition + chunkOffset, 1.0);
    gl_Position = gbufferProjection * gbufferModelView * position;
}
