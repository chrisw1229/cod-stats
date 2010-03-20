/* -----------------------------------------------------------------------------
 * RCS $Id: Exp $
 * (C) STOOP Software, 2008.
 * -----------------------------------------------------------------------------
 */

package org.stoop;

import java.awt.Graphics;
import java.awt.Image;
import java.awt.Rectangle;
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
public class PhotoCropper {

   private static final int THUMB_SIZE = 96;

   private static final Rectangle OFFSET = new Rectangle(100, 100, 100, 100);

   private static final String IMAGE_EXT = "jpg";

   private static final String INPUT_PATH = "C:/develop/cod-stats/data/maps/enclave/";

   private static final String OUTPUT_PATH = "C:/develop/cod-stats/frontend/players/photos";

   public static void main(String[] args) {
      System.out.println("Starting photo cropper...");

      System.out.println("Getting list of photo files...");
      File[] rawFiles = new File(INPUT_PATH).listFiles(new FilenameFilter() {

         public boolean accept(File dir, String name) {
            return name.endsWith(IMAGE_EXT);
         }
      });

      File outputDir = new File(OUTPUT_PATH);
      outputDir.mkdirs();

      if (rawFiles != null && rawFiles.length > 0) {
         System.out.println("Processing new photos: " + rawFiles.length);
         for (File rawFile : rawFiles) {

            System.out.println("Loading photo file: " + rawFile);
            BufferedImage photo = loadPhoto(rawFile);
            if (photo == null) {
               System.out.println("ERROR");
               break;
            }

            System.out.println("Cropping photo...");
            BufferedImage cropped = photo.getSubimage(OFFSET.x, OFFSET.y,
                  OFFSET.width, OFFSET.height);

            System.out.println("Scaling photo to thumbnail...");
            Image scaled = cropped.getScaledInstance(THUMB_SIZE, THUMB_SIZE,
                  Image.SCALE_SMOOTH);
            BufferedImage thumbnail = new BufferedImage(THUMB_SIZE, THUMB_SIZE,
                  BufferedImage.TYPE_INT_RGB);
            Graphics g = thumbnail.getGraphics();
            g.drawImage(scaled, 0, 0, null);
            g.dispose();

            File outputFile = new File(outputDir + File.separator
                  + rawFile.getName());
            System.out.println("Saving thumbnail file: " + outputFile);
            savePhoto(outputFile, thumbnail);
            System.out.println("Complete.\n");
         }
      } else {
         System.out.println("Not photos found.");
      }

      System.out.println("Exiting photo cropper.");
   }

   private static BufferedImage loadPhoto(File photoFile) {
      if (!photoFile.exists()) {
         return null;
      }

      InputStream input = null;
      try {
         input = new BufferedInputStream(new FileInputStream(photoFile));
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

   private static void savePhoto(File photoFile, BufferedImage image) {
      OutputStream output = null;
      try {
         output = new BufferedOutputStream(new FileOutputStream(photoFile));
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
}

/*
 * -----------------------------------------------------------------------------
 * (C) Subliminal Software, 2006.
 * -----------------------------------------------------------------------------
 */