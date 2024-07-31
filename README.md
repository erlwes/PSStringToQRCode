# PSStringToQRCode
PowerShell-module for converting text strings to QR-code and display it on screen, or save it as a .PNG-image.

## All the heavy lifting is done these Git-hub projects:
* Net.Codecrete.QrCodeGenerator by Manuel Bl. (https://github.com/manuelbl/QrCodeGenerator)
* SkiaSharp by Mono Project (https://github.com/mono/SkiaSharp)
* Svg.Skia by Wiesław Šoltés (https://github.com/wieslawsoltes/Svg.Skia)

All credits to the respectfull creators of the assemly-code used.
I simply pieced it together, so that it will perform a very specific task in PowerShell :)

## Install
```PowerShell
install-Module -Name PSStringToQRCode
```

## Example

This:

![image](https://github.com/user-attachments/assets/dda75ae4-056f-40bc-ba7d-8dcec504dfcf)


Results in this:

![image](https://github.com/user-attachments/assets/ccaaf53b-3f1e-4e6a-8ccf-cca43af1d391)
