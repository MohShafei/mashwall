# ========== CONFIGURATION ==========
$InputFolder = "D:\Test\mashwall\mashwall"
$OutputFolder = "D:\Test\mashwall\mashwall\Thumbnails"
$MaxWidth = 400
$Quality = 85  # 0 to 100
# ===================================

 
Add-Type -AssemblyName System.Drawing

$supportedExtensions = @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tiff", ".webp")
$total = (Get-ChildItem -Path $InputFolder -Recurse -File | Where-Object { $supportedExtensions -contains $_.Extension.ToLower() }).Count
$count = 0

Write-Host "Found $total images. Generating thumbnails..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $OutputFolder | Out-Null

Get-ChildItem -Path $InputFolder -Recurse -File | ForEach-Object {
    $file = $_
    $ext = $file.Extension.ToLower()

    if ($supportedExtensions -notcontains $ext) { return }

    $relativePath = $file.DirectoryName.Substring($InputFolder.Length).TrimStart('\')
    $targetDir = Join-Path $OutputFolder $relativePath
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + ".jpg"
    $outputPath = Join-Path $targetDir $outputName

    if (Test-Path $outputPath) {
        $count++
        Write-Host "Skipping (exists): $($file.Name)"
        return
    }

    try {
        $img = [System.Drawing.Image]::FromFile($file.FullName)

        $width = $img.Width
        $height = $img.Height
        $ratio = $MaxWidth / $width
        $newHeight = [int]($height * $ratio)

        $thumbnail = New-Object System.Drawing.Bitmap($MaxWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($thumbnail)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($img, 0, 0, $MaxWidth, $newHeight)

        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $Quality)

        $thumbnail.Save($outputPath, $codec, $encoderParams)

        $img.Dispose()
        $thumbnail.Dispose()
        $graphics.Dispose()

        $count++
        if ($count % 10 -eq 0) {
            Write-Host "Progress: $count / $total"
        }
    }
    catch {
        Write-Host "[FAIL] Failed: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========== Complete ==========" -ForegroundColor Green
Write-Host "[OK] Processed: $count images." -ForegroundColor Green
Write-Host "[FOLDER] Thumbnails saved to: $OutputFolder" -ForegroundColor Yellow

