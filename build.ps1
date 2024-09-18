# Copyright (c) Cloud Software Group, Inc.
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
  [String]$SnkKey,
  [Parameter(Mandatory = $true, HelpMessage = "Package source for NuGet restores.")]
  [String]$NugetSource
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
    $origLocation = Get-Location
    Set-Location $Path -Verbose

    try {
        Write-Host ''
        Write-Host "INFO: Applying patch file $Patch..."
        git apply --verbose $Patch
    }
    finally {
        Set-Location $origLocation -Verbose
    }

    if (-not $?) {
        Write-Error "Failed to apply $Patch"
    }
  }
}

$SWITCHES = '/nologo', '/m', '/verbosity:normal', '/p:Configuration=Release', `
            '/p:DebugSymbols=true', '/p:DebugType=pdbonly'
$RESTORE_SWITCHES= '/restore', '/p:RestoreNoCache=true'
$FRAME48 = '/p:TargetFrameworkVersion=v4.8'
$VS_TOOLS = '/toolsversion:Current'

if ($SnkKey) {
  $SIGN = '/p:SignAssembly=true', "/p:AssemblyOriginatorKeyFile=$SnkKey"
}

$REPO = Get-Item "$PSScriptRoot" | select -ExpandProperty FullName
$BUILD_DIR = "$REPO\_build"
$SCRATCH_DIR = "$BUILD_DIR\scratch"
$OUTPUT_DIR = "$BUILD_DIR\output"
$OUTPUT_20_DIR = "$OUTPUT_DIR\netstandard2.0"
$OUTPUT_48_DIR = "$OUTPUT_DIR\dotnet48"
$OUTPUT_46_DIR = "$OUTPUT_DIR\dotnet46"
$OUTPUT_45_DIR = "$OUTPUT_DIR\dotnet45"
$PATCHES = "$REPO\patches"

Write-Host 'DEBUG: Printing MSBuild.exe version...'
msbuild /ver
Write-Host ''

mkdirClean $BUILD_DIR, $SCRATCH_DIR, $OUTPUT_DIR, $OUTPUT_20_DIR, $OUTPUT_48_DIR, $OUTPUT_46_DIR, $OUTPUT_45_DIR

#prepare sources and manifest

Set-Location -Path $REPO
$gitCommit = git rev-parse HEAD
git archive --format=zip -o "$OUTPUT_DIR\\dotnet-packages-sources.zip" $gitCommit
"dotnet-packages.git $gitCommit" | Out-File -FilePath "$OUTPUT_DIR\dotnet-packages-manifest.txt"

#prepare sharpziplib

mkdirClean "$SCRATCH_DIR\sharpziplib"
Expand-Archive -DestinationPath "$SCRATCH_DIR\sharpziplib" -Path "$REPO\SharpZipLib\SharpZipLib-1.3.3.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-sharpziplib") } | % { $_.FullName } |`
  applyPatch -Path "$SCRATCH_DIR\sharpziplib\SharpZipLib-1.3.3"

msbuild $SWITCHES $FRAME48 $VS_TOOLS $SIGN "$SCRATCH_DIR\sharpziplib\SharpZipLib-1.3.3\ICSharpCode.SharpZipLib.sln"
'dll', 'pdb' | % { "$SCRATCH_DIR\sharpziplib\bin\ICSharpCode.SharpZipLib." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare xml-rpc dotnet 4.8

mkdirClean "$SCRATCH_DIR\xml-rpc_v48.net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\xml-rpc_v48.net" -Path "$REPO\XML-RPC.NET\xml-rpc.net.2.5.0.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-xmlrpc") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\xml-rpc_v48.net"


