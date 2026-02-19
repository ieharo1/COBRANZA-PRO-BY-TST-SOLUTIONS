from PIL import Image, ImageDraw, ImageFont
import os

# Create assets directory if not exists
os.makedirs("assets", exist_ok=True)

# iOS icon sizes
ios_sizes = [
    (20, "Icon-App-20x20@1x.png"),
    (40, "Icon-App-20x20@2x.png"),
    (60, "Icon-App-20x20@3x.png"),
    (29, "Icon-App-29x29@1x.png"),
    (58, "Icon-App-29x29@2x.png"),
    (87, "Icon-App-29x29@3x.png"),
    (40, "Icon-App-40x40@1x.png"),
    (80, "Icon-App-40x40@2x.png"),
    (120, "Icon-App-40x40@3x.png"),
    (76, "Icon-App-76x76@1x.png"),
    (152, "Icon-App-76x76@2x.png"),
    (167, "Icon-App-83.5x83.5@2x.png"),
    (1024, "Icon-App-1024x1024@1x.png"),
]

# Base colors
bg_color = (21, 101, 192)  # #1565C0 - Blue
fg_color = (255, 255, 255)  # White


def create_icon(size):
    # Create image with background color
    img = Image.new("RGBA", (size, size), bg_color)
    draw = ImageDraw.Draw(img)

    # Draw rounded rectangle background
    margin = max(2, size // 16)
    inner_size = size - (margin * 2)

    try:
        font_size = size // 2
        font = ImageFont.truetype("arialbd.ttf", font_size)
    except:
        font = ImageFont.load_default()

    # Draw "CP" text
    text = "CP"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = (size - text_width) // 2 - bbox[0]
    text_y = (size - text_height) // 2 - bbox[1]

    # Draw shadow
    shadow_offset = max(1, size // 32)
    draw.text(
        (text_x + shadow_offset, text_y + shadow_offset),
        text,
        font=font,
        fill=(0, 0, 0, 80),
    )

    # Draw main text
    draw.text((text_x, text_y), text, font=font, fill=fg_color)

    return img


# Create icons for iOS
for size, filename in ios_sizes:
    img = create_icon(size)
    output_path = f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{filename}"
    img.save(output_path, "PNG")
    print(f"Created: {filename}")

# Create icons for Android
sizes = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

for density, size in sizes.items():
    img = create_icon(size)
    output_path = f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
    img.save(output_path, "PNG")
    print(f"Created: mipmap-{density}/ic_launcher.png")

# Create adaptive icon foreground
img = create_icon(192)
img.save("assets/icon_foreground.png", "PNG")
print("Created: icon_foreground.png")

# Create simple icon
img = create_icon(192)
img.save("assets/icon.png", "PNG")
print("Created: icon.png")

print("\nAll iOS and Android icons created successfully!")
