##
## BriefLZ  -  small fast Lempel-Ziv
##
## main build makefile (GNU Make)
##
## Copyright (c) 2002-2005 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

# make [all]        - make all dirs
# make clean        - clean all dirs
# make <dir>        - make only dir
# make <dir>.clean  - clean only dir

subdirs  = delphi djgpp dll mscoff omf
csubdirs = $(patsubst %,%.clean,$(subdirs))

.PHONY: all clean $(subdirs) $(csubdirs)

all: $(subdirs)

$(subdirs):
	$(MAKE) -C $@

clean: $(csubdirs)

$(csubdirs):
	$(MAKE) -C $(basename $@) clean
