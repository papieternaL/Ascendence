// CRT Scanline Effect Shader
// Adds horizontal scanlines for a retro CRT monitor look

extern float intensity = 0.15; // How dark the scanlines are (0.0 - 1.0)

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Get the original pixel color
    vec4 pixel = Texel(texture, texture_coords) * color;
    
    // Create scanline pattern - every 2 pixels
    float scanline = mod(floor(screen_coords.y), 2.0);
    
    // Darken every other line
    float darken = 1.0 - (scanline * intensity);
    
    // Apply scanline effect
    pixel.rgb *= darken;
    
    // Optional: Add slight vertical gradient for CRT curvature illusion
    float height = love_ScreenSize.y;
    float vignette = 1.0 - (abs(screen_coords.y - height * 0.5) / (height * 0.5)) * 0.15;
    pixel.rgb *= vignette;
    
    return pixel;
}

