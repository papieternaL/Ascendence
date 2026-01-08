// 16-Color Palette Quantization Shader
// Warm Autumn Palette with bright player accent

// 16-color autumn palette (browns, oranges, olives, with cyan for player)
const vec3 palette[16] = vec3[16](
    vec3(0.094, 0.094, 0.094), // 0: Near Black (dark shadows)
    vec3(0.259, 0.165, 0.110), // 1: Dark Brown (tree trunks)
    vec3(0.431, 0.282, 0.184), // 2: Medium Brown (wood)
    vec3(0.678, 0.522, 0.361), // 3: Light Brown (tan/sand)
    
    vec3(0.584, 0.318, 0.141), // 4: Burnt Sienna (autumn leaves)
    vec3(0.831, 0.522, 0.247), // 5: Orange (bright leaves)
    vec3(0.941, 0.753, 0.529), // 6: Peach/Cream (highlights)
    vec3(0.976, 0.906, 0.788), // 7: Pale Cream (bright highlights)
    
    vec3(0.388, 0.420, 0.239), // 8: Olive Green (forest floor)
    vec3(0.529, 0.588, 0.341), // 9: Sage Green (foliage)
    vec3(0.698, 0.349, 0.184), // 10: Rust (deep autumn)
    vec3(0.843, 0.682, 0.282), // 11: Golden Yellow (sun-touched)
    
    vec3(0.141, 0.329, 0.388), // 12: Dark Teal (player shadow)
    vec3(0.200, 0.600, 0.800), // 13: Cyan (PLAYER - stands out!)
    vec3(0.478, 0.239, 0.239), // 14: Maroon (dark red)
    vec3(0.729, 0.333, 0.333)  // 15: Rusty Red (enemy accents)
);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Get the original pixel color
    vec4 pixel = Texel(texture, texture_coords) * color;
    
    // If pixel is transparent, keep it transparent
    if (pixel.a < 0.01) {
        return pixel;
    }
    
    // Find closest color in palette
    float minDistance = 9999.0;
    int closestIndex = 0;
    
    for (int i = 0; i < 16; i++) {
        // Calculate color distance (using weighted RGB distance)
        vec3 diff = pixel.rgb - palette[i];
        float distance = dot(diff, diff); // Squared distance for performance
        
        if (distance < minDistance) {
            minDistance = distance;
            closestIndex = i;
        }
    }
    
    // Return the closest palette color
    return vec4(palette[closestIndex], pixel.a);
}

