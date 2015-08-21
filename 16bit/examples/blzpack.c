/*
 * blzpack - BriefLZ example
 *
 * Copyright (c) 2002-2015 Joergen Ibsen
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must
 *      not claim that you wrote the original software. If you use this
 *      software in a product, an acknowledgment in the product
 *      documentation would be appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must
 *      not be misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any source
 *      distribution.
 */

/*
 * This is a simple example packer, which can compress and decompress a
 * single file using BriefLZ.
 *
 * It processes the data in blocks of 56k to make the 32-bit and 16-bit
 * versions compatible. The 32-bit version can achieve better ratios by
 * using larger block sizes.
 *
 * Each compressed block starts with a 24 byte header with the following
 * format:
 *
 *   - 32-bit signature (string "blz",0x1A)
 *   - 32-bit format version (1 in current version)
 *   - 32-bit size of compressed data following header
 *   - 32-bit CRC32 value of compressed data
 *   - 32-bit size of original uncompressed data
 *   - 32-bit CRC32 value of original uncompressed data
 *
 * All values in the header are stored in network order (big endian, most
 * significant byte first), and are read and written using the get_uint32()
 * and put_uint32() functions.
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <stddef.h>
#include <limits.h>

#include "brieflz.h"

/*
 * The block-size used to process data.
 */
#define BLOCK_SIZE (56u * 1024u)

/*
 * The size of the block header.
 */
#define HEADER_SIZE (6 * 4)

/*
 * Unsigned char type.
 */
typedef unsigned char byte;

/*
 * Get the low-order 8 bits of a value.
 */
#if CHAR_BIT == 8
# define octet(v) ((byte) (v))
#else
# define octet(v) ((v) & 0x00ffu)
#endif

/*
 * Store a 32-bit unsigned value in network order.
 */
static void put_uint32(byte *p, unsigned long val)
{
	p[0] = octet(val >> 24);
	p[1] = octet(val >> 16);
	p[2] = octet(val >> 8);
	p[3] = octet(val);
}

/*
 * Read a 32-bit unsigned value in network order.
 */
static unsigned long get_uint32(const byte *p)
{
	return ((unsigned long) octet(p[0]) << 24)
	       | ((unsigned long) octet(p[1]) << 16)
	       | ((unsigned long) octet(p[2]) << 8)
	       | ((unsigned long) octet(p[3]));
}

/*
 * Compute ratio between two numbers.
 */
unsigned int ratio(unsigned long x, unsigned long y)
{
	if (x <= ULONG_MAX / 100) {
		x *= 100;
	}
	else {
		y /= 100;
	}

	if (y == 0) {
		y = 1;
	}

	return (unsigned int) (x / y);
}

/*
 * Compress a file.
 */
int compress_file(const char *oldname, const char *packedname)
{
	byte header[HEADER_SIZE] = { 0x62, 0x6C, 0x7A, 0x1A, 0, 0, 0, 1 };
	FILE *oldfile;
	FILE *packedfile;
	unsigned long insize = 0, outsize = 0;
	static const char rotator[] = "-\\|/";
	unsigned int counter = 0;
	size_t n_read;
	clock_t clocks;
	byte *data, *packed, *workmem;

	/* allocate memory */
	if ((data = (byte *) malloc(BLOCK_SIZE)) == NULL
	    || (packed = (byte *) malloc(blz_max_packed_size(BLOCK_SIZE))) == NULL
	    || (workmem = (byte *) malloc(blz_workmem_size(BLOCK_SIZE))) == NULL) {
		printf("ERR: not enough memory\n");
		return 1;
	}

	/* open input file */
	if ((oldfile = fopen(oldname, "rb")) == NULL) {
		printf("ERR: unable to open input file\n");
		return 1;
	}

	/* create output file */
	if ((packedfile = fopen(packedname, "wb")) == NULL) {
		printf("ERR: unable to open output file\n");
		return 1;
	}

	clocks = clock();

	/* while we are able to read data from input file .. */
	while ((n_read = fread(data, 1, BLOCK_SIZE, oldfile)) > 0) {
		size_t packedsize;

		/* show a little progress indicator */
		printf("%c\r", rotator[counter]);
		counter = (counter + 1) & 0x03;

		/* compress data block */
		packedsize = blz_pack(data, packed, n_read, workmem);

		/* check for compression error */
		if (packedsize == 0) {
			printf("ERR: an error occured while compressing\n");
			return 1;
		}

		/* put block-specific values into header */
		put_uint32(header + 2 * 4, packedsize);
		put_uint32(header + 3 * 4, blz_crc32(packed, packedsize, 0));
		put_uint32(header + 4 * 4, n_read);
		put_uint32(header + 5 * 4, blz_crc32(data, n_read, 0));

		/* write header and compressed data */
		fwrite(header, 1, sizeof(header), packedfile);
		fwrite(packed, 1, packedsize, packedfile);

		/* sum input and output size */
		insize += n_read;
		outsize += packedsize + sizeof(header);
	}

	clocks = clock() - clocks;

	/* show result */
	printf("compressed %lu -> %lu bytes (%u%%) in %.2f seconds\n",
	       insize, outsize, ratio(outsize, insize),
	       (double) clocks / (double) CLOCKS_PER_SEC);

	/* close files */
	fclose(packedfile);
	fclose(oldfile);

	/* free memory */
	free(workmem);
	free(packed);
	free(data);

	return 0;
}

