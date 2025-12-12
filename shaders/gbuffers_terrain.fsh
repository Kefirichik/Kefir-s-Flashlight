#version 330 core

uniform sampler2D texture;

in vec2 texcoord;
in vec4 color;

layout(location = 0) out vec4 fragColor;

void main() {
    vec4 texColor = texture(texture, texcoord) * color;
    if (texColor.a < 0.1) discard;
    fragColor = texColor;
}