msbuild $SWITCHES $FRAME48 $VS_TOOLS $SIGN "$SCRATCH_DIR\xml-rpc_v48.net\src\xmlrpc.csproj"
'dll', 'pdb' | % { "$SCRATCH_DIR\xml-rpc_v48.net\bin\CookComputing.XmlRpcV2." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#prepare Json.NET 4.5, 4.8, and .NET Standard 2.0

mkdirClean "$SCRATCH_DIR\json.net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\json.net" -Path "$REPO\Json.NET\Newtonsoft.Json-13.0.1.zip"
Move-Item "$SCRATCH_DIR\json.net\Newtonsoft.Json-13.0.1\Src\Newtonsoft.Json" "$SCRATCH_DIR\json.net"
Move-Item "$SCRATCH_DIR\json.net\Newtonsoft.Json-13.0.1\Src\NuGet.Config" "$SCRATCH_DIR\json.net"

$RESTORE_NUGET_CONFIG_FILE="$SCRATCH_DIR\json.net\NuGet.Config"

((Get-Content -path $RESTORE_NUGET_CONFIG_FILE -Raw) -replace 'https://api.nuget.org/v3/index.json', $NugetSource) |`
 Set-Content -Path $RESTORE_NUGET_CONFIG_FILE

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-json-net")} |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\json.net"

msbuild $SWITCHES $RESTORE_SWITCHES -p:RestoreConfigFile=$RESTORE_NUGET_CONFIG_FILE $VS_TOOLS $SIGN "$SCRATCH_DIR\json.net\Newtonsoft.Json\Newtonsoft.Json.csproj"

'dll', 'pdb' | % { "$SCRATCH_DIR\json.net\Newtonsoft.Json\bin\Release\net48\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR
'dll', 'pdb' | % { "$SCRATCH_DIR\json.net\Newtonsoft.Json\bin\Release\net45\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_45_DIR
'dll', 'pdb' | % { "$SCRATCH_DIR\json.net\Newtonsoft.Json\bin\Release\netstandard2.0\Newtonsoft.Json.CH." + $_ } |`
  Move-Item -Destination $OUTPUT_20_DIR

#prepare log4net 4.6 and 4.8

mkdirClean "$SCRATCH_DIR\log4net"
Expand-Archive -DestinationPath "$SCRATCH_DIR\log4net" -Path "$REPO\Log4Net\logging-log4net-rel-2.0.15.zip"
Move-Item "$SCRATCH_DIR\log4net\logging-log4net-rel-2.0.15\*" "$SCRATCH_DIR\log4net"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-log4net") } | `
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\log4net"

msbuild /t:restore,build $SWITCHES $VS_TOOLS $SIGN "$SCRATCH_DIR\log4net\src\log4net\log4net.csproj"

Move-Item "$SCRATCH_DIR\log4net\build\artifacts\log4net.2.0.15.nupkg" -Destination $OUTPUT_DIR

'dll', 'pdb' | % { "$SCRATCH_DIR\log4net\build\Release\net48\log4net." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

'dll', 'pdb' | % { "$SCRATCH_DIR\log4net\build\Release\net46\log4net." + $_ } |`
  Move-Item -Destination $OUTPUT_46_DIR

#prepare discutils

mkdirClean "$SCRATCH_DIR\DiscUtils"
Expand-Archive -DestinationPath "$SCRATCH_DIR\DiscUtils" -Path "$REPO\DiscUtils\DiscUtils-0.11.zip"

Get-ChildItem $PATCHES | where { $_.Name.StartsWith("patch-discutils") } |`
  % { $_.FullName } | applyPatch -Path "$SCRATCH_DIR\DiscUtils"

msbuild $SWITCHES $FRAME48 $VS_TOOLS $SIGN "$SCRATCH_DIR\DiscUtils\LibraryOnly.sln"
'dll', 'pdb' | % { "$SCRATCH_DIR\DiscUtils\src\bin\Release\DiscUtils." + $_ } |`
  Move-Item -Destination $OUTPUT_48_DIR

#copy licences

Copy-Item "$REPO\XML-RPC.NET\LICENSE" -Destination "$OUTPUT_DIR\LICENSE.CookComputing.XmlRpcV2.txt"
Copy-Item "$REPO\Json.NET\LICENSE.txt" -Destination "$OUTPUT_DIR\LICENSE.Newtonsoft.Json.txt"
