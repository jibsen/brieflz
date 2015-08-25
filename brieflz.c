/*
 * BriefLZ - small fast Lempel-Ziv
 *
 * C packer
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

#include "brieflz.h"

/* must be a power of 2 (between 8k and 2mb appear reasonable) */
#define BLZ_WORKMEM_SIZE (1024 * 1024)

#if BLZ_WORKMEM_SIZE & (BLZ_WORKMEM_SIZE - 1)
#  error BLZ_WORKMEM_SIZE must be a power of 2
#endif

/* internal data structure */
struct blz_state {
	const unsigned char *src;
	unsigned char *dst;
	unsigned char *tagpos;
	unsigned int tag;
	unsigned int bits_left;
};

static void
blz_putbit(struct blz_state *bs, const int bit)
{
	/* check if tag is full */
	if (!bs->bits_left--) {
		/* store tag */
		bs->tagpos[0] = bs->tag & 0x00ff;
		bs->tagpos[1] = (bs->tag >> 8) & 0x00ff;

		/* init next tag */
		bs->tagpos = bs->dst;
		bs->dst += 2;
		bs->bits_left = 15;
	}

	/* shift bit into tag */
	bs->tag = (bs->tag << 1) + (bit ? 1 : 0);
}

static void
blz_putgamma(struct blz_state *bs, unsigned int val)
{
	unsigned int mask = val >> 1;

	/* mask = highest_bit(val >> 1) */
	while (mask & (mask - 1)) {
		mask &= mask - 1;
	}

	/* output gamma2-encoded bits */
	blz_putbit(bs, val & mask);

	while (mask >>= 1) {
		blz_putbit(bs, 1);
		blz_putbit(bs, val & mask);
	}

	blz_putbit(bs, 0);
}

static unsigned int
blz_hash4(const unsigned char *data)
{
	/* hash next four bytes of data[] */
	unsigned int val = data[0];
	val = (val * 317) + data[1];
	val = (val * 317) + data[2];
	val = (val * 317) + data[3];
	return val & (BLZ_WORKMEM_SIZE / sizeof(const unsigned char *) - 1);
}

unsigned int
blz_workmem_size(unsigned int src_size)
{
	(void) src_size;

	/* return required workmem size */
	return BLZ_WORKMEM_SIZE;
}

unsigned int
blz_max_packed_size(unsigned int src_size)
{
	/* return max compressed size */
	return src_size + src_size / 8 + 64;
}

unsigned int
blz_pack(const void *src, void *dst, unsigned int src_size, void *workmem)
{
	struct blz_state bs;
	const unsigned char **lookup = (const unsigned char **) workmem;
	const unsigned char *prevsrc = (const unsigned char *) src;
	unsigned int src_avail = src_size;

	/* check for empty input */
	if (src_avail == 0) {
		return 0;
	}

	/* init lookup[] */
	{
		unsigned int i;
		for (i = 0; i < BLZ_WORKMEM_SIZE / sizeof(const unsigned char *); ++i) {
			lookup[i] = 0;
		}
	}

	bs.src = (const unsigned char *) src;
	bs.dst = (unsigned char *) dst;

	/* first byte verbatim */
	*bs.dst++ = *bs.src++;

	/* check for 1 byte input */
	if (--src_avail == 0) {
		return 1;
	}

	/* init first tag */
	bs.tagpos = bs.dst;
	bs.dst += 2;
	bs.tag = 0;
	bs.bits_left = 16;

	/* main compression loop */
	while (src_avail > 4) {
		const unsigned char *p;
		unsigned int len = 0;

		/* update lookup[] up to current position */
		while (prevsrc < bs.src) {
			lookup[blz_hash4(prevsrc)] = prevsrc;
			prevsrc++;
		}

		/* look up current position */
		p = lookup[blz_hash4(bs.src)];

		/* check match */
		if (p) {
			while (len < src_avail && p[len] == bs.src[len]) {
				++len;
			}
		}

		/* output match or literal */
		if (len > 3) {
			unsigned int off = (unsigned int) (bs.src - p - 1);

			/* output match tag */
			blz_putbit(&bs, 1);

			/* output match length */
			blz_putgamma(&bs, len - 2);

			/* output match offset */
			blz_putgamma(&bs, (off >> 8) + 2);
			*bs.dst++ = off & 0x00ff;

			bs.src += len;
			src_avail -= len;
		}
		else {
			/* output literal tag */
			blz_putbit(&bs, 0);

			/* copy literal */
			*bs.dst++ = *bs.src++;
			src_avail--;
		}
	}

	/* output any remaining literals */
	while (src_avail > 0) {
		/* output literal tag */
		blz_putbit(&bs, 0);

		/* copy literal */
		*bs.dst++ = *bs.src++;
		src_avail--;
	}

	/* shift last tag into position and store */
	bs.tag <<= bs.bits_left;
	bs.tagpos[0] = bs.tag & 0x00ff;
	bs.tagpos[1] = (bs.tag >> 8) & 0x00ff;

	/* return compressed size */
	return (unsigned int) (bs.dst - (unsigned char *) dst);
}
