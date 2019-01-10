. "$PSScriptRoot\helpers.ps1"

Set-Location $projectDir

# 检查必要命令

if (-Not (Get-Command -Name cmake -ErrorAction SilentlyContinue))
{
    Write-Failure "请先安装 CMake，并确保 cmake 命令已添加到 PATH 环境变量"
    SafeExit 1
}

# CMake 生成

$configType = if ($args[0]) { $args[0] } else { "Debug" }

New-Item -Path .\build\$configType -ItemType Directory -ErrorAction SilentlyContinue
Set-Location .\build\$configType

$vcpkgRoot = if ($env:VCPKG_ROOT) { $env:VCPKG_ROOT } else { "$projectDir\vcpkg" }
$vcpkgTriplet = if ($env:VCPKG_TRIPLET) { $env:VCPKG_TRIPLET } else { "x86-windows-static-custom" }

if (-Not (Test-Path "$vcpkgRoot"))
{
    Write-Failure "Vcpkg 根目录不存在，请检查 vcpkg 是否正确安装和配置"
    SafeExit 1
}

Write-Host "正在使用 CMake 生成构建目录……"

cmake -G "Visual Studio 15 2017" -T "v141" `
    -DCMAKE_TOOLCHAIN_FILE="$vcpkgRoot\scripts\buildsystems\vcpkg.cmake" `
    -DVCPKG_TARGET_TRIPLET="$vcpkgTriplet" `
    -DCMAKE_CONFIGURATION_TYPES="$configType" `
    -DCMAKE_BUILD_TYPE="$configType" `
    "$projectDir"

if ($?)
{
    Write-Success "CMake 生成成功"
}
else
{
    Write-Failure "CMake 生成失败"
    SafeExit 1
}

# 退出

SafeExit 0
