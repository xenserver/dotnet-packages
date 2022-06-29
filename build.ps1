# Copyright (c) Citrix Systems, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms,
# with or without modification, are permitted provided
# that the following conditions are met:
#
# *   Redistributions of source code must retain the above
#     copyright notice, this list of conditions and the
#     following disclaimer.
# *   Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the
#     following disclaimer in the documentation and/or other
#     materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# Note: this build does not sign the binaries
# It's up to the consumer of the binaries to sign them

# NOTE: do not remove the Requires directive
#Requires -Version 3.0

Param(
  [Parameter(Mandatory = $false, HelpMessage = "Key for applying strong names to the assemblies")]
  [String]$SnkKey
)

$ErrorActionPreference = 'Stop'

function mkdirClean ([String[]] $paths) {
  foreach ($path in $paths) {
    if (Test-Path $path) {
      Remove-Item -Recurse -Force $path
    }
    New-Item -ItemType "directory" -Path "$path" | Out-Null
  }
}

function applyPatch {
  Param(
    [Parameter(Mandatory = $true)][String]$Path,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$Patch
  )

  process {
    Write-Output "Applying patch file $patch..."
    patch -b --binary -d $Path -p0 -i $Patch

    if (-not $?) {
        Write-Error "Failed to apply $Patch"
    }
  }
}

$SWITCHES = '/nologo', '/m', '/verbosity:normal', '/p:Configuration=Release', `
            '/p:DebugSymbols=true', '/p:DebugType=pdbonly'
$FRAME45 = '/p:TargetFrameworkVersion=v4.5'
$FRAME46 = '/p:TargetFrameworkVersion=v4.6'
$FRAME48 = '/p:TargetFrameworkVersion=v4.8'
$VS2019 = '/toolsversion:Current'

if ($SnkKey) {
  $SIGN = '/p:SignAssembly=true', "/p:AssemblyOriginatorKeyFile=$SnkKey"
}

$REPO = Get-Item "$PSScriptRoot" | select -ExpandProperty FullName
$BUILD_DIR = "$REPO\_build"
$SCRATCH_DIR = "$BUILD_DIR\scratch"
$OUTPUT_DIR = "$BUILD_DIR\output"
$OUTPUT_48_DIR = "$OUTPUT_DIR\dotnet48"
$OUTPUT_46_DIR = "$OUTPUT_DIR\dotnet46"
$OUTPUT_45_DIR = "$OUTPUT_DIR\dotnet45"
$PATCHES = "$REPO\patches"

$msbuild = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"

if (-not (Test-Path $msbuild)) {
  Write-Output 'DEBUG: Did not find VS Community edition. Trying Professional'
  $msbuild = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
}

Write-Output 'DEBUG: Printing MSBuild.exe version...'
& $msbuild /ver
Write-Output ''

mkdirClean $BUILD_DIR, $SCRATCH_DIR, $OUTPUT_DIR, $OUTPUT_48_DIR, $OUTPUT_46_DIR, $OUTPUT_45_DIR

#prepare sources and manifest

Set-Location -Path $REPO
$gitCommit = git rev-parse HEAD
git archive --format=zip -o "$OUTPUT_DIR\\dotnet-packages-sources.zip" $gitCommit
"dotnet-packages.git $gitCommit" | Out-File -FilePath "$OUTPUT_DIR\dotnet-packages-manifest.txt"

#prepare xml-rpc dotnet 4.8

mkdirClean "$SCRATCH_DIR\xml-rpc_v48.net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\xml-rpc_v48.net" -Path "$REPO\XML-RPC.NET\xml-rpc.net.2.5.0.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-xmlrpc") -and !$_.Name.Contains("dotnet45") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\xml-rpc_v48.net"


& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\xml-rpc_v48.net\src\xmlrpc.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\xml-rpc_v48.net\bin\CookComputing.XmlRpcV2." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare xml-rpc dotnet 4.5

mkdirClean "$SCRATCH_DIR\xml-rpc_v45.net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\xml-rpc_v45.net" -Path "$REPO\XML-RPC.NET\xml-rpc.net.2.5.0.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-xmlrpc") -and !$_.Name.Contains("dotnet48") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\xml-rpc_v45.net"

& $msbuild $SWITCHES $FRAME45 $VS2019 $SIGN "$SCRATCH_DIR\xml-rpc_v45.net\src\xmlrpc.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\xml-rpc_v45.net\bin\CookComputing.XmlRpcV2." + $_ } |`
  Move-Item -Destination $OUTPUT_45_DIR

#prepare Json.NET 4.8

