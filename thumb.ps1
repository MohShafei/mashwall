# ========== CONFIGURATION ==========
$InputFolder = "D:\claude\New folder\wall\mashwall"
$OutputFolder = "D:\claude\New folder\wall\mashwall\Thumbnails"
$MaxWidth = 360
$Quality = 50  # 0 to 100
$JPEGCompression = 50  # Separate compression for JPEG (lower = smaller file)
$PNGCompression = 5  # 0-9, higher = smaller file but slower
# ===================================

 
Add-Type -AssemblyName System.Drawing

# Only accept PNG, JPG, and JPEG
$supportedExtensions = @(".jpg", ".jpeg", ".png")
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

    # Get original filename without extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    # Add _thm suffix and keep original extension
    $outputName = $baseName + "_thm" + $ext
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
        
        # Calculate new dimensions maintaining aspect ratio
        $ratio = $MaxWidth / $width
        $newHeight = [int]($height * $ratio)
        
        # If height would be too small, use height-based calculation
        if ($newHeight -lt 1) {
            $newHeight = 1
        }

        # Create thumbnail with optimized settings
        $thumbnail = New-Object System.Drawing.Bitmap($MaxWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($thumbnail)
        
        # Use highest quality settings for resizing
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        
        $graphics.DrawImage($img, 0, 0, $MaxWidth, $newHeight)

        # Save with optimized compression based on format
        if ($ext -eq ".jpg" -or $ext -eq ".jpeg") {
            # JPEG - use quality setting
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $JPEGCompression)
            $thumbnail.Save($outputPath, $codec, $encoderParams)
        } elseif ($ext -eq ".png") {
            # PNG - save with compression
            # Create a memory stream to save with compression
            $pngEncoder = [System.Drawing.Imaging.Encoder]::Compression
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($pngEncoder, [long]$PNGCompression)
            
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders() | Where-Object { $_.FormatDescription -eq "PNG" }
            $thumbnail.Save($outputPath, $codec, $encoderParams)
        }

        $img.Dispose()
        $thumbnail.Dispose()
        $graphics.Dispose()

        # Show file size reduction
        $originalSize = [math]::Round((Get-Item $file.FullName).Length / 1KB, 2)
        $newSize = [math]::Round((Get-Item $outputPath).Length / 1KB, 2)
        $sizeReduction = [math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1)

        $count++
        if ($count % 5 -eq 0) {
            Write-Host "Progress: $count / $total - Last: $($file.Name) ($originalSize KB → $newSize KB, -$sizeReduction%)"
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
Write-Host ""
Write-Host "To further reduce file size, you can:" -ForegroundColor Cyan
Write-Host "  - Lower JPEGCompression (e.g., 40-50) for JPEG files" -ForegroundColor Gray
Write-Host "  - Increase PNGCompression (e.g., 7-9) for PNG files" -ForegroundColor Gray
Write-Host "  - Reduce MaxWidth (e.g., 300) for even smaller thumbnails" -ForegroundColor Gray