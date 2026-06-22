# 自动获取脚本所在文件夹（要打包的目录）
$sourcePath = $PSScriptRoot
# 脚本完整路径
$scriptFullPath = $MyInvocation.MyCommand.Definition
# ISO 文件名 = 文件夹名称，存在脚本同目录
$folderName = Split-Path $sourcePath -Leaf
$isoPath = Join-Path $PSScriptRoot "$folderName.iso"

# 前置清理旧ISO
if (Test-Path $isoPath) { 
    Remove-Item $isoPath -Force -ErrorAction SilentlyContinue 
}

# 内嵌C#流处理代码
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

# 创建ISO镜像
$image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
# 7 = ISO9660 + Joliet，支持中文长文件名
$image.FileSystemsToCreate = 7
# 卷标自动用文件夹名
$image.VolumeName = $folderName
$image.FreeMediaBlocks = -1

# 遍历文件夹，逐个添加文件，跳过脚本自身
Get-ChildItem -Path $sourcePath -Force | ForEach-Object {
    if ($_.FullName -ne $scriptFullPath) {
        $image.Root.AddTree($_.FullName, $true)
    }
}

$result = $image.CreateResultImage()

# 导出ISO文件
try {
    [IsoExporter]::SaveStream($result.ImageStream, $isoPath)
    Write-Host "打包完成！ISO路径：$isoPath" -ForegroundColor Green
} catch {
    Write-Host "错误：ISO文件被占用，请关闭解压/挂载软件后重试" -ForegroundColor Red
}
# 执行完毕暂停，按任意键关闭窗口
Write-Host "`n按任意键关闭窗口..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
