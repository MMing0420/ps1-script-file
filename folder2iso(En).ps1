# Automatically get the folder where the script is located (the target folder to be packaged)
$sourcePath = $PSScriptRoot
# Full path of the script file
$scriptFullPath = $MyInvocation.MyCommand.Definition
# ISO file name = folder name, located in the same directory as the script
$folderName = Split-Path $sourcePath -Leaf
$isoPath = Join-Path $PSScriptRoot "$folderName.iso"

# Delete existing ISO file before generation
if (Test-Path $isoPath) { 
    Remove-Item $isoPath -Force -ErrorAction SilentlyContinue 
}

# Dynamically compile C# helper code
try {
    $cSharpCode = @"
    using System;
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Runtime.InteropServices.ComTypes;
    public class IsoExporter {
        public static void SaveStream(object comStream, string filePath) {
            IStream source = (IStream)comStream;
            using (FileStream fs = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None)) {
                byte[] buffer = new byte[8192];
                IntPtr ptr = Marshal.AllocHGlobal(sizeof(int));
                try {
                    int bytesRead;
                    do {
                        source.Read(buffer, buffer.Length, ptr);
                        bytesRead = Marshal.ReadInt32(ptr);
                        if (bytesRead > 0) fs.Write(buffer, 0, bytesRead);
                    } while (bytesRead > 0);
                } finally {
                    Marshal.FreeHGlobal(ptr);
                }
            }
        }
    }
"@
    Add-Type -TypeDefinition $cSharpCode -ErrorAction SilentlyContinue
} catch { }

# Initialize ISO image object
$image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
# 7 = ISO9660 + Joliet, supports long file names
$image.FileSystemsToCreate = 7
# Automatically set volume name as folder name
$image.VolumeName = $folderName
$image.FreeMediaBlocks = -1

# Traverse files in the folder and add all files/folders to the image (excluding the script itself)
Get-ChildItem -Path $sourcePath -Force | ForEach-Object {
    if ($_.FullName -ne $scriptFullPath) {
        $image.Root.AddTree($_.FullName, $true)
    }
}

$result = $image.CreateResultImage()

# Save ISO file
try {
    [IsoExporter]::SaveStream($result.ImageStream, $isoPath)
    Write-Host "Generation completed. ISO path: $isoPath" -ForegroundColor Green
} catch {
    Write-Host "Failed to generate ISO file. Possible causes: file occupied/insufficient permissions, etc." -ForegroundColor Red
}
# Pause execution and wait for key press to close the window
Write-Host "`nPress any key to close the window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")