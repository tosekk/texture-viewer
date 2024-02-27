package main

import "core:fmt"
import la "core:math/linalg"

import rl "vendor:raylib"


// CONSTANTS
SCREEN_WIDTH: f32: 800
SCREEN_HEIGHT: f32: 700
APP_TITLE: cstring: "Texture Viewer"
BG_COLOR: rl.Color: { 240, 240, 240, 255 }
PRIMARY_COLOR: rl.Color: { 40, 40, 40, 255 }
SECONDARY_COLOR: rl.Color: { 120, 120, 120, 255 }
ACCENT_COLOR: rl.Color: { 180, 180, 180, 255 }
SECOND_ACCENT_COLOR: rl.Color: { 200, 200, 200, 255 }
NO_TINT: rl.Color: { 255, 255, 255, 255 }


// Structs
TextureFormat :: struct {
    pixelFormat: rl.PixelFormat,
    text: cstring,
    bits: i32
}

Text :: struct {
    text: cstring,
    x: i32,
    y: i32
}


main :: proc() {
    rl.InitWindow(i32(SCREEN_WIDTH), i32(SCREEN_HEIGHT), APP_TITLE)
    rl.SetTargetFPS(120)

    // Texture
    image: rl.Image = rl.LoadImage("D.png")
    rl.ImageFormat(&image, rl.PixelFormat.UNCOMPRESSED_R32G32B32)
    texture: rl.Texture2D = rl.LoadTextureFromImage(image)
    texture.format = rl.PixelFormat.UNCOMPRESSED_R32G32B32
    texPos: la.Vector2f32 = { 80, 80 }

    originalWidth: i32 = texture.width
    originalHeight: i32 = texture.height

    // Channel Texture
    channelTexture: rl.RenderTexture2D = rl.LoadRenderTexture(originalWidth, originalHeight)
    imageColors: [^]rl.Color = rl.LoadImageColors(image)

    rl.BeginTextureMode(channelTexture)
        for x in 0..=(originalWidth - 1) {
            for y in 0..=(originalHeight - 1) {
                rl.DrawPixelV({ f32(x), f32(originalHeight - y) }, imageColors[x + (y * image.height)])
            }
        }
    rl.EndTextureMode()

    // Data
    // Texture format
    textureFormats := [17]TextureFormat{
        TextureFormat{ rl.PixelFormat.COMPRESSED_ASTC_4x4_RGBA, "ASTC 4x4", 8 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_ASTC_8x8_RGBA, "ASTC 8x8", 2 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_ASTC_8x8_RGBA, "DXT1 RGB", 4 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_DXT1_RGBA, "DXT1 RGBA", 4 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_DXT3_RGBA, "DXT3", 8 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_DXT5_RGBA, "DXT5", 8 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_ETC1_RGB, "ETC1", 4 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_ETC2_EAC_RGBA, "ETC2 RGBA", 8 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_ETC2_RGB, "ETC2 RGB", 4 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_PVRT_RGB, "PVRT RGB", 4 },
        TextureFormat{ rl.PixelFormat.COMPRESSED_PVRT_RGBA, "PVRT RGBA", 4 },
        TextureFormat{ rl.PixelFormat.UNCOMPRESSED_GRAY_ALPHA, "Alpha", 16 },
        TextureFormat{ rl.PixelFormat.UNCOMPRESSED_GRAYSCALE, "Grayscale", 8  },
        TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R32G32B32, "32-bit", 96 },
        TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R32G32B32A32, "32-bit with alpha", 128 },
        TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R8G8B8, "8-bit", 24 },
        TextureFormat{ rl.PixelFormat.UNCOMPRESSED_R8G8B8A8, "8-bit with alpha", 32 } }

    texFormat := getTextureFormat(texture.format)
    
    // Memory footprint
    textureKB: f32 = getTextureFootprint({ originalWidth, originalHeight }, texFormat.bits)

    // Downscale texture to fit viewer
    texture.width = 400
    texture.height = 400

    // GUI
    // Compression
    compressionSelected: rl.Rectangle = { 560, 160, 160, 25 }
    compressionsToSelect: [dynamic]rl.Rectangle
    mouseOverCompression: bool = false
    selectingCompression: bool = false
    
    selectedTextX, selectedTextY := calculateTextPosition(texFormat.text, 12, compressionSelected)
    
    for i in 1..=len(textureFormats) {
        compressionRec: rl.Rectangle = { compressionSelected.x, compressionSelected.y + f32(i) * compressionSelected.height,
            compressionSelected.width, compressionSelected.height }
        append(&compressionsToSelect, compressionRec)   
    }

    // Channels
    channelR: rl.Rectangle = { 560, 100, 30, 30 }
    channelG: rl.Rectangle = { 595, 100, 30, 30 }
    channelB: rl.Rectangle = { 630, 100, 30, 30 }
    channelA: rl.Rectangle = { 665, 100, 30, 30 }
    channels: [4]rl.Rectangle = { channelR, channelG, channelB, channelA }

    rText: cstring = "R"
    rTextX, rTextY: i32 = calculateTextPosition(rText, 12, channelR)
    gText: cstring = "G"
    gTextX, gTextY: i32 = calculateTextPosition(gText, 12, channelG)
    bText: cstring = "B"
    bTextX, bTextY: i32 = calculateTextPosition(bText, 12, channelB)
    aText: cstring = "A"
    aTextX, aTextY: i32 = calculateTextPosition(aText, 12, channelA)
    channelTexts: [4]Text = {Text{rText, rTextX, rTextY},
                            Text{gText, gTextX, gTextY},
                            Text{bText, bTextX, bTextY},
                            Text{aText, aTextX, aTextY}}

    rgba: [4]u8 = { 1, 1, 1, 1 }

    // Dropped Files
    dropped: bool = false
    newImagePath: cstring
    
        
    for !rl.WindowShouldClose() {
        mouseOverMethod: bool
        mouseOverChannel: bool

        mousePos: la.Vector2f32 = rl.GetMousePosition()
        
        mouseOverCompression = rl.CheckCollisionPointRec(mousePos, compressionSelected)

        rl.SetMouseCursor(rl.MouseCursor.DEFAULT)

        if !dropped {
            if rl.IsFileDropped() {
                files := rl.LoadDroppedFiles()

                newImagePath = files.paths[0]

                image = rl.LoadImage(newImagePath)
                texture = rl.LoadTextureFromImage(image)
                texture.width, texture.height = 400, 400
                imageColors = rl.LoadImageColors(image)

                rl.UnloadDroppedFiles(files)

                dropped = true
            } 
        }

        if mouseOverCompression {
            rl.SetMouseCursor(rl.MouseCursor.POINTING_HAND)
        }
        
        if selectingCompression {
            rl.SetMouseCursor(rl.MouseCursor.POINTING_HAND)

            for i in 0..=(len(compressionsToSelect) - 1) {
                compRec: rl.Rectangle = compressionsToSelect[i]
                
                mouseOverMethod = rl.CheckCollisionPointRec(mousePos, compRec)
                
                if mouseOverMethod {
                    rl.DrawRectangleRec(compressionsToSelect[i], SECONDARY_COLOR)

                    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                        texture.format = textureFormats[i].pixelFormat
                        texFormat = getTextureFormat(texture.format)
                        textureKB = getTextureFootprint({ originalWidth, originalHeight }, texFormat.bits)

                        selectedTextX, selectedTextY = calculateTextPosition(texFormat.text, 12, compressionSelected)
                        selectingCompression = false
                        break
                    }
                } else {
                    rl.DrawRectangleRec(compressionsToSelect[i], SECOND_ACCENT_COLOR)
                }
            }
        }

        for channel in channels {
            mouseOverChannel = rl.CheckCollisionPointRec(mousePos, channel)

            if mouseOverChannel {
                rl.SetMouseCursor(rl.MouseCursor.POINTING_HAND)
                break
            }
        }
        
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            if !mouseOverCompression {
                selectingCompression = false
            } else {
                rl.DrawRectangleRec(compressionSelected, SECONDARY_COLOR)
                selectingCompression = !selectingCompression
            }

            if rl.CheckCollisionPointRec(mousePos, channelR) {
                rgba[0] = 1 - rgba[0]
                paintTextureChannels(channelTexture, imageColors, rgba[0], rgba[1], rgba[2], rgba[3], originalHeight, originalWidth)
                channelTexture.texture.format = texFormat.pixelFormat
                texture = channelTexture.texture
                texture.width, texture.height = 400, 400
            }

            if rl.CheckCollisionPointRec(mousePos, channelG) {
                rgba[1] = 1 - rgba[1]
                paintTextureChannels(channelTexture, imageColors, rgba[0], rgba[1], rgba[2], rgba[3], originalHeight, originalWidth)
                channelTexture.texture.format = texFormat.pixelFormat
                texture = channelTexture.texture
                texture.width, texture.height = 400, 400
            }

            if rl.CheckCollisionPointRec(mousePos, channelB) {
                rgba[2] = 1 - rgba[2]
                paintTextureChannels(channelTexture, imageColors, rgba[0], rgba[1], rgba[2], rgba[3], originalHeight, originalWidth)
                channelTexture.texture.format = texFormat.pixelFormat
                texture = channelTexture.texture
                texture.width, texture.height = 400, 400
            }
            if rl.CheckCollisionPointRec(mousePos, channelA) {
                rgba[3] = 1 - rgba[3]
                paintTextureChannels(channelTexture, imageColors, rgba[0], rgba[1], rgba[2], rgba[3], originalHeight, originalWidth)
                channelTexture.texture.format = texFormat.pixelFormat
                texture = channelTexture.texture
                texture.width, texture.height = 400, 400
            }
        }

        // Drawing
        rl.BeginDrawing()

            rl.ClearBackground(BG_COLOR)

            rl.DrawTextureV(texture, texPos, NO_TINT)
            
            // VRAM Footprint
            rl.DrawText(rl.TextFormat("VRAM Footprint: %.2f KB", textureKB), 560, 200, 12, PRIMARY_COLOR)

            // Channels
            rl.DrawText("Channels", 560, 80, 12, PRIMARY_COLOR)

            for channel in channels {
                rl.DrawRectangleRec(channel, SECOND_ACCENT_COLOR)
            }

            for channelText in channelTexts {
                rl.DrawText(channelText.text, channelText.x, channelText.y, 12, PRIMARY_COLOR)
            }

            // Compression
            rl.DrawText("Compression", 560, 140, 12, PRIMARY_COLOR)
            rl.DrawRectangleRec(compressionSelected, ACCENT_COLOR)
            rl.DrawText(texFormat.text, selectedTextX, selectedTextY, 12, PRIMARY_COLOR)

            if selectingCompression {
                for i in 0..=(len(compressionsToSelect) - 1) {
                    compRec: rl.Rectangle = compressionsToSelect[i]

                    mouseOverMethod = rl.CheckCollisionPointRec(mousePos, compRec)
                     
                    if mouseOverMethod {
                        rl.DrawRectangleRec(compressionsToSelect[i], SECONDARY_COLOR)
                    } else {
                        rl.DrawRectangleRec(compressionsToSelect[i], SECOND_ACCENT_COLOR)
                    }
                    
                    text: cstring = textureFormats[i].text
                    textX, textY := calculateTextPosition(text, 12, compRec)
                    rl.DrawText(text, textX, textY, 12, PRIMARY_COLOR)
                }
            }

        rl.EndDrawing()
    }

    rl.UnloadImageColors(imageColors)
    rl.UnloadRenderTexture(channelTexture)
    rl.UnloadTexture(texture)
    rl.CloseWindow()
}