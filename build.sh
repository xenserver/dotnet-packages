#!/bin/bash

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

# Calling with --snk <snk-file> will apply strong names to the assemblies
# using the specified key

set -eux

#do everything in place as jenkins runs a clean build, i.e. will delete previous artifacts on starting

REPO=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR=${REPO}/_build
SCRATCH_DIR=${BUILD_DIR}/scratch
OUTPUT_DIR=${BUILD_DIR}/output
OUTPUT_SRC_DIR=${OUTPUT_DIR}/SOURCES
OUTPUT_46_DIR=${OUTPUT_DIR}/dotnet46
OUTPUT_45_DIR=${OUTPUT_DIR}/dotnet45
PATCHES=${REPO}/patches

SIGN=""

while [ "$#" -gt 0 ]
do
  case "$1" in
    --snk)
      echo Will apply a strong name to xmlrpc and json dlls
      SIGN="/p:SignAssembly=true /p:AssemblyOriginatorKeyFile=${2}"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

MSBUILD=MSBuild.exe
echo "DEBUG: Printing MSBuild.exe version..."
"${MSBUILD}" /ver

SWITCHES="/nologo /m /verbosity:minimal /p:Configuration=Release"
FRAME45="/p:TargetFrameworkVersion=v4.5"
FRAME46="/p:TargetFrameworkVersion=v4.6"
VS2013="/toolsversion:12.0"
VS2015="/toolsversion:14.0"
VS2013_CPP="/property:PlatformToolset=v120"

XML_RPC_LICENSE="libraries-src/XML-RPC.NET/LICENSE"
JSON_NET_LICENSE="libraries-src/Json.NET/LICENSE.txt"
XML_RPC_DIST_FILE="libraries-src/XML-RPC.NET/xml-rpc.net.2.5.0.zip"
JSON_NET_ZIP_FILE="libraries-src/Json.NET/Newtonsoft.Json-10.0.2.zip"
LOG4NET_DIST_FILE="libraries-src/Log4Net/log4net-1.2.13-src.zip"
SHARP_ZIP_LIB_DIST_FILE="libraries-src/SharpZipLib/SharpZipLib_0854_SourceSamples.zip"
DISCUTILS_DIST_FILE="libraries-src/DiscUtils/DiscUtils-204669b416f9.zip"
DOT_NET_ZIP_FILE="libraries-src/DotNetZip/DotNetZip-src-v1.9.1.8.zip"
PUTTY_ZIP_FILE="libraries-src/PuTTY/putty-src.zip"

mkdir_clean()
{
  rm -rf $1 && mkdir -p $1
}

mkdir_clean ${BUILD_DIR}
mkdir_clean ${SCRATCH_DIR}
mkdir_clean ${OUTPUT_DIR}
mkdir_clean ${OUTPUT_46_DIR}
mkdir_clean ${OUTPUT_45_DIR}
mkdir_clean ${OUTPUT_SRC_DIR}

apply_patches()
{
  for i in ${1}
  do
    echo applying patch file ${i}...
    patch -b --binary -d ${2} -p0 <${i}
  done
}

#prepare xml-rpc dotnet 4.6

install -m 644 ${REPO}/${XML_RPC_DIST_FILE} ${SCRATCH_DIR}

XMLRPC_SRC_DIR=${SCRATCH_DIR}/xml-rpc.net
mkdir_clean ${XMLRPC_SRC_DIR}
unzip -q -d ${XMLRPC_SRC_DIR} ${SCRATCH_DIR}/xml-rpc.net.2.5.0.zip
shopt -s extglob
apply_patches "${PATCHES}/patch-xmlrpc!(*dotnet45*)" ${XMLRPC_SRC_DIR} # Apply all except dotnet 4.5
shopt -u extglob
cd ${SCRATCH_DIR}/xml-rpc.net/src && "${MSBUILD}" ${SWITCHES} ${FRAME46} ${VS2013} ${SIGN}
cp ${SCRATCH_DIR}/xml-rpc.net/bin/CookComputing.XmlRpcV2.{dll,pdb} ${OUTPUT_46_DIR}

#prepare xml-rpc dotnet 4.5

