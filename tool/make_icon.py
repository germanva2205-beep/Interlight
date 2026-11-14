from PIL import Image, ImageDraw, ImageFont

S = 1024
img = Image.new("RGB", (S, S))
px = img.load()
a, b = (255, 138, 0), (160, 230, 90)
for y in range(S):
    for x in range(S):
        t = (x + y) / (2 * S)
        px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
d = ImageDraw.Draw(img)
cx, cy, R = S // 2, int(S * 0.45), int(S * 0.30)
d.ellipse((cx - R, cy - R, cx + R, cy + R), fill="white")
o = (245, 124, 0)
d.rounded_rectangle((cx - 55, cy - 120, cx + 55, cy + 30), 55, fill=o)
d.arc((cx - 100, cy - 70, cx + 100, cy + 85), 0, 180, fill=o, width=22)
d.rectangle((cx - 11, cy + 85, cx + 11, cy + 135), fill=o)
d.rounded_rectangle((cx - 60, cy + 125, cx + 60, cy + 145), 10, fill=o)
f = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 90)
d.text((cx, int(S * 0.87)), "H&M", font=f, fill="white", anchor="mm")
img.save("assets/icon.png")
