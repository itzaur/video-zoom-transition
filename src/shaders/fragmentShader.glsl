varying vec2 vUv;

uniform sampler2D uVideo;
uniform sampler2D uImage;
uniform float uCircleScale;
uniform float uTime;
uniform vec2 uViewport;

float circle(vec2 uv, float radius, float sharp) {
    vec2 tempUV = (uv - vec2(0.5)) / vec2(0.58, 1.0);

    return 1.0 - smoothstep(radius - radius * sharp, radius + radius * sharp, dot(tempUV, tempUV) * 2.0);
}

//Avener Random FBM
mat2 rot2d(in float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float r(in float a, in float b) {
    return fract(sin(dot(vec2(a, b), vec2(12.9898, 78.233))) * 43758.5453);
}
float h(in float a) {
    return fract(sin(dot(a, dot(12.9898, 78.233))) * 43758.5453);
}

float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    return mix(mix(mix(h(n + 0.0), h(n + 1.0), f.x), mix(h(n + 57.0), h(n + 58.0), f.x), f.y), mix(mix(h(n + 113.0), h(n + 114.0), f.x), mix(h(n + 170.0), h(n + 171.0), f.x), f.y), f.z);
}

// http://www.iquilezles.org/www/articles/morenoise/morenoise.htm
// http://www.pouet.net/topic.php?post=401468
vec3 dnoise2f(in vec2 p) {
    float i = floor(p.x), j = floor(p.y);
    float u = p.x - i, v = p.y - j;
    float du = 30. * u * u * (u * (u - 2.) + 1.);
    float dv = 30. * v * v * (v * (v - 2.) + 1.);
    u = u * u * u * (u * (u * 6. - 15.) + 10.);
    v = v * v * v * (v * (v * 6. - 15.) + 10.);
    float a = r(i, j);
    float b = r(i + 1.0, j);
    float c = r(i, j + 1.0);
    float d = r(i + 1.0, j + 1.0);
    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = a - b - c + d;
    return vec3(k0 + k1 * u + k2 * v + k3 * u * v, du * (k1 + k3 * v), dv * (k2 + k3 * u));
}

float fbm(in vec2 uv) {
    vec2 p = uv;
    float f, dx, dz, w = 0.5;
    f = dx = dz = 0.0;
    for (int i = 0; i < 3; ++i) {
        vec3 n = dnoise2f(uv);
        dx += n.y;
        dz += n.z;
        f += w * n.x / (1.0 + dx * dx + dz * dz);
        w *= 0.86;
        uv *= vec2(1.36);
        uv *= rot2d(1.25 * noise(vec3(p * 0.1, 0.12 * uTime)) +
            0.75 * noise(vec3(p * 0.1, 0.20 * uTime)));
    }
    return f;
}

float fbmLow(in vec2 uv) {
    float f, dx, dz, w = 0.5;
    f = dx = dz = 0.0;
    for (int i = 0; i < 3; ++i) {
        vec3 n = dnoise2f(uv);
        dx += n.y;
        dz += n.z;
        f += w * n.x / (1.0 + dx * dx + dz * dz);
        w *= 0.95;
        uv *= vec2(3);
    }
    return f;
}

vec2 zoom(in vec2 uv_1, in float zoom) {
    return (uv_1 - vec2(0.5)) / vec2(zoom) + vec2(0.5);
}

void main() {
    float videoAspect = 1920.0 / 1080.0;
    float screenAspect = uViewport.x / uViewport.y;

    vec2 multiplier = vec2(1.0);

    if (videoAspect > screenAspect) {
        multiplier = vec2(screenAspect / videoAspect, 1.0);
    } else {
        // multiplier = vec2(1.0, screenAspect / videoAspect);
    }

    vec2 newUV = (vUv - vec2(0.5)) * multiplier + vec2(0.5);

    vec2 centerVector = vUv - vec2(0.5);

    // Ripples
    vec2 noiseUV = centerVector;

    noiseUV *= rot2d(uTime * 5.5);

    vec2 rv = noiseUV / (length(noiseUV * 10.0) * noiseUV * 20.0);
    float curl = 10.0 * fbm(noiseUV * fbmLow(vec2(length(noiseUV) - uTime + 0.5 * rv)));

    noiseUV *= rot2d(-uTime * 4.5);

    vec2 curlDistortion = fbmLow(noiseUV * curl) * noiseUV * 7.0;

    vec2 insideUV = newUV + 0.1 * centerVector * (2.0 - uCircleScale);

    // newUV += curlDistortion * 0.3;
    // vec2 backgroundUV = newUV + curlDistortion * 0.3;

    // end of ripples

    vec2 circleUV = (vUv - vec2(0.5)) * (1.0, 1.0) +vec2(0.5);

    // float distance = length(circleUV);
    // float distance = smoothstep(0.3, 0.5, length(circleUV));
    float circleProgress = circle(circleUV, uCircleScale, 0.25 + 0.25 * uCircleScale);

    vec2 backgroundUV = newUV + curlDistortion * 0.1 - centerVector * circleProgress - 0.5 * centerVector * uCircleScale;

    vec4 videoTexture = texture2D(uVideo, insideUV);
    vec4 imageTexture = texture2D(uImage, backgroundUV);

    vec4 finalMix = mix(imageTexture, videoTexture, circleProgress);

    // gl_FragColor = imageTexture;
    // gl_FragColor = videoTexture;
    // gl_FragColor = vec4(vec3(circleProgress), 1.0);
    gl_FragColor = vec4(centerVector, 0.0, 1.0);
    gl_FragColor = vec4(fbm(vUv * 100.0), 0.0, 0.0, 1.0);
    gl_FragColor = vec4(curl, 0.0, 0.0, 1.0);
    gl_FragColor = vec4(curlDistortion, 0.0, 1.0);
    gl_FragColor = finalMix;
    // gl_FragColor = vec4(noiseUV, 0.0, 1.0);
}