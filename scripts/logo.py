# Prépare l'icône et l'écran de démarrage à partir du logo officiel d'EnfinToi (enfintoi.com/icons/icon-512.png).
import sys
from PIL import Image, ImageFilter
src = Image.open(sys.argv[1]).convert("RGBA")
white = Image.new("RGBA", src.size, (255, 255, 255, 255))
logo = Image.alpha_composite(white, src).convert("RGB")
# Icône 1024 x 1024, fond blanc, sans transparence
icon = logo.resize((1024, 1024), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
icon.save("assets/icon-only.png")
icon.save("assets/icon-foreground.png")
Image.new("RGB", (1024, 1024), (255, 255, 255)).save("assets/icon-background.png")
# Écran de démarrage 2732 x 2732 : logo centré sur fond blanc
splash = Image.new("RGB", (2732, 2732), (255, 255, 255))
big = logo.resize((900, 900), Image.LANCZOS)
splash.paste(big, ((2732 - 900) // 2, (2732 - 900) // 2))
splash.save("assets/splash.png")
splash.save("assets/splash-dark.png")
print("Logo EnfinToi prêt")
