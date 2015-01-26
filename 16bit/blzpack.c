/*
 * blzpack  -  BriefLZ 16-bit example
 *
 * Copyright (c) 2002-2003 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 *
 * This software is provided 'as-is', without any express
 * or implied warranty.  In no event will the authors be
 * held liable for any damages arising from the use of
 * this software.
 *
 * Permission is granted to anyone to use this software
 * for any purpose, including commercial applications,
 * and to alter it and redistribute it freely, subject to
 * the following restrictions:
 *
 * 1. The origin of this software must not be
 *    misrepresented; you must not claim that you
 *    wrote the original software. If you use this
 *    software in a product, an acknowledgment in
 *    the product documentation would be appreciated
 *    but is not required.
 *
 * 2. Altered source versions must be plainly marked
 *    as such, and must not be misrepresented as
 *    being the original software.
 *
 * 3. This notice may not be removed or altered from
 *    any source distribution.
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <stddef.h>

#include "brieflz.h"
#include "depack.h"
#include "crc32.h"

#define BUFSIZE (56*1024)

void compress_file(const char *oldname, const char *packedname)
{
   unsigned long header[6] = { 0x1A7A6C62, 1, 0, 0, 0, 0 };
   FILE *oldfile = NULL;
   FILE *packedfile = NULL;
   unsigned long outsize = 0;
   const char rotator[] = "-\\|/";
   unsigned short counter = 0;
   size_t n_read, packedsize;
   clock_t clock_start, clock_end;
   char *data, *packed, *workmem;

   if ((data = (char *)malloc(BUFSIZE)) == NULL)
   {
      printf("ERR: not enough memory\n");
      return;
   }

   if ((packed = (char *)malloc(blz16_max_packed_size(BUFSIZE))) == NULL)
   {
      printf("ERR: not enough memory\n");
      return;
   }

   if ((workmem = (char *)malloc(blz16_workmem_size(BUFSIZE))) == NULL)
   {
      printf("ERR: not enough memory\n");
      return;
   }

   if ((oldfile = fopen(oldname, "rb")) == NULL)
   {
      printf("ERR: unable to open input file\n");
      return;
   }

   if ((packedfile = fopen(packedname, "wb")) == NULL)
   {
      printf("ERR: unable to open output file\n");
      return;
   }

   fseek(oldfile, 0, SEEK_SET);

   clock_start = clock();

   while ((n_read = fread(data, 1, BUFSIZE, oldfile)) > 0)
   {
      printf("%c\r", rotator[counter++]);
      counter &= 0x03;

      packedsize = blz16_pack_asm((unsigned char *)data,
                                  (unsigned char *)packed,
                                  n_read,
                                  (unsigned char *)workmem);

      if (packedsize == 0)
      {
         printf("ERR: an error occured while compressing\n");
         return;
      }

      header[2] = packedsize & 0x0000ffff;
      header[3] = is16_crc32_asm((unsigned char *)packed, packedsize);
      header[4] = n_read & 0x0000ffff;
      header[5] = is16_crc32_asm((unsigned char *)data, n_read);

      fwrite(header, 1, sizeof(header), packedfile);
      fwrite(packed, 1, packedsize, packedfile);

      outsize += packedsize + sizeof(header);
   }

   clock_end = clock();

   printf("file compressed in %.2lf seconds, with %lu bytes\n",
          (double)(clock_end - clock_start) / (double)CLOCKS_PER_SEC,
          outsize);

   fclose(packedfile);
   fclose(oldfile);

   free(workmem);
   free(packed);
   free(data);
}

void decompress_file(const char *packedname, const char *newname)
{
   unsigned long header[6];
   FILE *newfile = NULL;
   FILE *packedfile = NULL;
   unsigned long outsize = 0;
   const char rotator[] = "-\\|/";
   unsigned short counter = 0;
   size_t depackedsize;
   clock_t clock_start, clock_end;
   char *data, *packed;

   if ((data = (char *)malloc(BUFSIZE)) == NULL)
   {
      printf("ERR: not enough memory\n");
      return;
   }

   if ((packed = (char *)malloc(blz16_max_packed_size(BUFSIZE))) == NULL)
   {
      printf("ERR: not enough memory\n");
      return;
   }

   if ((packedfile = fopen(packedname, "rb")) == NULL)
   {
      printf("ERR: unable to open intput file\n");
      return;
   }

   if ((newfile = fopen(newname, "wb")) == NULL)
   {
      printf("ERR: unable to open output file\n");
      return;
   }

   fseek(packedfile, 0, SEEK_SET);

   clock_start = clock();

   while (fread(header, 1, sizeof(header), packedfile) == sizeof(header))
   {
      printf("%c\r", rotator[counter++]);
      counter &= 0x03;

      if ((header[0] != 0x1A7A6C62) || (header[1] != 1) || (header[2] > BUFSIZE))
      {
         printf("ERR: invalid header in compressed file\n");
         return;
      }

      if (fread(packed, 1, header[2], packedfile) != header[2])
      {
         printf("ERR: error reading block from compressed file\n");
         return;
      }

      if (header[3] != is16_crc32_asm((unsigned char *)packed, header[2]))
      {
         printf("ERR: compressed data crc error\n");
         return;
      }

      depackedsize = blz16_depack_asm((unsigned char *)packed,
                                      (unsigned char *)data,
                                      header[4]);

      if (depackedsize != header[4])
      {
         printf("ERR: an error occured while decompressing\n");
         return;
      }

      if (header[5] != is16_crc32_asm((unsigned char *)data, depackedsize))
      {
         printf("ERR: decompressed file crc error\n");
         return;
      }

      fwrite(data, 1, depackedsize, newfile);

      outsize += depackedsize;
   }

   clock_end = clock();

   printf("file decompressed in %.2lf seconds, with %lu bytes\n",
          (double)(clock_end - clock_start) / (double)CLOCKS_PER_SEC,
          outsize);

   fclose(packedfile);
   fclose(newfile);

   free(packed);
   free(data);
}

void show_syntax()
{
   printf("syntax:\n\n"
          "   compress    :  blzpack c <file> <packed_file>\n"
          "   decompress  :  blzpack d <packed_file> <depacked_file>\n\n");
}

int main(int argc, char *argv[])
{
   printf("===============================================================================\n"
          "BriefLZ 16-bit example          Copyright (c) 2002-2003 by Joergen Ibsen / Jibz\n"
          "                                                            All Rights Reserved\n\n"
          "                                                  http://www.ibsensoftware.com/\n"
          "===============================================================================\n\n");

   if (argc < 4)
   {
      show_syntax();
      return 1;
   }

   if (argv[1][0] == 'c' || argv[1][0] == 'C')
   {

      compress_file(argv[2], argv[3]);

   } else if (argv[1][0] == 'd' || argv[1][0] == 'D')
   {

      decompress_file(argv[2], argv[3]);

   } else {

      show_syntax();
      return 1;
   }

   return 0;
}
