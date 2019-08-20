#version 300 es

#ifdef GL_ES
precision highp float;
#endif

out vec4 fragOut;

uniform sampler2D palette; 
uniform vec4 resolution;
uniform vec2 panPosition;
uniform float lightR, lightG, lightB;
uniform float offX, offY, offZ; 
uniform float rotAngle, rotX, rotY, rotZ; 
uniform float incX, incY, incZ;
uniform float scaleX, scaleY, scaleZ;
uniform bool isFullRender;
uniform bool useShadow;
uniform bool useAO;
uniform bool invertPalette;
uniform float diffIntensity;
uniform float ambientLight;
uniform float shadowDensity;
uniform float shadowDarkness;
uniform float shadowIterations;
uniform float subPixel;
uniform float gamma;
uniform float paletteOffset;
uniform float AA;

uniform mat3 Orientation;
uniform float phongMethod;
uniform float specularExponent;
uniform float specularComponent;
uniform float normalComponent;
uniform float maxDetailIter;

uniform float aoMult, aoSub, aoMix;

const vec3 Eye = vec3(0, 0, 2.2);
uniform vec3 Light;
uniform float epsilon;
const float Slice=.0;
uniform float maxIterations;// = 7;
uniform float spongeIterations;// = 7;

uniform float Power;// = 12.0;
const float BAILOUT=2.0;
const float PI = 3.1415926535897932384626433832795;
const float DEG2RAD = PI/180.0;
const float halfPI = PI/2.0;


// rotate on axes, pass other 2 values -> e.g. rotate X, pass v.yz
vec2 rotate(float angle, vec2 v) 
{
  float a=cos(angle);
  float b=sin(angle);
  return vec2(a*v.s - b*v.t, a*v.t + b*v.s);
}


float sdPlane( vec3 p )
{
	return p.y;
}


//#define SINGLE_ROT        
vec2 sdSponge(vec3 z)
{
    vec3 offset = vec3(offX, offY, offZ);
    vec3 angle  = vec3(rotX, rotY, rotZ)*DEG2RAD;
    vec3 jVec   = vec3(incX, incY, incZ);
    vec3 scale  = vec3(scaleX, scaleY, scaleZ);
    //vec3 inc =
    float mag;
    float trap = dot(z.xyz,z.xyz);
    for(int i = int(spongeIterations); i >0; i--)
    {
        z = abs(z);
        //if(z.x>BAILOUT || z.y>BAILOUT || z.z>BAILOUT) break;
        z.xy = ((z.x < z.y) ? z.yx : z.xy); 
        z.xz = ((z.x < z.z) ? z.zx : z.xz); 
        z.zy = ((z.y < z.z) ? z.yz : z.zy);	 
        z = z * scale - offset * (scale - 1.);

        float offZ = offset.z*(max(scale.x, max(scale.y, scale.z))-1.);
        z.z += (z.z < -0.5*offZ) ? offZ : 0.0;
/*
        vec3 offZ = offset*(scale-vec3(1.));
        z += vec3((z.x < -0.5*offZ.x) ? offZ.x : 0.0, 
                  (z.y < -0.5*offZ.y) ? offZ.y : 0.0, 
                  (z.z < -0.5*offZ.z) ? offZ.z : 0.0);*/
#ifdef SINGLE_ROT        
        z = rotate(rotAngle * DEG2RAD, angle, z);
#else
        if(angle.x>0.0) z.yz = rotate(angle.x, z.yz);
        if(angle.y>0.0) z.zx = rotate(angle.y, z.zx);
        if(angle.z>0.0) z.xy = rotate(angle.z, z.xy);
#endif        
        z+=jVec;
        trap = min( trap, dot(z.xyz,z.xyz) );
    }
    //trap = length(normalize(z.xyz));
    z = abs(z) - vec3(1.);
    float dis = min(max(z.x, max(z.y, z.z)),0.0) + length(max(z,0.0)); 
    return vec2(dis * pow(1.25 * max(scale.x, max(scale.y, scale.z)), -(spongeIterations)), trap); 
}

