#version 130

uniform vec2 RESOLUTION;
uniform int MAX_DEPTH;
uniform int MAX_DISTANCE;
uniform int SAMPLE_COUNT;
uniform int SCALE;
uniform float GAMMA;

uniform vec3 position;
uniform vec2 angle;

uniform vec2 seed1;
uniform vec2 seed2;

uniform int staticFrames;
uniform sampler2D sample;

uniform float time;

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

struct Triangle
{
    vec3 v0;
    vec3 v1;
    vec3 v2;
    vec3 normal;
};

struct Model
{
    Material material;
    vec3 position;
    vec3 size;
    Triangle triangles[12];
};


// ---------- OBJECTS ----------
Sphere spheres[21] = Sphere[]
(   
    Sphere(
        Material(vec3(0.0), vec3(0.95), 0.001, 1.0, 1.0),
        vec3(2.5, -45, 1.25),
        1.25
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.95), 0.985, 1.0, 1.0),
        vec3(7.5, -45, 1.25),
        1.25
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7), 1.0, 1.0, 1.0),
        vec3(-35.5, -35.5, 2.5),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.85, 0.71, 0.4), 0.01, 1.0, 1.0),
        vec3(20.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.9, 0.4, 0.83), 0.99, 1.0, 1.0),
        vec3(20.0, 3.0, 1.0),
        1.0
    ),

    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 1.0, 1.0, 1.0),
        vec3(-20.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.9338, 1.0, 1.0),
        vec3(-20.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.8671, 1.0, 1.0),
        vec3(-20.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.8004, 1.0, 1.0),
        vec3(-20.0, 9.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.7337, 1.0, 1.0),
        vec3(-17.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.6670, 1.0, 1.0),
        vec3(-17.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.6003, 1.0, 1.0),
        vec3(-17.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.5336, 1.0, 1.0),
        vec3(-17.0, 9.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.4669, 1.0, 1.0),
        vec3(-14.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.4002, 1.0, 1.0),
        vec3(-14.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.3668, 1.0, 1.0),
        vec3(-14.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.3335, 1.0, 1.0),
        vec3(-14.0, 9.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.2001, 1.0, 1.0),
        vec3(-11.0, 0.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.1334, 1.0, 1.0),
        vec3(-11.0, 3.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.0667, 1.0, 1.0),
        vec3(-11.0, 6.0, 1.0),
        1.0
    ),
    Sphere(
        Material(vec3(0.0), vec3(0.7, 0.7, 0.7), 0.0, 1.0, 1.0),
        vec3(-11.0, 9.0, 1.0),
        1.0
    )
);

Plane planes[1] = Plane[]
(
    Plane(
        Material(vec3(0.0), vec3(0.4, 0.3, 0.2), 0.95, 1.0, 1.0),
        vec3(0.0, 0.0, 1.0),
        0.0
    )
);

Model models[5] = Model[]
(
    Model(
        Material(vec3(0.0), vec3(1.0, 1.0, 1.0), 0.7, 1.0, 1.0),
        vec3(0.0, -50.0, 0.002),
        vec3(10.0, 20.0, 10.0),
        Triangle[](
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), -vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), -vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), -vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), -vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), -vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), -vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), -vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), -vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), -vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), -vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), -vec3(0.0, 1.0, 0.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), -vec3(0.0, 1.0, 0.0))
        )
    ),
    Model(
        Material(vec3(0.0), vec3(1.0, 0.7, 0.3), 0.7, 1.0, 1.0),
        vec3(0.0, -50.0, -0.003),
        vec3(0.003, 20.0, 10.0),
        Triangle[](
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0))
        )
    ),
    Model(
        Material(vec3(0.0), vec3(0.3, 0.3, 1.0), 0.7, 1.0, 1.0),
        vec3(9.997, -50.0, -0.003),
        vec3(0.003, 20.0, 10.0),
        Triangle[](
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0))
        )
    ),
    Model(
        Material(vec3(10.0), vec3(1.0, 1.0, 1.0), 0.0, 1.0, 1.0),
        vec3(3.5, -46.5, 9.99),
        vec3(3.0, 3.0, 0.1),
        Triangle[](
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0))
        )
    ),
    Model(
        Material(vec3(0.0), vec3(0.0, 0.0, 0.0), 0.0, 1.0, 1.0),
        vec3(0.0, -32.5, 0.0),
        vec3(10.0, 0.003, 10.0),
        Triangle[](
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(-1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 0.0, 0.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0)),
            Triangle(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0))
        )
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