XMLRPC_SRC_DIR=${SCRATCH_DIR}/xml-rpc_v45.net
mkdir_clean ${XMLRPC_SRC_DIR}
unzip -q -d ${XMLRPC_SRC_DIR} ${SCRATCH_DIR}/xml-rpc.net.2.5.0.zip
shopt -s extglob
apply_patches "${PATCHES}/patch-xmlrpc!(*dotnet46*)" ${XMLRPC_SRC_DIR} # Apply all except dotnet 4.6
shopt -u extglob
cd ${SCRATCH_DIR}/xml-rpc_v45.net/src && "${MSBUILD}" ${SWITCHES} ${FRAME45} ${VS2013} ${SIGN}
cp ${SCRATCH_DIR}/xml-rpc_v45.net/bin/CookComputing.XmlRpcV2.{dll,pdb} ${OUTPUT_45_DIR}

#prepare Json.NET 4.6

install -m 644 ${REPO}/${JSON_NET_ZIP_FILE} ${SCRATCH_DIR}

JSON_NET_SRC_DIR=${SCRATCH_DIR}/json.net
mkdir_clean ${JSON_NET_SRC_DIR}
unzip -q -d ${JSON_NET_SRC_DIR} ${SCRATCH_DIR}/Newtonsoft.Json-10.0.2.zip
ls ${JSON_NET_SRC_DIR}
shopt -s extglob
apply_patches "${PATCHES}/patch-json-net!(*dotnet45*)" ${JSON_NET_SRC_DIR} # Apply all except dotnet 4.5
shopt -u extglob
cd ${SCRATCH_DIR}/json.net/Newtonsoft.Json-10.0.2/Src/Newtonsoft.Json && "${MSBUILD}" ${SWITCHES} ${FRAME46} ${VS2015} ${SIGN} Newtonsoft.Json.Net40.csproj
cp ${SCRATCH_DIR}/json.net/Newtonsoft.Json-10.0.2/Src/Newtonsoft.Json/bin/Release/net46/Newtonsoft.Json.{dll,pdb} ${OUTPUT_46_DIR}

#prepare Json.NET 4.5

JSON_NET_SRC_DIR=${SCRATCH_DIR}/json_v45.net
mkdir_clean ${JSON_NET_SRC_DIR}
unzip -q -d ${JSON_NET_SRC_DIR} ${SCRATCH_DIR}/Newtonsoft.Json-10.0.2.zip
ls ${JSON_NET_SRC_DIR}
shopt -s extglob
apply_patches "${PATCHES}/patch-json-net!(*dotnet46*)" ${JSON_NET_SRC_DIR} # Apply all except dotnet 4.6
shopt -u extglob
cd ${SCRATCH_DIR}/json_v45.net/Newtonsoft.Json-10.0.2/Src/Newtonsoft.Json && "${MSBUILD}" ${SWITCHES} ${FRAME45} ${VS2015} ${SIGN} Newtonsoft.Json.Net40.csproj
cp ${SCRATCH_DIR}/json_v45.net/Newtonsoft.Json-10.0.2/Src/Newtonsoft.Json/bin/Release/net45/Newtonsoft.Json.{dll,pdb} ${OUTPUT_45_DIR}

#prepare log4net

install -m 644 ${REPO}/${LOG4NET_DIST_FILE} ${SCRATCH_DIR}
LOG4NET_SRC_DIR=${SCRATCH_DIR}/log4net
LOG4NET_DIST_DIR=${SCRATCH_DIR}/log4net-1.2.13
rm -rf ${LOG4NET_SRC_DIR}
rm -rf ${LOG4NET_DIST_DIR}
unzip -q -d ${SCRATCH_DIR} ${SCRATCH_DIR}/log4net-1.2.13-src.zip
mv ${LOG4NET_DIST_DIR} ${LOG4NET_SRC_DIR}
apply_patches "${PATCHES}/patch-log4net*" ${LOG4NET_SRC_DIR}
cd ${SCRATCH_DIR}/log4net/src && "${MSBUILD}" ${SWITCHES} ${FRAME46} ${VS2013} log4net.vs2010.csproj
cp ${SCRATCH_DIR}/log4net/build/bin/net/2.0/release/log4net.{dll,pdb} ${OUTPUT_46_DIR}

