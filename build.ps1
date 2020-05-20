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
  }
}

$SWITCHES = '/nologo', '/m', '/verbosity:normal', '/p:Configuration=Release'
$FRAME45 = '/p:TargetFrameworkVersion=v4.5'
$FRAME48 = '/p:TargetFrameworkVersion=v4.8'
$VS2019 = '/toolsversion:Current'
$VS2019_CPP = '/property:PlatformToolset=v142'

if ($SnkKey) {
  $SIGN = '/p:SignAssembly=true', "/p:AssemblyOriginatorKeyFile=$SnkKey"
}

$REPO = Get-Item "$PSScriptRoot" | select -ExpandProperty FullName
$BUILD_DIR = "$REPO\_build"
$SCRATCH_DIR = "$BUILD_DIR\scratch"
$OUTPUT_DIR = "$BUILD_DIR\output"
$OUTPUT_SRC_DIR = "$OUTPUT_DIR\SOURCES"
$OUTPUT_48_DIR = "$OUTPUT_DIR\dotnet48"
$OUTPUT_45_DIR = "$OUTPUT_DIR\dotnet45"
$PATCHES = "$REPO\patches"

$msbuild="${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"

Write-Output 'DEBUG: Printing MSBuild.exe version...'
& $msbuild /ver
Write-Output ''

mkdirClean $BUILD_DIR, $SCRATCH_DIR, $OUTPUT_DIR, $OUTPUT_SRC_DIR, $OUTPUT_48_DIR, $OUTPUT_45_DIR

#prepare sources and manifest

Set-Location -Path $REPO
$gitCommit = git rev-parse HEAD
git archive --format=zip -o "$OUTPUT_SRC_DIR\\dotnet-packages-sources.zip" $gitCommit
"dotnet-packages.git $gitCommit" | Out-File -FilePath "$OUTPUT_DIR\dotnet-packages-manifest.txt"

#prepare xml-rpc dotnet 4.8

mkdirClean "$SCRATCH_DIR\xml-rpc_v48.net"
unzip -q -d "$SCRATCH_DIR\xml-rpc_v48.net" "$REPO\XML-RPC.NET\xml-rpc.net.2.5.0.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-xmlrpc") -and !$_.Name.Contains("dotnet45") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\xml-rpc_v48.net"


& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\xml-rpc_v48.net\src\xmlrpc.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\xml-rpc_v48.net\bin\CookComputing.XmlRpcV2." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare xml-rpc dotnet 4.5

mkdirClean "$SCRATCH_DIR\xml-rpc_v45.net"
unzip -q -d "$SCRATCH_DIR\xml-rpc_v45.net" "$REPO\XML-RPC.NET\xml-rpc.net.2.5.0.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-xmlrpc") -and !$_.Name.Contains("dotnet48") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\xml-rpc_v45.net"

