folder文件夹转化为iso文件
将此ps1脚本放到你要打包的文件夹内。
我尽可能把中文名文件输出乱码的问题修改了，如果是其他语言(比如日语韩语)，可能会出现乱码，需要调整字符集。
运行ps1脚本，它会将文件夹内的文件打包为iso，它不会把自己打包进入，输出的iso文件名字与文件夹的名字相同。
例如D:\testfolder，将folder2iso.ps1当入此文件夹，在文件夹里运行脚本，它会将除了自己以外的文件打包为testfolder.iso，并放在此文件夹内。

你可能需要注意安全策略拦截（SecurityError）
Windows 默认执行策略阻止本地  .ps1  脚本运行，抛出权限未授权异常。
如果有你可以:以管理员身份打开PowerShell
 修改执行策略，放行本地脚本
输入这条命令并回车，弹出提示输入  Y  确认:
powershell
 Set-ExecutionPolicy RemoteSigned
RemoteSigned 含义：网上下载的脚本需要数字签名，本地自己创建的脚本可直接运行，兼顾安全与使用。

======
Convert a folder into an ISO file

Put this PS1 script into the folder you want to package.

I've done my best to fix the garbled output issue for Chinese filenames. If you're using other languages (like Japanese or Korean), you might still see garbled characters — you'll need to tweak the character set.

Run the PS1 script, and it'll package all the files in the folder into an ISO. It won't include itself in the package. The output ISO file will have the same name as the folder.

For example: say you have D:\testfolder. Drop folder2iso.ps1 into that folder, run the script from there, and it'll pack everything except itself into testfolder.iso, saved right in the same folder.

One thing to watch out for: security policy blocks (SecurityError).
Windows' default execution policy prevents local .ps1 scripts from running and throws an unauthorized exception.

If that happens, here's what you can do: open PowerShell as Administrator, change the execution policy to allow local scripts. Run this command and hit Enter, then type Y to confirm:

```powershell
Set-ExecutionPolicy RemoteSigned
```

What RemoteSigned means: scripts downloaded from the internet need a digital signature, but scripts you create locally can run directly. It's a good balance between security and usability.

