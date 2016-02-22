##
## blzpack - BriefLZ example
##
## GCC Makefile
##

.SUFFIXES:

.PHONY: clean all

CFLAGS = -Wall -Wextra -pedantic -O2 -flto
CPPFLAGS = -DNDEBUG -I..

ifeq ($(OS),Windows_NT)
  LDFLAGS += -static
  ifeq ($(CC),cc)
    CC = gcc
  endif
endif

objs = blzpack.o parg.o brieflz.o depack.o

target = blzpack

all: $(target)

%.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

%.o : ../%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(target): $(objs)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(objs) $(target)

blzpack.o: ../brieflz.h parg.h
parg.o: parg.h
brieflz.o: ../brieflz.h
depack.o: ../brieflz.h