& $msbuild $SWITCHES $FRAME45 $VS2019 $SIGN "$SCRATCH_DIR\xml-rpc_v45.net\src\xmlrpc.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\xml-rpc_v45.net\bin\CookComputing.XmlRpcV2." + $_ } |`
  Move-Item -Destination $OUTPUT_45_DIR

#prepare Json.NET 4.8

mkdirClean "$SCRATCH_DIR\json48.net"
unzip -q -d "$SCRATCH_DIR\json48.net" "$REPO\Json.NET\Newtonsoft.Json-10.0.2.zip" "Newtonsoft.Json-10.0.2/Src/Newtonsoft.Json/*"
Move-Item "$SCRATCH_DIR\json48.net\Newtonsoft.Json-10.0.2\Src\Newtonsoft.Json" "$SCRATCH_DIR\json48.net"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-json-net") -and !$_.Name.Contains("dotnet45") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\json48.net"

& $msbuild $SWITCHES $FRAME48 $VS2019 $SIGN "$SCRATCH_DIR\json48.net\Newtonsoft.Json\Newtonsoft.Json.Net40.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\json48.net\Newtonsoft.Json\bin\Release\net48\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare Json.NET 4.5

mkdirClean "$SCRATCH_DIR\json45.net"
unzip -q -d "$SCRATCH_DIR\json45.net" "$REPO\Json.NET\Newtonsoft.Json-10.0.2.zip" "Newtonsoft.Json-10.0.2/Src/Newtonsoft.Json/*"
Move-Item "$SCRATCH_DIR\json45.net\Newtonsoft.Json-10.0.2\Src\Newtonsoft.Json" "$SCRATCH_DIR\json45.net"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-json-net") -and !$_.Name.Contains("dotnet48") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\json45.net"

& $msbuild $SWITCHES $FRAME45 $VS2019 $SIGN "$SCRATCH_DIR\json45.net\Newtonsoft.Json\Newtonsoft.Json.Net40.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\json45.net\Newtonsoft.Json\bin\Release\net45\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_45_DIR

#prepare log4net

mkdirClean "$SCRATCH_DIR\log4net"
unzip -q -d "$SCRATCH_DIR\log4net" "$REPO\Log4Net\log4net-1.2.13-src.zip" "log4net-1.2.13/*"
Move-Item "$SCRATCH_DIR\log4net\log4net-1.2.13\*" "$SCRATCH_DIR\log4net"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-log4net") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\log4net"

& $msbuild $SWITCHES $FRAME48 $VS2019 "$SCRATCH_DIR\log4net\src\log4net.vs2010.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\log4net\build\bin\net\2.0\release\log4net." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare sharpziplib

mkdirClean "$SCRATCH_DIR\sharpziplib"
unzip -q -d "$SCRATCH_DIR\sharpziplib" "$REPO\SharpZipLib\SharpZipLib_0854_SourceSamples.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-sharpziplib") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\sharpziplib"

& $msbuild $SWITCHES $FRAME48 $VS2019 "$SCRATCH_DIR\sharpziplib\src\ICSharpCode.SharpZLib.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\sharpziplib\bin\ICSharpCode.SharpZipLib." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare dotnetzip

mkdirClean "$SCRATCH_DIR\dotnetzip"
unzip -q -d "$SCRATCH_DIR\dotnetzip" "$REPO\DotNetZip\DotNetZip-src-v1.9.1.8.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-dotnetzip") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\dotnetzip"

& $msbuild $SWITCHES $FRAME48 $VS2019 "$SCRATCH_DIR\dotnetzip\DotNetZip-src\DotNetZip\Zip\Zip DLL.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\dotnetzip\DotNetZip-src\DotNetZip\Zip\bin\Release\Ionic.Zip." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare discutils

mkdirClean "$SCRATCH_DIR\DiscUtils"
unzip -q -d "$SCRATCH_DIR\DiscUtils" "$REPO\DiscUtils\DiscUtils-204669b416f9.zip"  "DiscUtils_204669b416f9/*"
Move-Item "$SCRATCH_DIR\DiscUtils\DiscUtils_204669b416f9\*" "$SCRATCH_DIR\DiscUtils"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-discutils") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\DiscUtils"

& $msbuild $SWITCHES $FRAME48 $VS2019 "$SCRATCH_DIR\DiscUtils\src\DiscUtils.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\DiscUtils\src\bin\Release\DiscUtils." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare PuTTY

mkdirClean "$SCRATCH_DIR\PuTTY"
unzip -q -d "$SCRATCH_DIR\PuTTY" "$REPO\PuTTY\putty-src.zip"
'version.h', 'licence.h' | % { "$SCRATCH_DIR\PuTTY\" + $_ } | Copy-Item -Destination "$SCRATCH_DIR\PuTTY\windows\"
& $msbuild $SWITCHES $VS2019_CPP "$SCRATCH_DIR\PuTTY\windows\VS2012"
Move-Item "$SCRATCH_DIR\PuTTY\windows\VS2012\putty\Release\putty.exe" -Destination $OUTPUT_48_DIR

#copy licences

Copy-Item "$REPO\XML-RPC.NET\LICENSE" -Destination "$OUTPUT_DIR\LICENSE.CookComputing.XmlRpcV2.txt"
Copy-Item "$REPO\Json.NET\LICENSE.txt" -Destination "$OUTPUT_DIR\LICENSE.Newtonsoft.Json.txt"
