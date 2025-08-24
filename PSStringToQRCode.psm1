<#
.SYNOPSIS
Creates a QR code image from a string and either shows it, saves it, or returns it as a stream.

.DESCRIPTION
Convert-StringToQR takes input text, renders an SVG QR code, rasterizes it with SkiaSharp,
and encodes it to PNG. You can:
- Preview it in a Windows Form (default),
- Save it to disk (-SaveImageOutput),
- Or get a raw PNG MemoryStream suitable for piping or embedding (-StreamOutput).

.INPUTS
System.String
You can pipe strings directly to the function.

.OUTPUTS
System.IO.Stream
Returns a MemoryStream containing PNG data when -StreamOutput is used.
Otherwise, no output is written to the pipeline.

.PARAMETER Text
The text content to encode into the QR code.

.PARAMETER Height
PNG image height in pixels. Default: 600.

.PARAMETER Width
PNG image width in pixels. Default: 600.

.PARAMETER SaveImageOutput
Full path to save the PNG file. If provided, the QR is written to this path.

.PARAMETER StreamOutput
When specified, the function returns a MemoryStream that contains the PNG.

.EXAMPLE
PS> Convert-StringToQR -Text "Hello world"
Opens preview-window showing the QR code for "Hello world".

.EXAMPLE
PS> Get-EntraBitLockerKeys | Convert-StringToQR
Gets output string from "Get-EntraBitLockerKeys" and opens a preview-windows with the QR-code that represents input string.

.EXAMPLE
PS> Convert-StringToQR "Ninja turtles!" -Height 200 -Width 200 -SaveImageOutput "C:\temp\qr.png"
Creates a 200x200 PNG and saves it to C:\temp\qr.png.

.EXAMPLE
PS> Convert-StringToQR 'Ninja Turtles' -height 250 -width 250 -StreamOutput | ConvertTo-Sixel
Outputs image as stream and displays it in console using "Sixel" PowerShell-module (Sixel has to be installed separatley)


.NOTES
Author: Erlend Westervik
Dependencies: Net.Codecrete.QrCodeGenerator, SkiaSharp, Svg.Skia
Dispose: Native Skia resources are disposed internally.

Version history:
  1.0.1 - 31/07/2024 - Initial development
  1.0.2 - 24/08/2025 - Added switch to output image as a stream, removed unnessasary output, added alias so that PSStringToQRCode = Convert-StringToQR, so that its easier to find cmdlet after installing module.

.LINK
https://github.com/erlwes/PSStringToQRCode

#>

function Convert-StringToQR {
    [CmdletBinding()]
    [OutputType([System.IO.Stream])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][string]$Text,
        [int]$Height = 600,
        [int]$Width  = 600,
        [string]$SaveImageOutput,
        [switch]$StreamOutput
    )
    begin {
        $moduleBase = (Get-Module PSStringToQRCode).ModuleBase

        Add-Type -Path (Join-Path $moduleBase 'Net.Codecrete.QrCodeGenerator\Net.Codecrete.QrCodeGenerator.dll')
        Add-Type -Path (Join-Path $moduleBase 'SkiaSharp\SkiaSharp.dll')
        Add-Type -Path (Join-Path $moduleBase 'Svg.Skia\Svg.Skia.dll')
    }
    process {
        #=== Build SVG in-memory ===#
        $qrCode    = [Net.Codecrete.QrCodeGenerator.QrCode]::encodeText($Text, [Net.Codecrete.QrCodeGenerator.QrCode+Ecc]::MEDIUM)
        $qrCodeSvg = $qrCode.ToSvgString(4)

        $memoryStream = [System.IO.MemoryStream]::new()
        try {
            $svgBytes = [System.Text.Encoding]::UTF8.GetBytes($qrCodeSvg)
            [void]$memoryStream.Write($svgBytes, 0, $svgBytes.Length)
            [void]$memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin)

            $svg = [Svg.Skia.SKSvg]::new()
            try {
                # IMPORTANT: suppress pipeline output from Load()
                [void]$svg.Load($memoryStream)

                $picture = $svg.Picture
                $bounds  = $picture.CullRect

                #=== Render SVG to bitmap ===#
                $bmp     = [SkiaSharp.SKBitmap]::new([int]$Width, [int]$Height)
                $canvas  = [SkiaSharp.SKCanvas]::new($bmp)
                try {
                    $canvas.Clear([SkiaSharp.SKColors]::White)

                    $scaleX = $Width  / $bounds.Width
                    $scaleY = $Height / $bounds.Height
                    $scale  = [Math]::Min($scaleX, $scaleY)
                    $tx     = ($Width  - $bounds.Width  * $scale) / 2
                    $ty     = ($Height - $bounds.Height * $scale) / 2

                    $canvas.Scale($scale, $scale)     | Out-Null
                    $canvas.Translate($tx / $scale, $ty / $scale) | Out-Null
                    $canvas.DrawPicture($picture)     | Out-Null
                    $canvas.Flush()                    | Out-Null

                    #=== Encode to PNG ===#
                    $image = [SkiaSharp.SKImage]::FromBitmap($bmp)
                    try {
                        $data = $image.Encode([SkiaSharp.SKEncodedImageFormat]::Png, 100)
                        try {
                            #--- Output selection ---#
                            if ($StreamOutput.IsPresent) {
                                # return a MemoryStream containing the PNG
                                $pngStream = [System.IO.MemoryStream]::new()
                                $data.SaveTo($pngStream)
                                [void]$pngStream.Seek(0, [System.IO.SeekOrigin]::Begin)
                                return $pngStream
                            }
                            elseif ($SaveImageOutput) {
                                # save to file (without printing anything)
                                $fs = [System.IO.File]::Open($SaveImageOutput, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                                try {
                                    $data.SaveTo($fs)
                                    $fs.Flush()
                                }
                                finally { $fs.Dispose() }
                            }
                            else {
                                # show a simple Windows Forms preview
                                Add-Type -AssemblyName System.Windows.Forms
                                Add-Type -AssemblyName System.Drawing

                                $pngStream = [System.IO.MemoryStream]::new()
                                $data.SaveTo($pngStream)
                                [void]$pngStream.Seek(0, [System.IO.SeekOrigin]::Begin)

                                $form = New-Object Windows.Forms.Form
                                $form.Text = "QR Code [$Text]"
                                $form.Width  = [int]$Width + 16
                                $form.Height = [int]$Height + 39
                                $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

                                $pb = New-Object Windows.Forms.PictureBox
                                $pb.Width  = [int]$Width
                                $pb.Height = [int]$Height
                                $pb.Image  = [System.Drawing.Bitmap]::FromStream($pngStream)
                                $pb.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
                                $form.Controls.Add($pb)

                                [void]$form.ShowDialog()

                                # dispose UI image stream after closing the form
                                $pb.Image.Dispose()
                                $pngStream.Dispose()
                            }
                        }
                        finally { $data.Dispose() }
                    }
                    finally { $image.Dispose() }
                }
                finally {
                    $canvas.Dispose()
                    $bmp.Dispose()
                }
            }
            finally { $svg.Dispose() }
        }
        finally { $memoryStream.Dispose() }
    }
}

New-Alias -Name PSStringToQRCode -Value Convert-StringToQR
