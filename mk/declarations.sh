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


SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [ -z "${JOB_NAME+xxx}" ]
then
    JOB_NAME="devbuild"
    echo "WARN: JOB_NAME env var not set, we will use ${JOB_NAME}"
fi

if [ -z "${BUILD_NUMBER+xxx}" ]
then
    BUILD_NUMBER="0"
    echo "WARN: BUILD_NUMBER env var not set, we will use ${BUILD_NUMBER}"
fi

#rename Jenkins environment variables to distinguish them from ours; remember to use them as get only

get_GIT_COMMIT=${GIT_COMMIT}

if [ -z "${get_GIT_COMMIT+xxx}" ]
then
    get_GIT_COMMIT="none"
    echo "WARN: GIT_COMMIT env var not set, we will use $get_GIT_COMMIT"
fi

get_BRANCH=${GIT_LOCAL_BRANCH}

if [ -z "${get_BRANCH+xxx}" ]
then
    get_BRANCH=$($git rev-parse --abbrev-ref HEAD)
    echo "WARN: GIT_LOCAL_BRANCH env var not set, using current head ${get_BRANCH} instead"
fi

get_JOB_NAME=${JOB_NAME}

#do everything in place as jenkins runs a clean build, i.e. will delete previous artifacts on starting
if [ -z "${WORKSPACE+xxx}" ]
then
    DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
    WORKSPACE="${DIR}"
    echo "WARN: WORKSPACE env var not set, we will use ${WORKSPACE}"
fi


ROOT=$(cygpath -u "${WORKSPACE}")
SCRATCH_DIR=${ROOT}/scratch
OUTPUT_DIR=${ROOT}/output
OUTPUT_SRC_DIR=${OUTPUT_DIR}/SOURCES
OUTPUT_UNSIGNED_DIR=${OUTPUT_DIR}/UNSIGNED
REPO=${ROOT}/dotnet-packages.git
FILES=${REPO}/mk/files
PATCHES=${REPO}/mk/patches

SECURE_BUILD_ARCHIVE_UNC=//10.80.13.10/distfiles/distfiles/WindowsBuilds/
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

BUILD_TOOLS_REPO=git://hg.uk.xensource.com/closed/windows/buildtools.git
BUILD_TOOLS=${SCRATCH_DIR}/buildtools.git
STORE_FILES=${BUILD_TOOLS}/scripts/storefiles.py

