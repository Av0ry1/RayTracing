#version 130
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 RESOLUTION;
uniform int MAX_DEPTH;
uniform int MAX_DISTANCE;
uniform int SAMPLE_COUNT;

uniform vec3 position;
uniform vec2 angle;

uniform vec2 seed1;
uniform vec2 seed2;

uniform int sampleCount;
uniform sampler2D sample;

uvec4 R_STATE;


// ---------- STRUCTS ----------
struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct Material
{
    vec3 emmitance;
    vec3 reflectance;
    float roughness;
    float opacity;
    float refractiveIndex;
};

struct Sphere
{
    Material material;
    vec3 position;
    float radius;
};

struct Plane
{
    Material material;
    vec3 normal;
    float offset;
};


// ---------- OBJECTS ----------
Sphere spheres[18] = Sphere[]
(   
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.3, 0.4), 0.01, 1.0, 1.0),
        vec3(20.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.4, 0.3, 0.9), 0.99, 1.0, 1.0),
        vec3(20.0, 3.0, 1.0),
        1.0
    ),

    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 1.0, 1.0, 1.0),
        vec3(-20.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.9375, 1.0, 1.0),
        vec3(-20.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.875, 1.0, 1.0),
        vec3(-20.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.8125, 1.0, 1.0),
        vec3(-20.0, 9.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.75, 1.0, 1.0),
        vec3(-17.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.6875, 1.0, 1.0),
        vec3(-17.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.625, 1.0, 1.0),
        vec3(-17.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.5625, 1.0, 1.0),
        vec3(-17.0, 9.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.5, 1.0, 1.0),
        vec3(-14.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.4375, 1.0, 1.0),
        vec3(-14.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.375, 1.0, 1.0),
        vec3(-14.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.3125, 1.0, 1.0),
        vec3(-14.0, 9.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.25, 1.0, 1.0),
        vec3(-11.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.1875, 1.0, 1.0),
        vec3(-11.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.125, 1.0, 1.0),
        vec3(-11.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.9, 0.9), 0.0625, 1.0, 1.0),
        vec3(-11.0, 9.0, 1.0),
        1.0
    )
);

Plane planes[1] = Plane[]
(
    Plane(
        Material(vec3(0.0), vec3(0.6, 0.6, 0.57), 0.985, 1.0, 1.0),
        vec3(0.0, 0.0, 1.0),
        0.0
    )
);


// ---------- UTILS ----------
mat2 rot(float a)
{
	float s = sin(a);
	float c = cos(a);
	return mat2(c, -s, s, c);
}

uint TausStep(uint z, int S1, int S2, int S3, uint M)
{
	uint b = (((z << S1) ^ z) >> S2);
	return (((z & M) << S3) ^ b);	
}

uint LCGStep(uint z, uint A, uint C)
{
	return (A * z + C);	
}

vec2 hash22(vec2 p)
{
	p += seed1.x;
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx+33.33);
	return fract((p3.xx+p3.yz)*p3.zy);
}

float random()
{
	R_STATE.x = TausStep(R_STATE.x, 13, 19, 12, uint(4294967294));
	R_STATE.y = TausStep(R_STATE.y, 2, 25, 4, uint(4294967288));
	R_STATE.z = TausStep(R_STATE.z, 3, 11, 17, uint(4294967280));
	R_STATE.w = LCGStep(R_STATE.w, uint(1664525), uint(1013904223));
	return 2.3283064365387e-10 * float((R_STATE.x ^ R_STATE.y ^ R_STATE.z ^ R_STATE.w));
}

vec3 randomOnSphere() {
	vec3 rand = vec3(random(), random(), random());
	float theta = rand.x * 2.0 * 3.14159265;
	float v = rand.y;
	float phi = acos(2.0 * v - 1.0);
	float r = pow(rand.z, 1.0 / 3.0);
	float x = r * sin(phi) * cos(theta);
	float y = r * sin(phi) * sin(theta);
	float z = r * cos(phi);
	return vec3(x, y, z);
}


