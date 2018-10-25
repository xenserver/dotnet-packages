# Third-Party Components

This repository contains the source code and patches for the third-party
libraries:

* DiscUtils (v0.7) - a .NET library for reading and writing ISO files
  and Virtual Machine disk files (VHD, VDI, XVA, VMDK, etc);
* DotNetZip (v1.9.1.8) - a .NET library for handling ZIP files;
* SharpZipLib (v0.85.4)- a Zip, GZip, Tar and BZip2 library written
  entirely in C# for the .NET platform;
* XML-RPC.NET (v2.5.0) - a library for implementing XML-RPC Services
  and clients in the .NET environment;
* log4net (v1.2.13) - a library providing logging services for purposes
  of application debugging and auditing;
* PuTTY (v0.67) - PuTTY is a free implementation of Telnet and SSH for
  Windows and Unix platforms, along with an xterm terminal emulator;
* Json.NET (v10.0.2) - a Json framework for .NET.

## Contributions

The preferable way to contribute patches is to fork the repository on Github and
then submit a pull request. If for some reason you can't use Github to submit a
pull request, then you may send your patch for review to the
xs-devel@lists.xenserver.org mailing list, with a link to a public git repository
for review. Please see the [CONTRIB](CONTRIB) file for some general guidelines on submitting
changes.

## License

This code is licensed under the BSD 2-Clause license. The individual libraries
are subject to their own licenses, which can be found in the corresponding
directories. Please see the [LICENSE](LICENSE) file for more information.

## How to build dotnet-packages

### Prerequisites

1. .Net Framework 4.5 and 4.6 installed.
2. Visual Studio build tools for 2013 (toolsversion 12.0) and 2015 (toolsversion 14.0).
3. The Windows 8.1 SDK (PlatformToolset v120 included in VS2013).
4. Add the location of the `msbuild` executable to the System Path.
5. [Cygwin](http://www.cygwin.com)) installed including the `unzip` and `patch` packages.
6. Add the Cygwin `/bin` directory to your System Path.
7. Make sure Git is installed and can be accessed from the command-line.

### Build

The libraries can be built (with patches applied) by opening the command line in
a suitable directory and running the following commands:

```shell
git clone https://github.com/xenserver/dotnet-packages.git
sh dotnet-packages/build.sh
```