vec3 randomOnSphere()
{
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
	vec3 col = vec3(0.4, 0.6, 1.0);
	vec3 sun = vec3(0.95, 0.9, 1.0);
	sun *= max(0.0, pow(dot(rd, lightDir), 128.0));
	col += max(0.0, pow(dot(lightDir, rd), 3.0));
	return clamp(sun + col*0.6, 0.0, 1.0);
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

float triangleIntersect(Ray ray, Triangle tri)
{
    vec3 v1v0 = tri.v1 - tri.v0;
    vec3 v2v0 = tri.v2 - tri.v0;
    vec3 rov0 = ray.origin - tri.v0;
    vec3 n = cross( v1v0, v2v0 );
    vec3  q = cross( rov0, ray.direction );
    float d = 1.0/dot( ray.direction, n );
    float u = d*dot( -q, v2v0 );
    float v = d*dot(  q, v1v0 );
    float t = d*dot( -n, rov0 );
    if ( u<0.0 || v<0.0 || (u+v)>1.0 ) t = -15.0;

    return t;
}


// ---------- MAIN ----------
vec3 cast(inout Ray ray, inout bool hitEmitter)
{
    Material material;
    vec3 normal;
    vec3 color;
    vec2 minDist = vec2(MAX_DISTANCE);

    for (int i = 0; i < models.length(); i++)
    {
        Model mdl = models[i];

        for (int j = 0; j < mdl.triangles.length(); j++)
        {
            Triangle tri = mdl.triangles[j];

            tri.v0 *= mdl.size;
            tri.v1 *= mdl.size;
            tri.v2 *= mdl.size;

            tri.v0 += mdl.position;
            tri.v1 += mdl.position;
            tri.v2 += mdl.position;

            vec2 dist = vec2(triangleIntersect(ray, tri));

            if (dist.x > 0.0 && dist.x < minDist.x)
            {
                minDist = dist;
                normal = tri.normal;
                material = mdl.material;
            }
        }
    }

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

        vec2 dist = vec2(planeIntersect(ray, pla));

        if (dist.x > 0.0 && dist.x < minDist.x)
        {
            minDist = dist;
            normal = pla.normal;
            material = pla.material;
        }
    }

    if (minDist.x == MAX_DISTANCE)
    {
        hitEmitter = true;
        return getSky(ray.direction);
    }

    if (material.emmitance.x + material.emmitance.y + material.emmitance.z > 0)
    {
        hitEmitter = true;
        return material.emmitance;
    }

    ray.origin += ray.direction * (minDist.x - 0.001);
    ray.direction = reflect(ray.direction, normal);
    
    if (material.roughness > 0.0)
    {
        vec3 r = normalize(randomOnSphere());
        vec3 diffuse = normalize(r * dot(r, normal));
        ray.direction = normalize(mix(ray.direction, diffuse, material.roughness));
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
        //if (color.x + color.y + color.z == 0) break;
    }

    return vec3(0.0);
}

void main()
{
    vec2 uv = (gl_TexCoord[0].xy - 0.5) * RESOLUTION / RESOLUTION.y;

    vec3 rayDirection = normalize(vec3(1.0, uv));
    rayDirection.zx *= rot(-angle.y);
    rayDirection.xy *= rot(angle.x);

    vec2 uvRes = hash22(uv + 0.0) * RESOLUTION + RESOLUTION;

    R_STATE.x = uint(seed1.x + uvRes.x);
    R_STATE.y = uint(seed1.y + uvRes.x);
    R_STATE.z = uint(seed2.x + uvRes.y);
    R_STATE.w = uint(seed2.y + uvRes.y);

    vec3 color = vec3(0.0);

    for (int i = 0; i < SAMPLE_COUNT; i++)
    {
        color += trace(position, rayDirection);
    }
    color /= SAMPLE_COUNT;
    
    //float white = 20.0;
	//color *= white * 16.0;
	//color = (color * (1.0 + color / white / white)) / (1.0 + color);

    color.x = pow(color.x, 1.0/GAMMA);
    color.y = pow(color.y, 1.0/GAMMA);
    color.z = pow(color.z, 1.0/GAMMA);

    vec3 sampleColor = texture(sample, vec2(gl_TexCoord[0].x, 1.0 - gl_TexCoord[0].y)).rgb;

    color = mix(sampleColor, color, 1.0 / min(30, staticFrames));

    gl_FragColor = vec4(color, 1.0);
}