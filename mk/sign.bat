@echo off
rem Copyright (c) Citrix Systems Inc. 
rem All rights reserved.
rem 
rem Redistribution and use in source and binary forms,
rem with or without modification, are permitted provided
rem that the following conditions are met:
rem 
rem *   Redistributions of source code must retain the above
rem     copyright notice, this list of conditions and the
rem     following disclaimer.
rem *   Redistributions in binary form must reproduce the above
rem     copyright notice, this list of conditions and the
rem     following disclaimer in the documentation and/or other
rem     materials provided with the distribution.
rem 
rem THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
rem CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
rem INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
rem MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
rem DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
rem CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
rem SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
rem BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
rem SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
rem INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
rem WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
rem NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
rem OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
rem SUCH DAMAGE.

if defined CTXSIGN (
    %CTXSIGN%  --authorise --workerID tizon-1 --orchID tizon-1 --jobID XenServerWindowsLegacyPVTools_signing --task XenServerDotnetPackages-%BUILD_NUMBER% --debug > out.txt
    echo OUTPUT FROM CTXSIGN --AUTHORISE:
    type out.txt
    echo OUTPUT ENDS
    if errorlevel = 1 exit /b 1
    echo
    set /p CCSS_TICKET= < out.txt
    %CTXSIGN% --sign --key XenServer.NET_KEY %1
    %CTXSIGN% --end
) else (
    set ddk_path="no ddk"
    if exist c:\winddk\6001.18001 set ddk_path=c:\winddk\6001.18001
    if exist c:\winddk\6000 set ddk_path=c:\winddk\6000

    if "%ddk_path%"=="no ddk" goto no_ddk
    goto found_ddk

    :no_ddk
    echo "Cannot find a DDK in either c:\winddk\6000 or c:\winddk\6001.18001"
    goto end

    :found_ddk
    ::do not display this because the tool is called too many times and it polutes the output.
    IF DEFINED DEBUG (echo ddk is %ddk_path%)

    :end
    @echo on

    set descr="Citrix XenCenter"
    if not [%2]==[] set descr=%2
    %ddk_path%\bin\catalog\signtool.exe sign -a -s my -n "Citrix Systems, Inc" -d %descr% -t http://timestamp.verisign.com/scripts/timestamp.dll %1
)