/*
 * Decompress a file.
 */
int decompress_file(const char *packedname, const char *newname)
{
	byte header[HEADER_SIZE];
	FILE *newfile;
	FILE *packedfile;
	unsigned long insize = 0, outsize = 0;
	static const char rotator[] = "-\\|/";
	unsigned int counter = 0;
	clock_t clocks;
	byte *data, *packed;
	size_t max_packed_size;

	max_packed_size = blz_max_packed_size(BLOCK_SIZE);

	/* allocate memory */
	if ((data = (byte *) malloc(BLOCK_SIZE)) == NULL
	    || (packed = (byte *) malloc(max_packed_size)) == NULL) {
		printf("ERR: not enough memory\n");
		return 1;
	}

	/* open input file */
	if ((packedfile = fopen(packedname, "rb")) == NULL) {
		printf("ERR: unable to open input file\n");
		return 1;
	}

	/* create output file */
	if ((newfile = fopen(newname, "wb")) == NULL) {
		printf("ERR: unable to open output file\n");
		return 1;
	}

	clocks = clock();

	/* while we are able to read a header from input file .. */
	while (fread(header, 1, sizeof(header), packedfile) == sizeof(header)) {
		size_t hdr_packedsize, hdr_depackedsize, depackedsize;

		/* show a little progress indicator */
		printf("%c\r", rotator[counter]);
		counter = (counter + 1) & 0x03;

		/* verify values in header */
		if (get_uint32(header + 0 * 4) != 0x626C7A1Aul /* "blz\x1A" */
		    || get_uint32(header + 1 * 4) != 1
		    || get_uint32(header + 2 * 4) > max_packed_size
		    || get_uint32(header + 4 * 4) > BLOCK_SIZE) {
			printf("ERR: invalid header in compressed file\n");
			return 1;
		}

		/* get compressed and original size from header */
		hdr_packedsize = (size_t) get_uint32(header + 2 * 4);
		hdr_depackedsize = (size_t) get_uint32(header + 4 * 4);

		/* read compressed data */
		if (fread(packed, 1, hdr_packedsize, packedfile) != hdr_packedsize) {
			printf("ERR: error reading block from compressed file\n");
			return 1;
		}

		/* check CRC32 of compressed data */
		if (get_uint32(header + 3 * 4) != blz_crc32(packed, hdr_packedsize, 0)) {
			printf("ERR: compressed data crc error\n");
			return 1;
		}

		/* decompress data */
		depackedsize = blz_depack(packed, data, hdr_depackedsize);

		/* check for decompression error */
		if (depackedsize != hdr_depackedsize) {
			printf("ERR: an error occured while decompressing\n");
			return 1;
		}

		/* check CRC32 of decompressed data */
		if (get_uint32(header + 5 * 4) != blz_crc32(data, depackedsize, 0)) {
			printf("ERR: decompressed file crc error\n");
			return 1;
		}

		/* write decompressed data */
		fwrite(data, 1, depackedsize, newfile);

		/* sum input and output size */
		insize += hdr_packedsize + sizeof(header);
		outsize += depackedsize;
	}

	clocks = clock() - clocks;

	/* show result */
	printf("decompressed %lu -> %lu bytes in %.2f seconds\n",
	       insize, outsize,
	       (double) clocks / (double) CLOCKS_PER_SEC);

	/* close files */
	fclose(packedfile);
	fclose(newfile);

	/* free memory */
	free(packed);
	free(data);

	return 0;
}

/*
 * Show program syntax.
 */
void show_syntax(void)
{
	printf("Licensed under the zlib license.\n\n"
	       "  Syntax:\n\n"
	       "    compress    :  blzpack c <file> <packed_file>\n"
	       "    decompress  :  blzpack d <packed_file> <depacked_file>\n\n");
}

/*
 * Main.
 */
int main(int argc, char *argv[])
{
	/* show banner */
	printf("BriefLZ example\n"
	       "Copyright 2002-2015 Joergen Ibsen (www.ibsensoftware.com)\n\n");

	/* check number of arguments */
	if (argc != 4) {
		show_syntax();
		return 1;
	}

#ifdef __WATCOMC__
	/* Unlike BC, which unbuffers stdout if it is a device, OpenWatcom 1.2
	   line buffers stdout; this prevents "rotator" trick based on output
	   of "\r" and writing new line over previous. To make rotator work
	   we unbuffer stdout manually:
	*/
	setbuf(stdout, NULL);
#endif

	/* check first character of first argument to determine action */
	if (argv[1][0] && argv[1][1] == '\0') {
		switch (argv[1][0]) {
		/* compress file */
		case 'c':
		case 'C':
			return compress_file(argv[2], argv[3]);

		/* decompress file */
		case 'd':
		case 'D':
			return decompress_file(argv[2], argv[3]);
		}
	}

	/* show program syntax */
	show_syntax();
	return 1;
}