mkdirClean "$SCRATCH_DIR\json48.net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\json48.net" -Path "$REPO\Json.NET\Newtonsoft.Json-13.0.1.zip"
Move-Item "$SCRATCH_DIR\json48.net\Newtonsoft.Json-13.0.1\Src\Newtonsoft.Json" "$SCRATCH_DIR\json48.net"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-json-net") -and !$_.Name.Contains("dotnet45") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\json48.net"
dotnet restore "$SCRATCH_DIR\json48.net\Newtonsoft.Json\Newtonsoft.Json.csproj"

& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\json48.net\Newtonsoft.Json\Newtonsoft.Json.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\json48.net\Newtonsoft.Json\bin\Release\net48\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare Json.NET 4.5

mkdirClean "$SCRATCH_DIR\json45.net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\json45.net" -Path "$REPO\Json.NET\Newtonsoft.Json-13.0.1.zip"
Move-Item "$SCRATCH_DIR\json45.net\Newtonsoft.Json-13.0.1\Src\Newtonsoft.Json" "$SCRATCH_DIR\json45.net"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-json-net") -and !$_.Name.Contains("dotnet48") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\json45.net"
dotnet restore "$SCRATCH_DIR\json45.net\Newtonsoft.Json\Newtonsoft.Json.csproj"

& $msbuild $SWITCHES $FRAME45 $VS2019 $SIGN "$SCRATCH_DIR\json45.net\Newtonsoft.Json\Newtonsoft.Json.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\json45.net\Newtonsoft.Json\bin\Release\net45\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_45_DIR

#prepare log4net 4.8

mkdirClean "$SCRATCH_DIR\log4net48"
Expand-Archive -DestinationPath "$SCRATCH_DIR\log4net48" -Path "$REPO\Log4Net\apache-log4net-source-2.0.12.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-log4net") -and !$_.Name.Contains("dotnet46") } | `
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\log4net48"

& $msbuild /t:restore,build $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\log4net48\src\log4net\log4net.csproj"

Move-Item "$SCRATCH_DIR\log4net48\build\artifacts\log4net.2.0.12.nupkg" -Destination $OUTPUT_48_DIR
'dll', 'pdb' | % { "$SCRATCH_DIR\log4net48\build\Release\net48\log4net." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare log4net 4.6

mkdirClean "$SCRATCH_DIR\log4net46"
Expand-Archive -DestinationPath "$SCRATCH_DIR\log4net46" -Path "$REPO\Log4Net\apache-log4net-source-2.0.12.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-log4net") -and !$_.Name.Contains("dotnet48") } | `
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\log4net46"

& $msbuild /t:restore,build $SWITCHES $FRAME46 $VS2019 $SIGN "$SCRATCH_DIR\log4net46\src\log4net\log4net.csproj"

Move-Item "$SCRATCH_DIR\log4net46\build\artifacts\log4net.2.0.12.nupkg" -Destination $OUTPUT_46_DIR
'dll', 'pdb' | % { "$SCRATCH_DIR\log4net46\build\Release\net46\log4net." + $_ } |`
  Move-Item -Destination $OUTPUT_46_DIR

#prepare sharpziplib

mkdirClean "$SCRATCH_DIR\sharpziplib"
Expand-Archive -DestinationPath "$SCRATCH_DIR\sharpziplib" -Path "$REPO\SharpZipLib\SharpZipLib_0854_SourceSamples.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-sharpziplib") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\sharpziplib"

& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\sharpziplib\src\ICSharpCode.SharpZLib.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\sharpziplib\bin\ICSharpCode.SharpZipLib." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare dotnetzip

mkdirClean "$SCRATCH_DIR\dotnetzip"
Expand-Archive -DestinationPath "$SCRATCH_DIR\dotnetzip" -Path "$REPO\DotNetZip\DotNetZip-src-v1.9.1.8.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-dotnetzip") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\dotnetzip"

& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\dotnetzip\DotNetZip-src\DotNetZip\Zip\Zip DLL.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\dotnetzip\DotNetZip-src\DotNetZip\Zip\bin\Release\Ionic.Zip." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare discutils

mkdirClean "$SCRATCH_DIR\DiscUtils"
Expand-Archive -DestinationPath "$SCRATCH_DIR\DiscUtils" -Path "$REPO\DiscUtils\DiscUtils-0.11.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-discutils") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\DiscUtils"

& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\DiscUtils\LibraryOnly.sln"
'dll', 'pdb' | % { "$SCRATCH_DIR\DiscUtils\src\bin\Release\DiscUtils." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#copy licences

Copy-Item "$REPO\XML-RPC.NET\LICENSE" -Destination "$OUTPUT_DIR\LICENSE.CookComputing.XmlRpcV2.txt"
Copy-Item "$REPO\Json.NET\LICENSE.txt" -Destination "$OUTPUT_DIR\LICENSE.Newtonsoft.Json.txt"
