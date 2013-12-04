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

set -eu

source "$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/declarations.sh"

mkdir_clean()
{
  rm -rf $1 && mkdir -p $1
}

mkdir_clean ${SCRATCH_DIR}
mkdir_clean ${OUTPUT_DIR}
mkdir_clean ${OUTPUT_SRC_DIR}
mkdir_clean ${BUILD_ARCHIVE}

#bring_distfiles
for file in ${DISTFILES[@]}
do
  cp -r ${file} ${SCRATCH_DIR}
done

apply_patches()
{
  for i in ${1}
  do
    # keep it quiet by default, if you want enable if DEBUG is defined.
    patch -d ${2} -p0 <${i}
  done
}
    
#prepare xml-rpc

XMLRPC_SRC_DIR=${SCRATCH_DIR}/xml-rpc.net
mkdir_clean ${XMLRPC_SRC_DIR}
unzip -q -d ${XMLRPC_SRC_DIR} ${SCRATCH_DIR}/xml-rpc.net.2.1.0.zip
cp ${PATCHES}/patch-xmlrpc* ${OUTPUT_SRC_DIR}
apply_patches "${PATCHES}/patch-xmlrpc*" ${XMLRPC_SRC_DIR}
sed -i "/SignAssembly/ i <AssemblyOriginatorKeyFile>${SNK}</AssemblyOriginatorKeyFile>" ${XMLRPC_SRC_DIR}/src/xmlrpc.csproj

#prepare log4net

LOG4NET_SRC_DIR=${SCRATCH_DIR}/log4net
LOG4NET_DIST_DIR=${SCRATCH_DIR}/log4net-1.2.10
rm -rf ${LOG4NET_SRC_DIR}
rm -rf ${LOG4NET_DIST_DIR}
unzip -q -d ${SCRATCH_DIR} ${SCRATCH_DIR}/incubating-log4net-1.2.10.zip
mv ${LOG4NET_DIST_DIR} ${LOG4NET_SRC_DIR}
rm -rf ${LOG4NET_SRC_DIR}/{examples,doc}
cp ${FILES}/log4net.sln ${FILES}/log4net.csproj ${LOG4NET_SRC_DIR}/src
cp ${FILES}/log4net.sln ${FILES}/log4net.csproj ${OUTPUT_SRC_DIR}
cp ${FILES}/log4net.Tests.csproj ${LOG4NET_SRC_DIR}/tests/src/log4net.Tests.csproj
cp ${FILES}/log4net.Tests.csproj ${OUTPUT_SRC_DIR}

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

#build

run_msbuild()
{
  /cygdrive/c/WINDOWS/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe /p:Configuration=Release /p:TargetFrameworkVersion=v4.0
}

cd ${SCRATCH_DIR}/xml-rpc.net/src && run_msbuild
cd ${SCRATCH_DIR}/log4net/src     && run_msbuild
cd ${SCRATCH_DIR}/sharpziplib/src && run_msbuild
cd ${SCRATCH_DIR}/dotnetzip/DotNetZip-src/DotNetZip/Zip && run_msbuild
cd ${SCRATCH_DIR}/DiscUtils/src   && run_msbuild

#collect extra files in the output directory
cp ${REPO}/mk/sign.bat ${OUTPUT_DIR}
cp ${SCRATCH_DIR}/xml-rpc.net/bin/CookComputing.XmlRpcV2.{dll,pdb} \
   ${SCRATCH_DIR}/log4net/build/bin/net/2.0/release/log4net.{dll,pdb} \
   ${SCRATCH_DIR}/sharpziplib/bin/ICSharpCode.SharpZipLib.{dll,pdb} \
   ${SCRATCH_DIR}/dotnetzip/DotNetZip-src/DotNetZip/Zip/bin/Release/Ionic.Zip.{dll,pdb} \
   ${SCRATCH_DIR}/DiscUtils/src/bin/Release/DiscUtils.{dll,pdb} \
   ${OUTPUT_DIR}

#sign those necessary
chmod a+x ${OUTPUT_DIR}/sign.bat
cd ${OUTPUT_DIR} && ${OUTPUT_DIR}/sign.bat CookComputing.XmlRpcV2.dll "XML-RPC.NET by Charles Cook, signed by Citrix"
cd ${OUTPUT_DIR} && ${OUTPUT_DIR}/sign.bat log4net.dll  "Log4Net by The Apache Software Foundation, signed by Citrix"
cd ${OUTPUT_DIR} && ${OUTPUT_DIR}/sign.bat ICSharpCode.SharpZipLib.dll "SharpZipLib by IC#Code, signed by Citrix"
cd ${OUTPUT_DIR} && ${OUTPUT_DIR}/sign.bat DiscUtils.dll "DiscUtils by Kenneth Bell, signed by Citrix"
cd ${OUTPUT_DIR} && ${OUTPUT_DIR}/sign.bat Ionic.Zip.dll "OSS, signed by Citrix"

#create source manifest

MANIFEST=${OUTPUT_DIR}/SOURCES/MANIFEST
#this is the repo name where the main build system will look for the sources
MANIFEST_COMPONENT=dotnet-packages-ref

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

#create manifest and build location
echo "@branch=${XS_BRANCH}" >> ${OUTPUT_DIR}/manifest
echo "dotnet-packages dotnet-packages.git" ${get_GIT_REVISION:0:12} >> ${OUTPUT_DIR}/manifest
echo ${get_BUILD_URL} >> ${OUTPUT_DIR}/latest-successful-build

set +u
