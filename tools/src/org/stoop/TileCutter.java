/* -----------------------------------------------------------------------------
 * RCS $Id: Exp $
 * (C) STOOP Software, 2008.
 * -----------------------------------------------------------------------------
 */

package org.stoop;

import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.imageio.ImageIO;

/**
 * 
 * @author Chris Ward
 */
public class TileCutter {

   private static final int TILE_SIZE = 256;

   private static final String TILE_NAME = "mp_uo_carentan";

   private static final String IMAGE_EXT = "jpg";

   private static final String INPUT_PATH = "C:/develop/cod-stats/data/maps/"
         + TILE_NAME + "/" + TILE_NAME;

   private static final String OUTPUT_PATH = "C:/develop/cod-stats/frontend/tiles/"
         + TILE_NAME + "/";

   public static void main(String[] args) {
      System.out.println("Starting tile cutter...");

      // Clean the target output folder
      cleanOutput();

      boolean running = true;
      int zoom = 0;

      System.out.println("Processing new tiles...");
      do {
         System.out.println("Zoom Level: " + zoom);
         System.out.print(" - Loading source image...");
         BufferedImage image = loadImage(zoom + "." + IMAGE_EXT);
         if (image == null) {
            System.out.println("NONE");
            break;
         }
         System.out.println("DONE");

         System.out.print(" - Cutting and saving tiles...");
         int y = 0;
         for (int r = 0; r < image.getHeight(); r += TILE_SIZE) {
            int x = 0;
            for (int c = 0; c < image.getWidth(); c += TILE_SIZE) {
               int width = TILE_SIZE;
               int height = TILE_SIZE;
               if (c + width > image.getWidth()) {
                  width = image.getWidth() - c;
               }
               if (r + height > image.getHeight()) {
                  height = image.getHeight() - r;
               }
               BufferedImage tile = image.getSubimage(c, r, width, height);
               saveTile(zoom, y, x++, tile);
            }
            y++;
         }
         System.out.println("DONE");
         zoom++;
      } while (running);

      System.out.println("Exiting tile cutter.");
   }

   private static void cleanOutput() {
      System.out.print("Deleting old tiles...");
      File outputDir = new File(OUTPUT_PATH);
      File[] tiles = outputDir.listFiles(new FilenameFilter() {

         @Override
         public boolean accept(File dir, String name) {
            return name.endsWith(".jpg") || name.endsWith(".jpeg");
         }

      });
      if (tiles != null) {
         for (File tile : tiles) {
            tile.delete();
         }
      }
      outputDir.mkdirs();
      System.out.println("DONE");
   }

   private static BufferedImage loadImage(String name) {
      File imageFile = new File(INPUT_PATH + name);
      if (!imageFile.exists()) {
         return null;
      }

      InputStream input = null;
      try {
         input = new BufferedInputStream(new FileInputStream(imageFile));
         return ImageIO.read(input);
      } catch (FileNotFoundException err) {
         err.printStackTrace();
      } catch (IOException err) {
         err.printStackTrace();
      } finally {
         if (input != null) {
            try {
               input.close();
            } catch (IOException err) {
               err.printStackTrace();
            }
         }
      }
      return null;
   }

   private static void saveImage(String name, BufferedImage image) {
      OutputStream output = null;
      try {
         output = new BufferedOutputStream(new FileOutputStream(OUTPUT_PATH
               + name));
         ImageIO.write(image, IMAGE_EXT, output);
      } catch (FileNotFoundException err) {
         err.printStackTrace();
      } catch (IOException err) {
         err.printStackTrace();
      } finally {
         if (output != null) {
            try {
               output.close();
            } catch (IOException err) {
               err.printStackTrace();
            }
         }
      }
   }

   private static void saveTile(int z, int y, int x, BufferedImage tile) {
      saveImage("tile_" + z + "_" + y + "_" + x + "." + IMAGE_EXT, tile);
   }
}

/*
 * -----------------------------------------------------------------------------
 * (C) Subliminal Software, 2006.
 * -----------------------------------------------------------------------------
 */