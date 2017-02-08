#!/bin/sh

# Copyright (c) Citrix Systems Inc. 
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


set -eux

#do everything in place as jenkins runs a clean build, i.e. will delete previous artifacts on starting
ROOT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
REPO=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH_DIR=${ROOT}/scratch
OUTPUT_DIR=${ROOT}/output
OUTPUT_SRC_DIR=${OUTPUT_DIR}/SOURCES
OUTPUT_46_DIR=${OUTPUT_DIR}/dotnet46
OUTPUT_UNSIGNED_DIR=${OUTPUT_DIR}/dotnet46/UNSIGNED
OUTPUT_SIGNED_DIR=${OUTPUT_DIR}/dotnet46/SIGNED
OUTPUT_SIGNED_45_DIR=${OUTPUT_DIR}/dotnet45
FILES=${REPO}/mk/files
PATCHES=${REPO}/mk/patches

SNK_ORIG=$(cygpath -w "${HOME}/.ssh/xs.net.snk")
SNK=${SNK_ORIG//\\/\\\\}

XML_RPC_DIST_FILE="libraries-src/XML-RPC.NET/xml-rpc.net.2.5.0.zip"
LOG4NET_DIST_FILE="libraries-src/Log4Net/log4net-1.2.13-src.zip"
SHARP_ZIP_LIB_DIST_FILE="libraries-src/SharpZipLib/SharpZipLib_0854_SourceSamples.zip"
DISCUTILS_DIST_FILE="libraries-src/DiscUtils/DiscUtils-204669b416f9.zip"
DOT_NET_ZIP_FILE="libraries-src/DotNetZip/DotNetZip-src-v1.9.1.8.zip"
PUTTY_ZIP_FILE="libraries-src/PuTTY/putty-src.zip"
MICROSOFT_DOTNET_FRAMEWORK_INSTALLER_FILE="libraries-redist/dotNetFx46_web_setup/NDP46-KB3045560-Web.exe"

DISTFILES=(${REPO}/${XML_RPC_DIST_FILE} \
           ${REPO}/${LOG4NET_DIST_FILE} \
           ${REPO}/${SHARP_ZIP_LIB_DIST_FILE} \
           ${REPO}/${DISCUTILS_DIST_FILE} \
           ${REPO}/${MICROSOFT_DOTNET_FRAMEWORK_INSTALLER_FILE} \
           ${REPO}/${DOT_NET_ZIP_FILE} \
           ${REPO}/${PUTTY_ZIP_FILE})

mkdir_clean()
{
  rm -rf $1 && mkdir -p $1
}

mkdir_clean ${SCRATCH_DIR}
mkdir_clean ${OUTPUT_DIR}
mkdir_clean ${OUTPUT_SRC_DIR}

#bring_distfiles
for file in ${DISTFILES[@]}
do
  cp -r ${file} ${SCRATCH_DIR}
done

apply_patches()
{
  for i in ${1}
  do
    patch -d ${2} -p0 <${i}
  done
}

#prepare xml-rpc dotnet 4.6

XMLRPC_SRC_DIR=${SCRATCH_DIR}/xml-rpc.net
mkdir_clean ${XMLRPC_SRC_DIR}
unzip -q -d ${XMLRPC_SRC_DIR} ${SCRATCH_DIR}/xml-rpc.net.2.5.0.zip
shopt -s extglob
apply_patches "${PATCHES}/patch-xmlrpc!(*dotnet45*)" ${XMLRPC_SRC_DIR} # Apply all except dotnet 4.5
shopt -u extglob
sed -i "/SignAssembly/ i <AssemblyOriginatorKeyFile>${SNK}</AssemblyOriginatorKeyFile>" ${XMLRPC_SRC_DIR}/src/xmlrpc.csproj

#prepare xml-rpc dotnet 4.5

XMLRPC_SRC_DIR=${SCRATCH_DIR}/xml-rpc_v45.net
mkdir_clean ${XMLRPC_SRC_DIR}
unzip -q -d ${XMLRPC_SRC_DIR} ${SCRATCH_DIR}/xml-rpc.net.2.5.0.zip
shopt -s extglob
apply_patches "${PATCHES}/patch-xmlrpc!(*dotnet46*)" ${XMLRPC_SRC_DIR} # Apply all except dotnet 4.6
shopt -u extglob
sed -i "/SignAssembly/ i <AssemblyOriginatorKeyFile>${SNK}</AssemblyOriginatorKeyFile>" ${XMLRPC_SRC_DIR}/src/xmlrpc.csproj

#prepare log4net

LOG4NET_SRC_DIR=${SCRATCH_DIR}/log4net
LOG4NET_DIST_DIR=${SCRATCH_DIR}/log4net-1.2.13
rm -rf ${LOG4NET_SRC_DIR}
rm -rf ${LOG4NET_DIST_DIR}
unzip -q -d ${SCRATCH_DIR} ${SCRATCH_DIR}/log4net-1.2.13-src.zip
mv ${LOG4NET_DIST_DIR} ${LOG4NET_SRC_DIR}
apply_patches "${PATCHES}/patch-log4net*" ${LOG4NET_SRC_DIR}

#prepare sharpziplib

SHARPZIPLIB_SRC_DIR=${SCRATCH_DIR}/sharpziplib
mkdir_clean ${SHARPZIPLIB_SRC_DIR}
unzip -q -d ${SHARPZIPLIB_SRC_DIR} ${SCRATCH_DIR}/SharpZipLib_0854_SourceSamples.zip
cp ${PATCHES}/patch-sharpziplib* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-sharpziplib*" ${SHARPZIPLIB_SRC_DIR}

#prepare dotnetzip

DOTNETZIP_SRC_DIR=${SCRATCH_DIR}/dotnetzip
mkdir_clean ${DOTNETZIP_SRC_DIR}
unzip -q -d ${DOTNETZIP_SRC_DIR} ${SCRATCH_DIR}/DotNetZip-src-v1.9.1.8.zip
cp ${PATCHES}/patch-dotnetzip* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-dotnetzip*" ${DOTNETZIP_SRC_DIR}

#prepare discutils

DISCUTILS_SRC_DIR=${SCRATCH_DIR}/DiscUtils
mkdir_clean ${DISCUTILS_SRC_DIR}
unzip -q -d ${DISCUTILS_SRC_DIR} ${SCRATCH_DIR}/DiscUtils-204669b416f9.zip
mv ${DISCUTILS_SRC_DIR}/DiscUtils_204669b416f9/* ${DISCUTILS_SRC_DIR}
cp ${PATCHES}/patch-discutils* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-discutils*" ${DISCUTILS_SRC_DIR}

#prepare PuTTY

PUTTY_SRC_DIR=${SCRATCH_DIR}/PuTTY
mkdir_clean ${PUTTY_SRC_DIR}
unzip -q -d ${PUTTY_SRC_DIR} ${SCRATCH_DIR}/putty-src.zip
cp ${PUTTY_SRC_DIR}/version.h ${PUTTY_SRC_DIR}/licence.h ${PUTTY_SRC_DIR}/windows/


echo "INFO: Performing main build tasks..."

run_msbuild()
{
  MSBuild.exe /nologo /m /verbosity:minimal /p:Configuration=Release /p:TargetFrameworkVersion=v4.6 /property:PlatformToolset=v120 $*
  return $?
}

run_msbuild_dotnet45()
{
  MSBuild.exe /nologo /m /verbosity:minimal /p:Configuration=Release /p:TargetFrameworkVersion=v4.5 /property:PlatformToolset=v120 $*
  return $?
}

run_msbuild_nofw()
{
  MSBuild.exe /nologo /m /verbosity:minimal /p:Configuration=Release /property:PlatformToolset=v120 $*
  return $?
}

cd ${SCRATCH_DIR}/xml-rpc.net/src && run_msbuild
cd ${SCRATCH_DIR}/xml-rpc_v45.net/src && run_msbuild_dotnet45 && mv ../bin/CookComputing.XmlRpcV2.dll ../bin/CookComputing.XmlRpcV2_dotnet45.dll && mv ../bin/CookComputing.XmlRpcV2.pdb ../bin/CookComputing.XmlRpcV2_dotnet45.pdb #building for dotnet4.5
cd ${SCRATCH_DIR}/log4net/src     && run_msbuild log4net.vs2010.csproj
cd ${SCRATCH_DIR}/sharpziplib/src && run_msbuild
cd ${SCRATCH_DIR}/dotnetzip/DotNetZip-src/DotNetZip/Zip && run_msbuild
cd ${SCRATCH_DIR}/DiscUtils/src   && run_msbuild
cd ${SCRATCH_DIR}/PuTTY/windows/VS2010 && run_msbuild_nofw

#collect extra files in the output directory

mkdir_clean ${OUTPUT_46_DIR}
cp ${REPO}/mk/sign.bat \
   ${SCRATCH_DIR}/xml-rpc.net/bin/CookComputing.XmlRpcV2.{dll,pdb} \
   ${SCRATCH_DIR}/log4net/build/bin/net/2.0/release/log4net.{dll,pdb} \
   ${SCRATCH_DIR}/sharpziplib/bin/ICSharpCode.SharpZipLib.{dll,pdb} \
   ${SCRATCH_DIR}/dotnetzip/DotNetZip-src/DotNetZip/Zip/bin/Release/Ionic.Zip.{dll,pdb} \
   ${SCRATCH_DIR}/DiscUtils/src/bin/Release/DiscUtils.{dll,pdb} \
   ${SCRATCH_DIR}/PuTTY/windows/VS2010/putty/Release/putty.exe \
   ${SCRATCH_DIR}/NDP46-KB3045560-Web.exe \
   ${OUTPUT_46_DIR}

#group files that will be signed
mkdir_clean ${OUTPUT_SIGNED_DIR}
mv ${OUTPUT_46_DIR}/{sign.bat,CookComputing.XmlRpcV2.dll,log4net.dll,ICSharpCode.SharpZipLib.dll,DiscUtils.dll,Ionic.Zip.dll,putty.exe} \
   ${OUTPUT_SIGNED_DIR}

mkdir_clean ${OUTPUT_SIGNED_45_DIR}
cp ${REPO}/mk/sign.bat ${OUTPUT_SIGNED_45_DIR}
cp ${SCRATCH_DIR}/xml-rpc_v45.net/bin/CookComputing.XmlRpcV2_dotnet45.dll ${OUTPUT_SIGNED_45_DIR}/CookComputing.XmlRpcV2.dll
cp ${SCRATCH_DIR}/xml-rpc_v45.net/bin/CookComputing.XmlRpcV2_dotnet45.pdb ${OUTPUT_SIGNED_45_DIR}/CookComputing.XmlRpcV2.pdb

#copy unsigned files
mkdir_clean ${OUTPUT_UNSIGNED_DIR}
cp ${OUTPUT_SIGNED_DIR}/{CookComputing.XmlRpcV2.dll,log4net.dll,ICSharpCode.SharpZipLib.dll,DiscUtils.dll,Ionic.Zip.dll,putty.exe} \
   ${OUTPUT_UNSIGNED_DIR}

#sign those necessary
chmod a+x ${OUTPUT_SIGNED_DIR}/sign.bat
cd ${OUTPUT_SIGNED_DIR} && ${OUTPUT_SIGNED_DIR}/sign.bat CookComputing.XmlRpcV2.dll "XML-RPC.NET by Charles Cook, signed by Citrix"
cd ${OUTPUT_SIGNED_DIR} && ${OUTPUT_SIGNED_DIR}/sign.bat log4net.dll  "Log4Net by The Apache Software Foundation, signed by Citrix"
cd ${OUTPUT_SIGNED_DIR} && ${OUTPUT_SIGNED_DIR}/sign.bat ICSharpCode.SharpZipLib.dll "SharpZipLib by IC#Code, signed by Citrix"
cd ${OUTPUT_SIGNED_DIR} && ${OUTPUT_SIGNED_DIR}/sign.bat DiscUtils.dll "DiscUtils by Kenneth Bell, signed by Citrix"
cd ${OUTPUT_SIGNED_DIR} && ${OUTPUT_SIGNED_DIR}/sign.bat Ionic.Zip.dll "OSS, signed by Citrix"
cd ${OUTPUT_SIGNED_DIR} && ${OUTPUT_SIGNED_DIR}/sign.bat putty.exe "PuTTY by Simon Tatham, signed by Citrix"

chmod a+x ${OUTPUT_SIGNED_45_DIR}/sign.bat
cd ${OUTPUT_SIGNED_45_DIR} && ${OUTPUT_SIGNED_45_DIR}/sign.bat CookComputing.XmlRpcV2.dll "XML-RPC.NET by Charles Cook, signed by Citrix"
#create source manifest

MANIFEST=${OUTPUT_DIR}/SOURCES/MANIFEST
#this is the repo name where the main build system will look for the sources
MANIFEST_COMPONENT=dotnet-packages

echo "${MANIFEST_COMPONENT} mit local" ${XML_RPC_DIST_FILE} >> ${MANIFEST}

for file in ${PATCHES}/patch-xmlrpc*
do
  echo "${MANIFEST_COMPONENT} mit local" $(basename ${file}) >> ${MANIFEST}
done

echo "${MANIFEST_COMPONENT} apache2 local" ${LOG4NET_DIST_FILE} >> ${MANIFEST}
for file in ${FILES}/log4net*
do
  echo "${MANIFEST_COMPONENT} apache2 local" $(basename ${file}) >> ${MANIFEST}
done

echo "${MANIFEST_COMPONENT} gpl+linkingexception local" ${SHARP_ZIP_LIB_DIST_FILE} >> ${MANIFEST}
for file in ${PATCHES}/patch-sharpziplib*
do
  echo "${MANIFEST_COMPONENT} gpl+linkingexception local" $(basename ${file}) >> ${MANIFEST}
done

echo "${MANIFEST_COMPONENT} mit local" ${DISCUTILS_DIST_FILE} >> ${MANIFEST}

set +ux
