# Boosts Feature Implementation - Color Tinting for Websites

## Overview

This document describes the implementation of the **Boosts** feature, which allows users to apply custom color tints to any website, similar to Arc Browser's Boosts functionality. This feature leverages DarkReader's sophisticated color processing algorithm to blend website colors with user-selected tint colors at adjustable strengths.

## What is Color Tinting?

Color tinting allows users to:
- Choose any color to tint/colorize entire websites
- Adjust the strength of the tint from 0-100%
- Create aesthetic overlays that shift the entire color palette toward a specific hue
- Maintain readability while changing the visual appearance

Think of it as applying a color filter or mood overlay to any website, perfect for personalization or accessibility needs.

## Implementation Details

### 1. Core Type Definitions

**File: `/workspace/src/definitions.d.ts`**

Added two new properties to the `Theme` interface:
- `tintColor: string` - The color to use for tinting (hex, rgb, or color name)
- `tintStrength: number` - The strength of the tint (0-100)

### 2. Default Values

**File: `/workspace/src/defaults.ts`**

Set default values in `DEFAULT_THEME`:
- `tintColor: ''` - No tint by default (empty string)
- `tintStrength: 0` - 0% strength by default

### 3. Color Processing Algorithm

**File: `/workspace/src/inject/dynamic-theme/modify-colors.ts`**

#### Key Changes:

1. **Updated Theme Cache Keys**: Added `tintColor` and `tintStrength` to the theme cache keys for proper caching behavior.

2. **New `applyTint()` Function**: 
   - Blends the original HSL color with the tint color
   - Uses circular hue blending (accounting for 0-360° wraparound)
   - Applies weighted blending:
     - **Hue**: 60% influence from tint color
     - **Saturation**: 50% influence from tint color  
     - **Lightness**: 20% influence from tint color (preserves readability)
   - Strength parameter controls overall blend intensity

3. **Modified `modifyColorWithCache()` Function**:
   - Now applies tinting after the standard color modification
   - Only applies tint if `tintColor` is set and `tintStrength` > 0

#### Algorithm Details:

```typescript
function applyTint(hsl: HSLA, tintColor: string, tintStrength: number): HSLA {
    // Parse tint color
    const tintRGB = parseToHSLWithCache(tintColor);
    
    // Normalize strength to 0-1 range
    const strength = Math.min(100, Math.max(0, tintStrength)) / 100;
    
    // Circular hue blending
    let hueDiff = tintRGB.h - hsl.h;
    if (hueDiff > 180) hueDiff -= 360;
    else if (hueDiff < -180) hueDiff += 360;
    const newHue = (hsl.h + hueDiff * strength * 0.6) % 360;
    
    // Saturation blending (50% influence)
    const newSaturation = hsl.s + (tintRGB.s - hsl.s) * strength * 0.5;
    
    // Lightness blending (20% influence - preserves readability)
    const newLightness = hsl.l + (tintRGB.l - hsl.l) * strength * 0.2;
    
    return { h: newHue, s: newSaturation, l: newLightness, a: hsl.a };
}
```

### 4. User Interface Controls

#### New UI Components:

**File: `/workspace/src/ui/popup/theme/controls/tint-color.tsx`**
- Color picker component for selecting the tint color
- Displays current tint color with preview
- Includes reset button to clear tint

**File: `/workspace/src/ui/popup/theme/controls/tint-strength.tsx`**
- Slider component for adjusting tint strength (0-100%)
- Shows percentage value
- Real-time preview as you adjust

**File: `/workspace/src/ui/popup/theme/controls/index.tsx`**
- Exports the new tint controls

#### UI Integration:

**File: `/workspace/src/ui/popup/theme/page/index.tsx`**

Added new collapsible section "Boosts (Color Tinting)" that includes:
- `TintColor` - Color picker for selecting tint
- `TintStrength` - Slider for adjusting strength

The Boosts section appears between "Brightness, contrast, mode" and "Colors" sections for easy access.

## How to Use

1. **Enable Dark Reader** on any website
2. **Click the Dark Reader icon** to open the popup
3. **Navigate to the Theme tab** (if not already there)
4. **Expand "Boosts (Color Tinting)"** section
5. **Choose a tint color** using the color picker
6. **Adjust tint strength** using the slider (0-100%)
7. Watch as the website's colors shift toward your chosen tint!

## Example Use Cases

- **Blue Tint**: Create a calm, focused browsing experience
- **Warm Tint**: Reduce eye strain with orange/amber tones
- **Green Tint**: Forest/nature aesthetic
- **Pink/Purple Tint**: Aesthetic customization
- **Custom Brand Colors**: Match websites to your personal brand

## Technical Highlights

1. **Performance**: Utilizes DarkReader's existing caching system for optimal performance
2. **Compatibility**: Works with all DarkReader theme modes and engines
3. **Precision**: HSL color space ensures smooth, natural-looking color transitions
4. **Flexibility**: Supports any color input format (hex, rgb, named colors)
5. **Preservation**: Carefully weighted blending preserves readability and contrast

## Build Status

✅ **Successfully Built**
- All TypeScript compilation passed
- No linting errors
- Build artifacts generated in `/workspace/build/`

## Future Enhancements (Optional)

- Add preset tint colors (Quick access buttons)
- Multiple tint layers with different blend modes
- Per-element tinting (advanced mode)
- Animated tint transitions
- Save favorite tint combinations as presets
- Schedule-based tinting (e.g., warmer tones at night)

## Testing Recommendations

Test the feature on various types of websites:
- Text-heavy sites (blogs, news)
- Image-heavy sites (portfolios, galleries)  
- Web applications (Google Docs, GitHub)
- Dark theme websites
- Light theme websites
- Mixed content sites

Try different tint colors:
- Primary colors (red, blue, green)
- Secondary colors (orange, purple, cyan)
- Neutral tones (gray, beige)
- Extreme values (very saturated vs desaturated)

Test different strength levels:
- Subtle: 10-30%
- Moderate: 40-60%
- Strong: 70-90%
- Maximum: 100%

---

**Implementation Date**: 2025-11-11
**Developer**: AI Assistant (Claude)
**Status**: ✅ Complete and Ready for Testing
