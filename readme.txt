

BriefLZ  -  small fast Lempel-Ziv

Version 1.02

Copyright (c) 2002-2003 by Joergen Ibsen / Jibz
All Rights Reserved

http://www.ibsensoftware.com/



About
-----

 BriefLZ is a small and fast open source implementation of a Lempel-Ziv
 style compression algorithm. The main focus is on speed, but the ratios
 achieved are quite good compared to similar algorithms.

 This package contains the following BriefLZ implementations:

   32bit/        -  32-bit x86 assembler (386+)
   32bit/small/  -  32-bit x86 assembler (386+), size-optimised
   32bit/c/      -  32-bit ansi C

   16bit/        -  16-bit x86 assembler (8086+)

 The compression code by default uses 1 mb (32-bit) / 32 kb (16-bit) of
 work memory during compression. The decompression code does not use any
 additional memory.

 The compression and decompression functions should be reentrant and
 thread-safe.

 blzpack, an example command-line compressor in C, is included.

 If you need compression with better ratios, please check out the aPLib
 compression library, which is available at:

   http://www.ibsensoftware.com/


Functionality
-------------

 The following describes the 32-bit x86 assembler functions, the other
 implementations work analogously.

 unsigned int blz_workmem_size(unsigned int length);

 This function returns the required size of the workmem buffer for
 compressing length bytes of data. The default is 1 mb (1024*1024 bytes)
 regardles of the length.

 unsigned int blz_max_packed_size(unsigned int length);

 Compression may expand incompressible data. This function returns the
 maximum possible compressed size of length bytes of data.

 unsigned int blz_pack_asm(void *source,
                           void *destination,
                           unsigned int length,
                           void *workmem);

 The compression function blz_pack_asm takes four parameters, a pointer
 to the data, a pointer to where the compressed data should be stored,
 the length of the data, and a pointer to the required workmem. It returns
 the length of the compressed data.

 unsigned int blz_depack_asm(void *source,
                             void *destination,
                             unsigned int depacked_length);

 The decompression function blz_depack_asm takes three parameters,
 a pointer to the compressed data, a pointer to where the decompressed
 data should be stored, and the length of the _decompressed_ data. It
 returns the length of the decompressed data.


Source Code
-----------

 The assembler source code for compression and decompression is NASM-style
 (I used NASM 0.98.36, but earlier versions should work fine if the cpu
 directive is removed). NASM is a fast, free, and portable assembler for
 the x86 platform, available at: http://sourceforge.net/projects/nasm/

 The 32-bit NASM source code uses the NASM linker compatibility macros
 (nasmlcm) to facilitate compiler/linker independent code.

 Makefiles (GNU Make style) for a number of compilers are included.

 The compression source contains a constant, BLZ_WORKMEM_SIZE, which
 controls the size of the required workmem. This value can be lowered to
 preserve memory at the cost of compression ratio.

 The example compressors process the data in blocks of 56k to make the
 32-bit and 16-bit versions compatible. The 32-bit version can achieve
 better ratios by using larger block sizes.


Greetings and Thanks
--------------------

   - bitRAKE for some nice optimisations.
   - Arkady for help with the 16-bit code and optimisations.
   - Eugene Suslikov (SEN) for making HIEW.
   - Oleh Yuschuk for making OllyDbg.
   - LiuTaoTao for making TR.
   - NASM development team for making NASM.

 A special thanks to the beta-testers:

   - Arkady
   - Gautier
   - Lawrence E. Boothby
   - METALBRAIN
   - Oleg Prokhorov
   - Veit Kannegieser


License
-------

 BriefLZ is made available under the zlib license:

   BriefLZ  -  small fast Lempel-Ziv

   Copyright (c) 2002-2003 by Joergen Ibsen / Jibz
   All Rights Reserved

   http://www.ibsensoftware.com/

   This software is provided 'as-is', without any express or implied
   warranty. In no event will the authors be held liable for any damages
   arising from the use of this software.

   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it
   freely, subject to the following restrictions:

     1. The origin of this software must not be misrepresented; you must
        not claim that you wrote the original software. If you use this
        software in a product, an acknowledgment in the product
        documentation would be appreciated but is not required.

     2. Altered source versions must be plainly marked as such, and must
        not be misrepresented as being the original software.

     3. This notice may not be removed or altered from any source
        distribution.


History
-------

 v1.02  *: Made it more obvious that blz_depack requires the length
           of the depacked data, not the packed data. Updated the
           documentation.

 v1.01   : Made a few changes in the C source.

 v1.00  *: First release.

 Project started November 12th 2002.
