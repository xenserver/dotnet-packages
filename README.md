DotNet Libraries 
================

This repository contains the source code and patches for the third-party 
libraries:

 *  DiscUtils (v0.7) - a .NET library for reading and writing ISO files 
    and Virtual Machine disk files (VHD, VDI, XVA, VMDK, etc);
 *  DotNetZip (v1.9.1.8) - a .NET library for handling ZIP files;
 *  SharpZipLib (v0.85.4)- a Zip, GZip, Tar and BZip2 library written 
    entirely in C# for the .NET platform;
 *  XML-RPC.NET (v2.1.0) - a library for implementing XML-RPC Services 
    and clients in the .NET environment;
 *  log4net (v1.2.10) - a library providing logging services for purposes 
    of application debugging and auditing.

Contributions
-------------

The preferable way to contribute is to submit your patches to the 
xs-devel@lists.xenserver.org mailing list rather than submitting pull requests. 
Please see the CONTRIB file for some general guidelines on submitting changes.

License
-------

This code is licensed under the BSD 2-Clause license. The individual libraries 
are subject to their own licenses, which can be found in the corresponding 
directories. Please see the LICENSE file for more information.

How to build dotnet-packages
----------------------------
The libraries can be built (and patches applied) by executing the script 
dotnet-packages-build.sh at the command line.
