##
## BriefLZ - small fast Lempel-Ziv
##
## Visual C/C++ dll makefile (GNU Make)
##
## Copyright (c) 2002-2015 Joergen Ibsen
##
## This software is provided 'as-is', without any express or implied
## warranty. In no event will the authors be held liable for any damages
## arising from the use of this software.
##
## Permission is granted to anyone to use this software for any purpose,
## including commercial applications, and to alter it and redistribute it
## freely, subject to the following restrictions:
##
##   1. The origin of this software must not be misrepresented; you must
##      not claim that you wrote the original software. If you use this
##      software in a product, an acknowledgment in the product
##      documentation would be appreciated but is not required.
##
##   2. Altered source versions must be plainly marked as such, and must
##      not be misrepresented as being the original software.
##
##   3. This notice may not be removed or altered from any source
##      distribution.
##

## --- paths ------------------------------------------------------

srcdir   = ..\..\src\fast


## --- files ------------------------------------------------------

target   = brieflz.dll
objects  = brieflz.obj crc32.obj depack.obj

temps    = brieflz.lib brieflz.exp


## --- flags ------------------------------------------------------


## --- rules -------------------------------------------------------

.PHONY: all clean

all: $(target)

$(target): $(objects)
	del /Q $@
	link /dll /nodefaultlib /noentry /def:brieflz.def /filealign:512 /out:$@ $^

%.obj : $(srcdir)\%.nas
	nasm -o $@ -f obj -DLCM_OBJ -DLCM_DLL -O3 -i$(srcdir)/ $<

%.obj : $(srcdir)\%.c
	cl /nologo /W3 /O2 /Zl /c /DBLZ_DLL_BUILD /I. $<

clean:
	del /Q $(target) $(objects) $(temps)


## --- dependencies -----------------------------------------------
