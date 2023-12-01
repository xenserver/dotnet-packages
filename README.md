# Third-Party Components

This repository contains the source code and patches for the third-party
libraries:

* DiscUtils (v0.11) - a .NET library for reading and writing ISO files
  and Virtual Machine disk files (VHD, VDI, XVA, VMDK, etc);
* SharpZipLib (v0.85.4)- a Zip, GZip, Tar and BZip2 library written
  entirely in C# for the .NET platform;
* XML-RPC.NET (v2.5.0) - a library for implementing XML-RPC Services
  and clients in the .NET environment;
* log4net (v2.0.15) - a library providing logging services for purposes
  of application debugging and auditing;
* Json.NET (v13.0.1) - a Json framework for .NET.

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

1. PowerShell 3.0 or above
2. Net Framework 4.5 and 4.8 installed.
3. Net Standard 2.0 installed.
4. Visual Studio build tools for 2019 (toolsversion 16.0).
  Add the location of `msbuild` to the System Path.
5. The Windows 10.0.18362.0 SDK (included in VS 2019).
6. [git](https://git-scm.com/download/win) for Windows.

### Build

The libraries can be built (with patches applied) by opening a PowerShell prompt
in the repo root and running:

```shell
.\build.ps1 [-SnkKey <snk-file>] [-NugetSources <package-sources>]
```
