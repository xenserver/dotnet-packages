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

# This is usually called by Jenkins
# If you define DEBUG environment variable you can make it more verbose.
#
# When are you doing modifications to the build system, always do them in such
# way that it will continue to work even if it's executed manually by a developer
# or from a build automation system.

DEBUG=1
if [ -n "${DEBUG+xxx}" ];
then
  echo "DEBUG mode activated (verbose)"
  set -x
fi

set -e

ROOT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
cd ${ROOT_DIR}

source ${ROOT_DIR}/dotnet-packages.hg/mk/declarations.sh

if [ -d "dotnet-packages-ref.hg" ]
then
  hg --cwd dotnet-packages-ref.hg pull -u
else
  hg clone ssh://xenhg@hg.uk.xensource.com/carbon/${XS_BRANCH}/dotnet-packages-ref.hg/
fi

source ${ROOT_DIR}/dotnet-packages.hg/mk/dotnet-packages-build.sh
source ${ROOT_DIR}/dotnet-packages.hg/mk/archive-push.sh
