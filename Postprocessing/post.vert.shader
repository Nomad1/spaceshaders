uniform mediump float s_nearPlaneWidth;
uniform mediump float s_nearPlaneHeight;
uniform vec3 s_sunLightDirection;

uniform mat4 s_pmvMatrix;

in vec3 in_position;
in vec2 in_texcoord;

// outs

#ifdef FXAA
out vec2 TexCoord[5];
#else
out vec2 TexCoord[1];
#endif

flat out vec4 Color;
flat out float Aspect;
flat out vec2 LightPos;

out vec4 LightDir;
out float NSteps;


// constants

#if defined( ULTRA_QUALITY )
 const int Samples = 12;
 const float Weight = 0.8;
 const float Decay = 0.8;
 const float Exposure = 0.03;
#elif defined( HIGH_QUALITY )
 const int Samples = 8;
 const float Weight = 0.8;
 const float Decay = 0.8;
 const float Exposure = 0.03;
#elif defined( NORMAL_QUALITY )
 const int Samples = 6;
 const float Weight = 0.9;
 const float Decay = 0.9;
 const float Exposure = 0.04;
#else
 const int Samples = 3;
 const float Weight = 0.9;
 const float Decay = 0.9;
 const float Exposure = 0.04;
#endif

const float Step = 0.010 / float(Samples);

out vec3 Coords[Samples];

void main(void)
{
    vec2 texCoord = vec2(in_texcoord.x, 1.0 - in_texcoord.y);
    gl_Position = s_pmvMatrix * vec4(in_position, 1.0);
    Aspect = s_nearPlaneWidth / s_nearPlaneHeight;

    LightPos = s_sunLightDirection.xy * vec2(0.5) + vec2(0.5);

    vec2 dir = texCoord - LightPos;
    float len = dot(dir, dir);
    float distance = sqrt(len);

    LightDir = vec4(dir, len, distance);

    // pre-calculate coords for distance search
    float nsteps = clamp(floor(distance / Step), 1.0, float(Samples));
    
    vec2 dtc = dir / nsteps;

    vec2 coord = texCoord;

    NSteps = floor(nsteps);

    float illumdecay = 1.0;

    for(int i = 0; i < Samples; i++)
    {
        coord -= dtc;
        Coords[i] = vec3(coord, illumdecay * Weight);
        illumdecay *= Decay;
    }

    TexCoord[0] = texCoord;
#ifdef FXAA
    vec2 inverseVP = vec2(1.0 / s_nearPlaneWidth, 1.0 / s_nearPlaneHeight);
    TexCoord[1] = texCoord + vec2(-inverseVP.x, -inverseVP.y);
    TexCoord[2] = texCoord + vec2(inverseVP.x, -inverseVP.y);
    TexCoord[3] = texCoord + vec2(-inverseVP.x, inverseVP.y);
    TexCoord[4] = texCoord + vec2(inverseVP.x, inverseVP.y);
#endif
}