ANDROID ADAPTIVE ICON — how to install
=======================================
Place files in your Android project's res/ folder:

  res/mipmap-mdpi/ic_launcher.png            (and the other densities)
  res/mipmap-*/ic_launcher_round.png
  res/mipmap-*/ic_launcher_foreground.png
  res/mipmap-*/ic_launcher_monochrome.png
  res/drawable/ic_launcher_background.png    (or use the color in res-values)
  res/mipmap-anydpi-v26/ic_launcher.xml      (provided as ic_launcher.xml)
  res/mipmap-anydpi-v26/ic_launcher_round.xml (copy of ic_launcher.xml)

The foreground art is sized inside the 66dp safe zone, so the launcher mask
(circle, squircle, rounded-square, teardrop) will never clip the crescent or star.
<monochrome> drives Android 13+ themed icons.
