// SPDX-License-Identifier: GPL-3.0-or-later
// A picture on the round 25 x 25 glyph matrix: each dot takes the brightness
// of the picture under its centre. Rebuild with:
//   qsb --qt6 -o matrix.frag.qsb matrix.frag
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 lit;
    vec4 unlit;
};
layout(binding = 1) uniform sampler2D source;

const float cells = 25.0;

void main() {
    vec2 grid = qt_TexCoord0 * cells;
    vec2 cell = floor(grid);
    vec2 middle = cell + 0.5 - cells * 0.5;
    if (dot(middle, middle) > cells * cells * 0.25) {
        fragColor = vec4(0.0);
        return;
    }
    vec4 picture = texture(source, (cell + 0.5) / cells);
    float level = dot(picture.rgb, vec3(0.2126, 0.7152, 0.0722)) * picture.a;
    float disc = 1.0 - smoothstep(0.34, 0.42, length(fract(grid) - 0.5));
    // Colour uniforms arrive premultiplied, as the output wants them.
    fragColor = mix(unlit, lit, level) * disc * qt_Opacity;
}
