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

## Functions

### 🟢 Convert-StringToQR
Converts text strings to QR-code and display it on screen.

Parameter | Description
--- | ---
text (mandatory) | The input text `(string)`
height | Height in px`(int)`
width | Width in px`(int)`
SaveImageOutput | Outputs PNG-file to specified path. Path must contain filename .png-extension `(string)`

**Usage**
Generates a 200x200px QR-code and saves it as .png-image file.
```PowerShell
"let's get schwifty" | Convert-StringToQR -SaveImageOutput c:\temp\swifty.png -height 200 -width 200
```
Generates a QR-code and displays it on the screen
```PowerShell
Convert-StringToQR -text "manage-bde –unlock c: -RecoveryPassword 002130-563959-533643-315590-484044-259380-247291-123563"
```

## 🔵 Example 1

This:

![image](https://github.com/user-attachments/assets/dda75ae4-056f-40bc-ba7d-8dcec504dfcf)

Results in this:

![image](https://github.com/user-attachments/assets/ccaaf53b-3f1e-4e6a-8ccf-cca43af1d391)

Another one QR code could contain `cd c:\windows\system32\drivers\crowdstrike && del c-00000291*.sys` etc.


## 🔵 Example 2

This:

![image](https://github.com/user-attachments/assets/fe548635-ef8e-48e9-adad-56a89de1af7e)


Results in this:

![image](https://github.com/user-attachments/assets/4d1f91d4-7782-4338-b633-830d027d0e5f)
