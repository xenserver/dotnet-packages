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

#this is the XenServer branch we're building; change this when making a new branch
# that's the code to get the branch name of the repository
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

XS_BRANCH=`cd $DIR;git config --get remote.origin.url|sed -e 's@.*carbon/\(.*\)/dotnet-packages.git.*@\1@'`

if [ -z "${JOB_NAME+xxx}" ]
then
    JOB_NAME="devbuild"
    echo "Warning: JOB_NAME env var not set, we will use ${JOB_NAME}"
fi

if [ -z "${BUILD_NUMBER+xxx}" ]
then
    BUILD_NUMBER="0"
    echo "Warning: BUILD_NUMBER env var not set, we will use ${BUILD_NUMBER}"
fi

if [ -z "${BUILD_ID+xxx}" ]
then
    BUILD_ID=$(date +"%Y-%m-%d_%H-%M-%S")
    echo "Warning: BUILD_ID env var not set, we will use ${BUILD_ID}"
fi

if [ -z "${BUILD_URL+xxx}" ]
then
    BUILD_URL="n/a"
    echo "Warning: BUILD_URL env var not set, we will use 'n/a'"
fi

if [ -z "${GIT_REVISION+xxx}" ]
then
    GIT_REVISION="none"
    echo "Warning: GIT_REVISION env var not set, we will use $GIT_REVISION"
fi

#rename Jenkins environment variables to distinguish them from ours; remember to use them as get only
get_JOB_NAME=${JOB_NAME}
get_BUILD_ID=${BUILD_ID}
get_BUILD_URL=${BUILD_URL}
get_GIT_REVISION=${GIT_REVISION}

#do everything in place as jenkins runs a clean build, i.e. will delete previous artifacts on starting
if [ -z "${WORKSPACE+xxx}" ]
then
    DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
    WORKSPACE="${DIR}"
    echo "Warning: WORKSPACE env var not set, we will use ${WORKSPACE}"
fi


ROOT=$(cygpath -u "${WORKSPACE}")
SCRATCH_DIR=${ROOT}/scratch
OUTPUT_DIR=${ROOT}/output
OUTPUT_SRC_DIR=${OUTPUT_DIR}/SOURCES
REPO=${ROOT}/dotnet-packages.git
FILES=${REPO}/mk/files
PATCHES=${REPO}/mk/patches
BUILD_ARCHIVE=/cygdrive/c/Jenkins/jobs/${get_JOB_NAME}/builds/${get_BUILD_ID}/archive

XML_RPC_DIST_FILE="libraries-src/XML-RPC.NET/xml-rpc.net.2.1.0.zip"
LOG4NET_DIST_FILE="libraries-src/Log4Net/incubating-log4net-1.2.10.zip"
SHARP_ZIP_LIB_DIST_FILE="libraries-src/SharpZipLib/SharpZipLib_0854_SourceSamples.zip"
DISCUTILS_DIST_FILE="libraries-src/DiscUtils/DiscUtils-204669b416f9.zip"
DOT_NET_ZIP_FILE="libraries-src/DotNetZip/DotNetZip-src-v1.9.1.8.zip"

DISTFILES=(${REPO}/${XML_RPC_DIST_FILE} \
           ${REPO}/${LOG4NET_DIST_FILE} \
           ${REPO}/${SHARP_ZIP_LIB_DIST_FILE} \
           ${REPO}/${DISCUTILS_DIST_FILE} \
           ${REPO}/${DOT_NET_ZIP_FILE})
