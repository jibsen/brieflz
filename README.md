
BriefLZ - small fast Lempel-Ziv
===============================

Version 1.2.0

Copyright (c) 2002-2018 Joergen Ibsen

<http://www.ibsensoftware.com/>

[![Build Status](https://travis-ci.org/jibsen/brieflz.svg?branch=master)](https://travis-ci.org/jibsen/brieflz) [![Build status](https://ci.appveyor.com/api/projects/status/l9vhammx8p8hkrqb/branch/master?svg=true)](https://ci.appveyor.com/project/jibsen/brieflz/branch/master) [![codecov](https://codecov.io/gh/jibsen/brieflz/branch/master/graph/badge.svg)](https://codecov.io/gh/jibsen/brieflz)


About
-----

BriefLZ is a small and fast open source implementation of a Lempel-Ziv
style compression algorithm. The main focus is on speed and code footprint,
but the ratios achieved are quite good compared to similar algorithms.


Why BriefLZ?
------------

Two widely used types of Lempel-Ziv based compression libraries are those
that employ [entropy encoding][entropy] to achieve good ratios (like Brotli,
zlib, Zstd), and those that forgo entropy encoding to favor speed (like LZ4,
LZO).

BriefLZ attempts to place itself somewhere between these two by using a
[universal code][universal], which may improve compression ratios compared to
no entropy encoding, while requiring little extra code.

Not counting the optional lookup tables, the compression function `blz_pack`
is 147 LOC, and the decompression function `blz_depack` is 61 LOC (and can be
implemented in 103 bytes of x86 machine code).

If you do not need the extra speed of libraries without entropy encoding, but
want reasonable compression ratios, and the footprint of the compression or
decompression code is a factor, BriefLZ might be an option.

[entropy]: https://en.wikipedia.org/wiki/Entropy_encoding
[universal]: https://en.wikipedia.org/wiki/Universal_code_(data_compression)


Benchmark
---------

Here are some results from running [lzbench][] on the
[Silesia compression corpus][silesia] on a Core i5-4570 @ 3.2GHz:

| Compressor name         | Compression| Decompress.|  Compr. size  | Ratio |
| ---------------         | -----------| -----------| ------------- | ----- |
| zstd 1.3.4 -9           |    30 MB/s |   894 MB/s |    60,691,094 | 3.492 |
| brotli 2017-12-12 -4    |    44 MB/s |   383 MB/s |    64,202,945 | 3.301 |
| **brieflz 1.2.0 -6**    |    17 MB/s |   375 MB/s |    67,208,420 | 3.153 |
| zlib 1.2.11 -6          |    24 MB/s |   295 MB/s |    68,228,431 | 3.106 |
| zstd 1.3.4 -1           |   310 MB/s |   943 MB/s |    73,654,014 | 2.877 |
| **brieflz 1.2.0 -3**    |   112 MB/s |   341 MB/s |    75,550,736 | 2.805 |
| zlib 1.2.11 -1          |    68 MB/s |   279 MB/s |    77,259,029 | 2.743 |
| lz4hc 1.8.2 -9          |    29 MB/s |  2901 MB/s |    77,884,448 | 2.721 |
| brotli 2017-12-12 -0    |   258 MB/s |   297 MB/s |    78,432,913 | 2.702 |
| **brieflz 1.2.0 -1**    |   173 MB/s |   329 MB/s |    81,138,803 | 2.612 |
| lzo1x 2.09              |   498 MB/s |   617 MB/s |   100,572,537 | 2.107 |
| lz4 1.8.2               |   547 MB/s |  2955 MB/s |   100,880,800 | 2.101 |

Please note that this benchmark is not entirely fair because BriefLZ has no
window size limit.

[lzbench]: https://github.com/inikep/lzbench
[silesia]: http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia


Usage
-----

The include file `include/brieflz.h` contains documentation in the form of
[doxygen][] comments. A configuration file is included, so you can simply run
`doxygen` to generate documentation in HTML format.

If you wish to compile BriefLZ on 16-bit systems, make sure to adjust the
constants `BLZ_HASH_BITS` and `DEFAULT_BLOCK_SIZE`.

When using BriefLZ as a shared library (dll on Windows), define `BLZ_DLL`.
When building BriefLZ as a shared library, define both `BLZ_DLL` and
`BLZ_DLL_EXPORTS`.

The `example` folder contains a simple command-line program, `blzpack`, that
can compress and decompress a file using BriefLZ. For convenience, the example
comes with makefiles for GCC and MSVC.

BriefLZ uses [CMake][] to generate build systems. To create one for the tools
on your platform, and build BriefLZ, use something along the lines of:

~~~sh
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release
~~~

You can also simply compile the source files and link them into your project.
CMake just provides an easy way to build and test across various platforms and
toolsets.

[doxygen]: http://www.doxygen.org/
[CMake]: http://www.cmake.org/


License
-------

This projected is licensed under the [zlib License](LICENSE) (Zlib).
