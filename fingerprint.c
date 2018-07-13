/*
    FingerJetFX OSE -- Fingerprint Feature Extractor, Open Source Edition

    Copyright (c) 2011 by DigitalPersona, Inc. All rights reserved.

    DigitalPersona, FingerJet, and FingerJetFX are registered trademarks 
    or trademarks of DigitalPersona, Inc. in the United States and other
    countries.

    FingerJetFX OSE is open source software that you may modify and/or
    redistribute under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation, either version 3 of the 
    License, or (at your option) any later version, provided that the 
    conditions specified in the COPYRIGHT.txt file provided with this 
    software are met.
 
    For more information, please visit digitalpersona.com/fingerjetfx.
*/ 
/*
      BINARY: fjfxSample - Sample Code for Fingerprint Feature Extractor

      ALGORITHM:      Alexander Ivanisov
                      Yi Chen
                      Salil Prabhakar
      IMPLEMENTATION: Alexander Ivanisov
                      Jacob Kaminsky
                      Lixin Wei
      DATE:           11/08/2011
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <fjfx.h>

#include "pm_c_util.h"
#include "pnm.h"
#include "bmp.h"
#include "bmptopnm.h"
#include "shhopt.h"
#include "nstring.h"

static xelval const bmpMaxval = 255;
    /* The maxval for intensity values in a BMP image -- either in a
       truecolor raster or in a colormap
    */

static const char *ifname;

int main(int argc, char ** argv) {
  FILE *fp = 0;
  int height, width, gray;
  unsigned int size;
  void * image = 0;
  size_t n;
  int err;
  unsigned char tmpl[FJFX_FMD_BUFFER_SIZE] = {0};

  int endok;
  FILE * ifP;
  int outputType;
  char tmpfile[25];
  int  tmpFd;
  bool grayPresent, colorPresent;
        /* These tell whether the image contains shades of gray other than
           black and white and whether it has colors other than black, white,
           and gray.
        */
  int cols, rows;
  unsigned char **BMPraster;
        /* The raster part of the BMP image, as a row x column array, with
           each element being a raw byte from the BMP raster.  Note that
           BMPraster[0] is really Row 0 -- the top row of the image, even
           though the bottom row comes first in the BMP format.
        */
  unsigned int cBitCount;
        /* Number of bits in BMP raster for each pixel */
  struct pixelformat pixelformat;
        /* Format of the raster bits for a single pixel */
  xel * colormap;
        /* Malloc'ed colormap (palette) from the BMP.  Contents of map
           undefined if not a colormapped BMP.
         */

  
  if(argc != 3 || argv[1] == NULL || argv[2] == NULL) {
    printf("Fingerprint Minutia Extraction\n"
           "Usage: %s <image.pgm> <fmd.ist>\n"
           "where <image.pgm> is the binary PGM (P5) file that containing 500DPI 8-bpp grayscale figerprint image\n"
           "      <fmd.ist> is the file where to write fingerprint minutia data in ISO/IEC 19794-2 2005 format\n", argv[0]);
    return -1;
  }

  // convert bmp to pgm
  pnm_init(&argc, argv);
  pm_setMessage(true, NULL); // pass false to avoid messages

  ifP = pm_openr(argv[1]);
  ifname = argv[1];

  readBmp(ifP, &BMPraster, &cols, &rows, &grayPresent, &colorPresent, 
            &cBitCount, &pixelformat, &colormap,
            false);
  pm_close(ifP);

  if (colorPresent) {
        outputType = PPM_TYPE;
        pm_error("Unsupported input - color bmp. We accept only grey scale bmp files.");
  } else if (grayPresent) {
        outputType = PGM_TYPE;
        pm_message("Converting to PGM image format via temp file..");
  } else {
        outputType = PBM_TYPE;
        pm_error("Unsupported input. We accept only grey scale bmp files.");
  }
    
  if (outputType == PBM_TYPE  || outputType == PPM_TYPE) {
        free(colormap);
        free(BMPraster);
        return 16;
    } else {
        memset(tmpfile, 0, sizeof(tmpfile));
        strncpy(tmpfile, "/tmp/fingerprint-XXXXXX",23);
        mktemp(tmpfile);
        if (strlen(tmpfile) == 0) {
           printf("Cannot create uniq temp file using mktemp(). Abort.");
           return 18;
        }
        fp = fopen(tmpfile, "w+b");
        if (fp == 0) {
            printf("Cannot create temporary image file: %s\n", argv[1]);
            return 17;
        }
        pnm_writepnminit(fp, cols, rows, bmpMaxval, outputType, FALSE);
        writeRasterGen(fp, BMPraster, cols, rows, outputType, cBitCount,
                       pixelformat, colormap); 
  }
  free(colormap);
  free(BMPraster);

  // process converted file
  endok = fseek(fp, 0L, SEEK_SET);
  if (endok == -1) {
      printf("Cannot set file position to begining of file: %s. Abort.", strerror(errno));
      return 254;
  }

  n = fscanf(fp, "P5%d%d%d", &width, &height, &gray); 
  if (n != 3 || 
      gray > 256 || width > 0xffff || height > 0xffff || 
      gray <= 1 || width < 32 || height < 32) {
    printf("Image file %s is in unsupported format\n", tmpfile);
    fclose(fp);
    return 10;
  }
  
  size = width * height;
  image = malloc(size);
  if (image == 0) {
    printf("Cannot allocate image buffer: image size is %dx%d", width, height);
    return 12;
  }
  
  n = fread(image, 1, size, fp);
  fclose(fp); fp = 0;
  endok = remove(tmpfile);
  if (endok == -1) {
      printf("Warning: cannot remove temporary file %s: %s. Abort.", tmpfile, strerror(errno));
      return 254;
  }
  if (n != size) {
    printf("Image file %s is too short\n", argv[1]);
    free(image);
    return 11;
  }

  size = FJFX_FMD_BUFFER_SIZE;
  err = fjfx_create_fmd_from_raw(image, 500, height, width, FJFX_FMD_ISO_19794_2_2005, tmpl, &size);
  free(image); image = 0;
  if (err != FJFX_SUCCESS) {
    printf("Failed feature extraction\n");
    return err;
  }
  
  fp = fopen(argv[2], "wb");
  if (fp == 0) {
    printf("Cannot create output file: %s\n", argv[2]);
    return 14;
  }
  pm_message("Writing ISO/IEC 19794-2 Format Minutiae Record (FMR) file.");
  n = fwrite(tmpl, 1, size, fp);
  fclose(fp);
  if (n != size) {
    printf("Cannot write output file of size %d\n", size);
    free(image);
    return 15;
  }
  return 0;
}
