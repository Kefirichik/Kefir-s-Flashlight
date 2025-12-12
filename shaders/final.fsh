#version 330 core

uniform sampler2D colortex0;

in vec2 texcoord;

layout(location = 0) out vec4 fragColor;

void main() {
   fragColor = texture(colortex0, texcoord);
}
