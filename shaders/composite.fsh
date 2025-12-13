#version 330 core

// CORE_SIZE CORE_BRIGHTNESS HALO_SIZE HALO_BRIGHTNESS SPILL_BRIGHTNESS VOLUMETRIC_INTENSITY

uniform sampler2D colortex0;
uniform sampler2D colortex1; 
uniform sampler2D colortex2; 
uniform sampler2D depthtex1; 

uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float near;
uniform float far;

#include "/settings.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 fragColor;

float getLinearDepth(float d) {
    return (2.0 * near * far) / (far + near - (d * 2.0 - 1.0) * (far - near));
}

float random(float p) {
    return fract(tan(distance(vec2(p * 1.618, p), vec2(p, p * 3.14))) * 141.421);
}

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    float depthRaw = texture(depthtex1, texcoord).r;
    float realDepth = getLinearDepth(depthRaw);

    vec3 normal = texture(colortex1, texcoord).rgb * 2.0 - 1.0;
    vec3 lightmap = texture(colortex2, texcoord).rgb;

    // --- FLASHLIGHT GEOMETRY ---
    
    vec2 uv = texcoord - 0.5;
    uv *= vec2(max(aspectRatio, 1.0), max(1.0 / aspectRatio, 1.0));
    float dist = length(uv);
    
    // This stops the beam from getting huge in the distance, keeping it stable.
    float shapeDepth = min(realDepth, 30.0);

    // This makes the beam closer to a Cylinder than a Cone.
    float expansion = shapeDepth * 0.006; 

    // CORE
    float coreRadius = (0.13 * CORE_SIZE) + expansion; 
    float beamCore = 1.0 - smoothstep(coreRadius, coreRadius + 0.05, dist);
    vec3 coreColor = vec3(CORE_RED, CORE_GREEN, CORE_BLUE) * beamCore;
    
    // HALO
    float haloRadius = (0.25 * HALO_SIZE) + expansion;
    float beamHalo = 1.0 - smoothstep(haloRadius, haloRadius + 0.15, dist);
    vec3 haloColor = vec3(HALO_RED, HALO_GREEN, HALO_BLUE) * beamHalo;
    
    // SPILL
    float beamSpill = 1.0 - smoothstep(0.0, 1.2 * HALO_SIZE + expansion, dist);
    vec3 spillColor = vec3(SPILL_RED, SPILL_GREEN, SPILL_BLUE) * beamSpill;

    // Combine Layers
    float flashlight = (beamCore * CORE_BRIGHTNESS) + 
                       (beamHalo * HALO_BRIGHTNESS) + 
                       (beamSpill * SPILL_BRIGHTNESS);
    vec3 flashlightColor = coreColor * CORE_SATURATION + haloColor * HALO_SATURATION + spillColor * SPILL_SATURATION;
    

    // Surface Falloff (Wall Fade)
    float surfaceFalloff = 1.0 - (realDepth / FLASHLIGHT_RANGE);
    surfaceFalloff = smoothstep(0.0, 1.0, surfaceFalloff);
    surfaceFalloff *= surfaceFalloff;

    // Calculate Surface Light
    float surfaceFlashlight = flashlight * surfaceFalloff;

    // Angle & Exposure Logic
    float angleFactor = max(normal.z, 0.0);
    float distBoost = mix(0.5, 2.0, smoothstep(0.0, 40.0, realDepth));
    float finalBoost = mix(1.0, distBoost, angleFactor);
    
    surfaceFlashlight *= pow(angleFactor, 0.4) * finalBoost;
    
    // Flicker
    if (FLASHLIGHT_FLICKER == 1) {
        if (abs(random(floor(frameTimeCounter * 12.0)) - 0.5) > 0.4) {
             float flickerMult = 0.8 + (sin(frameTimeCounter * 40.0) * 0.2);
             surfaceFlashlight *= flickerMult;
             beamSpill *= flickerMult; 
        }
    }

    // --- APPLY LIGHT TO SURFACE ---
    float finalLight = max(lightmap.x, surfaceFlashlight);
    
    bool isSky = (depthRaw >= 1.0);
    if (!isSky) {
        color *= finalLight;
    }

    color *= flashlightColor;

    // --- FOG & VOLUMETRICS ---
    
    // Calculate Fog Distance
    float fogDist = realDepth + dist * 2.0 - (finalLight * 15.0);
    
    // Air Beam (Volumetric Cone)
    float airPower = smoothstep(0.0, 50.0, FLASHLIGHT_RANGE); 
    float airBeam = beamSpill * SPILL_BRIGHTNESS * 2.0 * airPower;

    // Fog Density
    float fogStrength = (fogDist - 2.0) * 0.15;
    fogStrength = log(fogStrength * 20.0) * 0.3;
    fogStrength = clamp(fogStrength, 0.0, 1.0);

    // Fog Colors
    vec3 darkFogColor = vec3(0.05, 0.05, 0.05) * AMBIENT_BRIGHTNESS;
    vec3 beamFogColor = vec3(0.1, 0.1, 0.15); 
    
    vec3 finalFogColor = mix(darkFogColor, beamFogColor, clamp(airBeam, 0.0, 1.0));

    // Apply Fog
    color = mix(color, finalFogColor, fogStrength);

    // Additive Air Glow
    #ifdef VOLUMETRIC_INTENSITY
       color += vec3(airBeam * fogStrength * 0.15 * VOLUMETRIC_INTENSITY); 
    #else
       color += vec3(airBeam * fogStrength * 0.15); 
    #endif

    fragColor = vec4(color, 1.0);
}