// ---------- SKY ----------
vec3 getSky(vec3 rd)
{
    vec3 lightDir = normalize(vec3(0.9, 0.95, 1.0));
	vec3 col = vec3(0.7, 0.8, 0.9)+vec3(rd.z)/5;
	vec3 sun = vec3(0.95, 0.9, 1.0);
	sun *= max(0.0, pow(dot(rd, lightDir), 256.0));
	return clamp(sun + col, 0.0, 1.0);
}


// ---------- INTERSECTIONS ----------
vec2 sphereIntersect(Ray ray, Sphere sph)
{
    float b = dot(ray.origin - sph.position, ray.direction);
	float c = dot(ray.origin - sph.position, ray.origin - sph.position) - sph.radius * sph.radius;
	float h = b * b - c;
	if(h < 0.0) return vec2(-1.0);
	h = sqrt(h);
	return vec2(-b - h, -b + h);
}

float planeIntersect(Ray ray, Plane pla)
{
    return -(dot(ray.origin, pla.normal) - pla.offset) / dot(ray.direction, pla.normal);
}


// ---------- MAIN ----------
vec3 cast(inout Ray ray, inout bool hitEmitter)
{
    Material material;
    vec3 normal;
    vec3 color;
    vec2 minDist = vec2(MAX_DISTANCE);

    for (int i = 0; i < spheres.length(); i++)
    {
        Sphere sph = spheres[i];

        vec2 dist = sphereIntersect(ray, sph);

        if (dist.x > 0.0 && dist.x < minDist.x)
        {
            minDist = dist;
            normal = normalize(ray.origin + ray.direction * dist.x - sph.position);
            material = sph.material;
        }
    }

    for (int i = 0; i < planes.length(); i++)
    {
        Plane pla = planes[i];

        float dist = planeIntersect(ray, pla);

        if (dist > 0.0 && dist < minDist.x)
        {
            minDist = vec2(dist);
            normal = pla.normal;
            material = pla.material;
        }
    }

    if (minDist.x == MAX_DISTANCE)
    {
        hitEmitter = true;
        return getSky(ray.direction);
    }

    ray.origin += ray.direction * (minDist.x - 0.001);
    ray.direction = reflect(ray.direction, normal);

    if (material.roughness > 0.0)
    {
        vec3 r = randomOnSphere();
        vec3 diffuse = normalize(r * dot(r, normal));
        ray.direction = mix(ray.direction, diffuse, material.roughness);
    }

    color = material.reflectance;
    return color;
}

vec3 trace(vec3 rayOrigin, vec3 rayDirection)
{
    vec3 color = vec3(1.0);

    Ray ray = Ray(rayOrigin, rayDirection);
    bool hitEmitter = false;
    
    for (int i = 0; i < MAX_DEPTH; i++)
    {   
        color *= cast(ray, hitEmitter);
        if (hitEmitter) return color;
    }

    return vec3(0.0);
}

void main()
{
    vec2 uv = (gl_TexCoord[0].xy - 0.5) * RESOLUTION / RESOLUTION.y;

    vec2 uvRes = hash22(uv + 1.0) * RESOLUTION + RESOLUTION;
	R_STATE.x = uint(seed1.x + uvRes.x);
	R_STATE.y = uint(seed1.y + uvRes.x);
	R_STATE.z = uint(seed2.x + uvRes.y);
	R_STATE.w = uint(seed2.y + uvRes.y);

    vec3 rayDirection = normalize(vec3(1.0, uv));
    rayDirection.zx *= rot(-angle.y);
    rayDirection.xy *= rot(angle.x);

    vec3 color = vec3(0.0);
    for (int i = 0; i < SAMPLE_COUNT; i++)
    {
        color += trace(position, rayDirection);
    }
    color /= SAMPLE_COUNT;

    vec3 sampleColor = texture(sample, vec2(gl_TexCoord[0].x, 1.0-gl_TexCoord[0].y)).rgb;
    gl_FragColor = vec4(mix(sampleColor, color, 1.0 / sampleCount), 1.0);
}