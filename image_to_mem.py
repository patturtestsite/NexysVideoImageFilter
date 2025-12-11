#!/usr/bin/env python3


from PIL import Image
import sys

def image_to_mem(input_path, output_path, width=320, height=240):

    img = Image.open(input_path)
    img = img.resize((width, height), Image.Resampling.LANCZOS)
    img = img.convert('RGB')
    

    pixels = img.load()
    

    with open(output_path, 'w') as f:

        f.write(f"// Memory initialization file for {width}x{height} image\n")
        f.write(f"// Generated from: {input_path}\n")
        f.write(f"// Format: 24-bit RGB (8R, 8G, 8B)\n\n")

        for y in range(height):
            for x in range(width):
                r, g, b = pixels[x, y]
                

                pixel_value = (r << 16) | (g << 8) | b
                

                f.write(f"{pixel_value:06X}\n")
        
        print(f"✓ Wrote {width}x{height} = {width*height} pixels to {output_path}")
        print(f"  File size: {width*height} words x 24 bits = {width*height*3} bytes")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python image_to_mem.py input_image.jpg output.mem")
        print("Example: python image_to_mem.py test.jpg image_data.mem")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Optional: custom size
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 320
    height = int(sys.argv[4]) if len(sys.argv) > 4 else 240
    
    try:
        image_to_mem(input_file, output_file, width, height)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
