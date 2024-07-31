# PSStringToQRCode.psm1
Function Convert-StringToQR {
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$text,
        [Parameter(Mandatory = $false)][int]$height = 600,
        [Parameter(Mandatory = $false)][int]$width = 600,
        [Parameter(Mandatory = $false)][string]$SaveImageOutput #Validate the path and check extention PNG..
    )
    Begin {

        $moduleBase = (Get-Module PSStringToQRCode).ModuleBase

        # QR Code Generator for .NET
        # By Manuel Bleichenbacher (https://github.com/manuelbl/QrCodeGenerator)
        Add-Type -Path "$moduleBase\Net.Codecrete.QrCodeGenerator\Net.Codecrete.QrCodeGenerator.dll"

        # 2D graphics API for .NET platforms based on Google's Skia Graphics Library
        # By Mono Project (https://github.com/mono/SkiaSharp)
        Add-Type -Path "$moduleBase\SkiaSharp\SkiaSharp.dll"

        # SVG rendering library
        # By Wieslaw Soltes ( https://github.com/wieslawsoltes/Svg.Skia)
        Add-Type -Path "$moduleBase\Svg.Skia\Svg.Skia.dll"
    }
    Process {
        # Generate the SVG from string.
        $qrCode = [Net.Codecrete.QrCodeGenerator.QrCode]::encodeText("$text", [Net.Codecrete.QrCodeGenerator.QrCode+Ecc]::MEDIUM) #Medium error correction.
        $qrCodeSvg = $qrCode.ToSvgString(4)

        # SVG to MemoryStream
        $svgBytes = [System.Text.Encoding]::UTF8.GetBytes($qrCodeSvg)
        $memoryStream = New-Object System.IO.MemoryStream
        $memoryStream.Write($svgBytes, 0, $svgBytes.Length)
        $memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin) > $null
        
        $svg = [Svg.Skia.SKSvg]::new()

        # Load SVG from memory
        $svg.Load($memoryStream)

        # Get the dimensions of the SVG input picture
        $picture = $svg.Picture
        $bounds = $picture.CullRect

        # Create a bitmap matching the dimensions of the input SVG
        $width = [int]$width
        $height = [int]$height
        $bitmap = New-Object SkiaSharp.SKBitmap -ArgumentList $width, $height
        $canvas = [SkiaSharp.SKCanvas]::new($bitmap)
        $canvas.Clear([SkiaSharp.SKColors]::White)

        # Calculate the scale and translate to center the SVG in the canvas
        $scaleX = $width / $bounds.Width
        $scaleY = $height / $bounds.Height
        $scale = [System.Math]::Min($scaleX, $scaleY)
        $translateX = ($width - $bounds.Width * $scale) / 2
        $translateY = ($height - $bounds.Height * $scale) / 2

        # Apply transformations
        $canvas.Scale($scale, $scale)
        $canvas.Translate($translateX / $scale, $translateY / $scale)
        $canvas.DrawPicture($picture)
        $canvas.Flush()

        # Convert it to a PNG
        $image = [SkiaSharp.SKImage]::FromBitmap($bitmap)
        $data = $image.Encode([SkiaSharp.SKEncodedImageFormat]::Png, 100)
    }
    end {        
        if ($SaveImageOutput) {        
            #PNG to file?
            [System.IO.File]::WriteAllBytes($SaveImageOutput, $data.ToArray())
        }
        else {
            #Else, PNG to MemoryStream
            $pngStream = New-Object System.IO.MemoryStream
            $data.SaveTo($pngStream)
            $pngStream.Seek(0, [System.IO.SeekOrigin]::Begin) > $null
        }               
        if (!$SaveImageOutput) {                    
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing
            
            #Create the main form
            $form = New-Object Windows.Forms.Form
            $form.Text = "QR Code [$text]"
            $form.Width = $width + 16
            $form.Height = $height + 39    
            $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

            # Create a PictureBox and set the image
            $pictureBox = New-Object Windows.Forms.PictureBox
            $pictureBox.Width = $width
            $pictureBox.Height = $height
            $pictureBox.Image = [System.Drawing.Bitmap]::FromStream($pngStream)
            $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
            $form.Controls.Add($pictureBox)
            $form.add_FormClosed({
                #Cleanup?
            })

            # Show the form
            [void]$form.ShowDialog()
        }
    }
}