vec3 Phong(vec3 light, vec3 eye, vec3 pt, vec3 N, vec3 mat) {
    vec3 lightColor = vec3(lightR, lightG, lightB);
    vec3 L = normalize(light - pt);
    vec3 E = normalize(eye - pt);
    float NdotL = dot(N, L);
    vec3 halfLV = normalize(L + E);
    float specular =  specularComponent * pow(max(dot(N, halfLV), 0.0 ), specularExponent);
    vec3 lambertian = mat * (lightColor + abs(N) * normalComponent) *  max(NdotL, 0.0) * diffIntensity;
    return clamp(lambertian + vec3(specular), 0.0, 1.0);
}


vec2 mainBulb(vec3 p)
{
    vec4 v = vec4(p, 1.0);
    float trap = dot(v.xyz,v.xyz);
    for(int i=int(maxIterations); i>0; i--)
    {
        float r = max(epsilon,length(v.xyz));
        if(r>BAILOUT) break;

        float theta = acos(clamp(v.z/r, -1.0, 1.0))*Power;
        float phi = atan(v.y, v.x)*Power;
        v.w = max(epsilon, pow(r,Power-1.0)*Power*v.w+1.0);

        float zr = pow(r,Power);
        v.xyz = vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta))*zr + p;
        trap = min(trap, dot(v.xyz,v.xyz));
    }
    float r = length(v.xyz);
    return vec2(0.5*log(r)*r/v.w, trap);

}

vec2 map(vec3 p)
{
#define USE_MANDELBULB
#ifdef USE_MANDELBULB
//    float pl = sdPlane(p + vec3(1.0,1.0,1.0));
    vec2 d1 = mainBulb(p);
    vec2 d2 = sdSponge(p);

    return (d1.x>d2.x) ? d1 : d2;
    
       
    //return mainBulb(p);
//    return min(pl, max(d1,d2));

#else
    return sdSponge(p);
#endif    
}

vec3 getNormal(vec3 p) 
{
    vec2 e = vec2(1.0,-1.0)*.5773*epsilon;
    return normalize( e.xyy*map( p + e.xyy ).x + 
                      e.yxy*map( p + e.yxy ).x + 
                      e.yyx*map( p + e.yyx ).x + 
                      e.xxx*map( p + e.xxx ).x );        
}


//Inigo Quilez technique: http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float softShadow(vec3 ro, vec3 rd, float mint, float tmax)
{
    float k = shadowDensity;
	float res = 1.0;
    float t = mint;
    float ph = 1e30; // big, such that y = 0 on the first iteration
    float eps = epsilon*.1;
    

    for( int i=int(shadowIterations); i>0; i-- )
    {
        float h = map(ro+rd*t).x;

#define USE_TRADITIONAL
#ifdef USE_TRADITIONAL
        // traditional technique
        res = min( res, k*h/t );
        t += h;
#else            
        // improved technique

        // use this if you are getting artifact on the first iteration, or unroll the
        // first iteration out of the loop
        //float y = (i==0) ? 0.0 : h*h/(2.0*ph); 
        float y = h*h/max(2.0*ph,.01);
        float f = h*h-y*y;        
        res = min( res, k*sqrt(f)/max(epsilon,t-y) );
        ph = h;
      
        // other fake shadow method 
        //res = min( res, smoothstep(0.0,1.0,k*h/t ));

        //limit shadow increnments
        //t += clamp( h, 0.01, 0.05 );
        t += min( h, 0.05);
        //t += h;
#endif        
        if( res<eps || t>tmax ) break;
    }
    return clamp(res, 0.0, 1.0 );
}


float getAO( vec3 pos, vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<7; i++ )
    {
        float h = 0.001 + 0.15*float(i)*.25;
        float d = map( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= aoMix;
    }
    return clamp( aoSub - aoMult*occ, 0.0, 1.0 );    
}


