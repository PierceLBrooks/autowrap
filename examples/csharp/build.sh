#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

rm -f csharp
rm -f libcsharp*.so
dub build --arch=`uname -m` --force > /dev/null 2>&1
mv libcsharp.so libcsharp.`uname -m`.so
rm -f libcsharp.so
dub run --config=emitCSharp
LD_LIBRARY_PATH=$DIR dotnet run
