$glfwversion="3.3.1"

Invoke-WebRequest "https://github.com/glfw/glfw/releases/download/$glfwversion/glfw-$glfwversion.bin.WIN32.zip" -OutFile "$pwd\glfw-$glfwversion.bin.WIN32.zip"

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "$pwd\glfw-$glfwversion.bin.WIN32.zip" "$pwd"