float rayCast(vec3 rO, vec3 rD, float tmin, float tmax, int iter)
{
    //float eps = 0.001;
    float t = tmin;
    for( int i=iter; i>0; i-- )
    {
	    float res = map( rO+rD*t ).x;
        t += res;
        if( res<epsilon*t || t>tmax) break;
    }

    return t>tmax ? -1.0 : t;
}


void main() {
    float sqAA = AA*AA;
    int intAA = int(AA);
    float NR = .5;

	mat3 orient = Orientation;
vec3 sampleCoord[9];
	 sampleCoord[0] = vec3( 0.,  0., 1.);
	 sampleCoord[1] = vec3( NR, -NR, .3);
	 sampleCoord[2] = vec3(-NR,  NR, .3);
	 sampleCoord[3] = vec3( NR,  NR, .3);
	 sampleCoord[4] = vec3(-NR, -NR, .3);
	 sampleCoord[5] = vec3(  0,  NR, .5);
	 sampleCoord[6] = vec3(  0, -NR, .5);
	 sampleCoord[7] = vec3( NR,   0, .5);
	 sampleCoord[8] = vec3(-NR,   0, .5);

    float tmin = 0.0001;
    float tmax = 100.0;


    float colorDiv = .2381/sqAA;
    vec3 color = vec3(0.);
    vec3 colorShadow = color, colorAmbient = color;
    vec2 ratio = resolution.zw; //resolution.xy / max(resolution.x, resolution.y);;
    vec2 pan = panPosition*ratio;
    vec3 origin = orient * (Eye+vec3(pan, 0.0));
    for( int k=int(sqAA)-1; k>=0; k-- ) {
        vec2 aa = vec2(k%intAA, k/intAA) / AA - 0.5;

        for (int i = 0; i < 9; i++) {

            vec2 coord = (2.0 * (gl_FragCoord.xy + sampleCoord[i].xy + aa) / resolution.xy - vec2(1.))*ratio;

            vec3 ray = vec3(coord+pan, -1.2);
            vec3 dir = normalize(orient * ray);

            float t = rayCast(origin, dir, tmin, tmax, int(maxDetailIter));

            if (t >=0.0) {
                vec3 pos = origin + t*dir;
                vec3 N = getNormal(pos) ;
                float aoComponent = useAO ? getAO(pos, N) : 1.0;
    #define USE_PALETTE
    #ifdef USE_PALETTE
                float offsetPal = clamp(map(pos).y, 0.0, 1.0)*.5;
                offsetPal = invertPalette ? .5-offsetPal : offsetPal;
                offsetPal += paletteOffset;
                vec3 mat = texture(palette, vec2(abs(fract(offsetPal)),0.5)).xyz;
    #else
                vec3 mat = mix(vec3(.35,0.,0.), vec3(0.,.35,0.0),clamp(map(pos).y, 0.0, 1.0) );
    #endif
                //dif=1.0;
                vec3 L = orient* Light; 
                float shadow = (useShadow ? softShadow(pos, normalize(L-origin), tmin, tmax) : 1.0) ;
                colorShadow += shadow * shadow * sampleCoord[i].z;
                colorAmbient= (mat * ambientLight + vec3(ambientLight))*.5;

                color += (colorAmbient + Phong( L, orient * Eye, orient * ray, N, mat))  * aoComponent * sampleCoord[i].z;
                //color += (colorAmbient + N)  * aoComponent * sampleCoord[i].z;
            }
            if(!isFullRender) { colorDiv = 1./sqAA; break; }

        }
    }
    color *= colorDiv;
    color = clamp((mix(color, color*colorShadow*colorDiv, shadowDarkness)), 0.0, 1.0);

    //gamma
    color = pow( color, vec3(1./gamma));
    fragOut = vec4(color, 1.);
    
}
