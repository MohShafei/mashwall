# Load required assembly for image processing
Add-Type -AssemblyName System.Drawing

# Get all files in the current folder (or specify a path)
$folderPath = "."
$files = Get-ChildItem -Path $folderPath -File

foreach ($file in $files) {
    try {
        # Try to load the image to determine its actual format
        $img = [System.Drawing.Image]::FromFile($file.FullName)
        
        # Check if the image format is PNG or JPEG
        $isPng = $img.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Png)
        $isJpg = $img.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Jpeg)
        
        # If not PNG or JPEG, print the filename
        if (-not ($isPng -or $isJpg)) {
            Write-Host $file.Name -ForegroundColor Yellow
        }
        
        # Dispose the image to free resources
        $img.Dispose()
    }
    catch {
        # If the file cannot be loaded as an image, it's not a PNG or JPG
        Write-Host $file.Name -ForegroundColor Red
    }
}