#prepare sharpziplib

install -m 644 ${REPO}/${SHARP_ZIP_LIB_DIST_FILE} ${SCRATCH_DIR}
SHARPZIPLIB_SRC_DIR=${SCRATCH_DIR}/sharpziplib
mkdir_clean ${SHARPZIPLIB_SRC_DIR}
unzip -q -d ${SHARPZIPLIB_SRC_DIR} ${SCRATCH_DIR}/SharpZipLib_0854_SourceSamples.zip
cp ${PATCHES}/patch-sharpziplib* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-sharpziplib*" ${SHARPZIPLIB_SRC_DIR}
cd ${SCRATCH_DIR}/sharpziplib/src && "${MSBUILD}" ${SWITCHES} ${FRAME46} ${VS2013}
cp ${SCRATCH_DIR}/sharpziplib/bin/ICSharpCode.SharpZipLib.{dll,pdb} ${OUTPUT_46_DIR}

#prepare dotnetzip

install -m 644 ${REPO}/${DOT_NET_ZIP_FILE} ${SCRATCH_DIR}
DOTNETZIP_SRC_DIR=${SCRATCH_DIR}/dotnetzip
mkdir_clean ${DOTNETZIP_SRC_DIR}
unzip -q -d ${DOTNETZIP_SRC_DIR} ${SCRATCH_DIR}/DotNetZip-src-v1.9.1.8.zip
cp ${PATCHES}/patch-dotnetzip* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-dotnetzip*" ${DOTNETZIP_SRC_DIR}
cd ${SCRATCH_DIR}/dotnetzip/DotNetZip-src/DotNetZip/Zip && "${MSBUILD}" ${SWITCHES} ${FRAME46} ${VS2013}
cp ${SCRATCH_DIR}/dotnetzip/DotNetZip-src/DotNetZip/Zip/bin/Release/Ionic.Zip.{dll,pdb} ${OUTPUT_46_DIR}

#prepare discutils

install -m 644 ${REPO}/${DISCUTILS_DIST_FILE} ${SCRATCH_DIR}
DISCUTILS_SRC_DIR=${SCRATCH_DIR}/DiscUtils
mkdir_clean ${DISCUTILS_SRC_DIR}
unzip -q -d ${DISCUTILS_SRC_DIR} ${SCRATCH_DIR}/DiscUtils-204669b416f9.zip
mv ${DISCUTILS_SRC_DIR}/DiscUtils_204669b416f9/* ${DISCUTILS_SRC_DIR}
cp ${PATCHES}/patch-discutils* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-discutils*" ${DISCUTILS_SRC_DIR}
cd ${SCRATCH_DIR}/DiscUtils/src && "${MSBUILD}" ${SWITCHES} ${FRAME46} ${VS2013}
cp ${SCRATCH_DIR}/DiscUtils/src/bin/Release/DiscUtils.{dll,pdb} ${OUTPUT_46_DIR}

#prepare PuTTY

install -m 644 ${REPO}/${PUTTY_ZIP_FILE} ${SCRATCH_DIR}
PUTTY_SRC_DIR=${SCRATCH_DIR}/PuTTY
mkdir_clean ${PUTTY_SRC_DIR}
unzip -q -d ${PUTTY_SRC_DIR} ${SCRATCH_DIR}/putty-src.zip
cp ${PUTTY_SRC_DIR}/version.h ${PUTTY_SRC_DIR}/licence.h ${PUTTY_SRC_DIR}/windows/
cd ${SCRATCH_DIR}/PuTTY/windows/VS2010 && "${MSBUILD}" ${SWITCHES} ${VS2013_CPP}
cp ${SCRATCH_DIR}/PuTTY/windows/VS2010/putty/Release/putty.exe ${OUTPUT_46_DIR}

#copy licences

cp ${REPO}/${XML_RPC_LICENSE}  ${OUTPUT_DIR}/LICENSE.CookComputing.XmlRpcV2.txt
cp ${REPO}/${JSON_NET_LICENSE} ${OUTPUT_DIR}/LICENSE.Newtonsoft.Json.txt

set +ux
