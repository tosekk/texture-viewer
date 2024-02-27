package main

import la "core:math/linalg"

import rl "vendor:raylib"


getTextureFormat :: proc(texFormat: rl.PixelFormat) -> TextureFormat {
    #partial switch texFormat {
        case rl.PixelFormat.COMPRESSED_ASTC_4x4_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_ASTC_4x4_RGBA, "ASTC 4x4", 8 }
        case rl.PixelFormat.COMPRESSED_ASTC_8x8_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_ASTC_8x8_RGBA, "ASTC 8x8", 2 }
        case rl.PixelFormat.COMPRESSED_DXT1_RGB:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_ASTC_8x8_RGBA, "DXT1 RGB", 4 }
        case rl.PixelFormat.COMPRESSED_DXT1_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_DXT1_RGBA, "DXT1 RGBA", 4 }
        case rl.PixelFormat.COMPRESSED_DXT3_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_DXT3_RGBA, "DXT3", 8 }
        case rl.PixelFormat.COMPRESSED_DXT5_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_DXT5_RGBA, "DXT5", 8 }
        case rl.PixelFormat.COMPRESSED_ETC1_RGB:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_ETC1_RGB, "ETC1", 4 }
        case rl.PixelFormat.COMPRESSED_ETC2_EAC_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_ETC2_EAC_RGBA, "ETC2 RGBA", 8 }
        case rl.PixelFormat.COMPRESSED_ETC2_RGB:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_ETC2_RGB, "ETC2 RGB", 4 }
        case rl.PixelFormat.COMPRESSED_PVRT_RGB:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_PVRT_RGB, "PVRT RGB", 4 }
        case rl.PixelFormat.COMPRESSED_PVRT_RGBA:
            return TextureFormat{ rl.PixelFormat.COMPRESSED_PVRT_RGBA, "PVRT RGBA", 4 }
        case rl.PixelFormat.UNCOMPRESSED_GRAY_ALPHA:
            return TextureFormat{ rl.PixelFormat.UNCOMPRESSED_GRAY_ALPHA, "Alpha", 16 }
        case rl.PixelFormat.UNCOMPRESSED_GRAYSCALE:
            return TextureFormat{ rl.PixelFormat.UNCOMPRESSED_GRAYSCALE, "Grayscale", 8  }
        case rl.PixelFormat.UNCOMPRESSED_R32G32B32:
            return TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R32G32B32, "32-bit", 96 }
        case rl.PixelFormat.UNCOMPRESSED_R32G32B32A32:
            return TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R32G32B32A32, "32-bit with alpha", 128 }
        case rl.PixelFormat.UNCOMPRESSED_R8G8B8:
            return TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R8G8B8, "8-bit", 24 }
        case rl.PixelFormat.UNCOMPRESSED_R8G8B8A8:
            return TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R8G8B8A8, "8-bit with alpha", 32 }
    }

    return TextureFormat{ rl.PixelFormat.UNKNOWN, "UNKNOWN", 0 }
}

getTextureFootprint :: proc(textureDimensions: [2]i32, bits: i32) -> f32 {
    textureBits: i32 = textureDimensions.x * textureDimensions.y * bits
    textureBytes: f32 = f32(textureBits) / 8
    textureKB: f32 = f32(textureBytes) / 1024

    return textureKB
}

paintTextureChannels :: proc(renderTexture: rl.RenderTexture2D, imageColors: [^]rl.Color, r, g, b, a: u8, height, width: i32) {
    rl.BeginTextureMode(renderTexture)
        for x in 0..=(width - 1) {
            for y in 0..=(height - 1) {
                index: i32 = x + (y * height)
                pxlColor: rl.Color = { r * imageColors[index].r, g * imageColors[index].g, b * imageColors[index].b, a * imageColors[index].a }
                rl.DrawPixelV({ f32(x), f32(height - y) }, pxlColor)
            }
        }
    rl.EndTextureMode()
}

calculateTextPosition :: proc(text: cstring, font: i32, rec: rl.Rectangle) -> (i32, i32) {
    textLength: i32 = rl.MeasureText(text, font)
    posX: i32 = i32(rec.x) + ((i32(rec.width) - textLength) / 2)
    posY: i32 = i32(rec.y) + ((i32(rec.height) - 12) / 2)

    return posX, posY
}