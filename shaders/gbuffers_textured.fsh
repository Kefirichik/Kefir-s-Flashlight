#version 330 core

uniform sampler2D lightmap;
uniform sampler2D texture;

in vec2 texcoord;
in vec2 lmcoord;
in vec3 Normal;
in vec4 Color;
in float blockId;

// Define Multiple Render Targets (MRT)
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;
layout(location = 2) out vec4 outColor2;

void main() {
    vec4 color = texture(texture, texcoord) * Color;
    if (color.a < .1){
        discard;
    }
    
    int id = int(blockId + 0.5);
    if (id == 21) {
        color *= vec4(0.9, 0.8, 0.85, 1.0);
    }

    float sunLight = dot(texture(lightmap, lmcoord).rgb, vec3(0.30, 0.59, 0.11));

    // Outputs
    outColor0 = color;
    outColor1 = vec4(Normal * 0.5 + 0.5, 1.0);
    outColor2 = vec4(lmcoord, sunLight, 1.0);
}
