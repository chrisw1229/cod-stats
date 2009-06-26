/* -----------------------------------------------------------------------------
 * RCS $Id: Exp $
 * (C) STOOP Software, 2008.
 * -----------------------------------------------------------------------------
 */

package org.stoop;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 
 * @author Chris Ward
 */
public class PropertiesReader {

   private static final String DIR = "C:/develop/cod-stats/data/weapons";

   private static final int BUFFER_SIZE = 524288; // 512 KB

   public static void main(String[] args) {
      File dir = new File(DIR);
      for (File file : dir.listFiles()) {
         processFile(file);
      }
   }

   private static void processFile(File file) {
      BufferedReader reader = null;

      Map<String, String> props = new HashMap<String, String>();
      try {
         InputStream input = new FileInputStream(file);
         reader = new BufferedReader(new InputStreamReader(input), BUFFER_SIZE);
         String line = reader.readLine();

         int pos = line.indexOf("\\");
         if (pos < 0) {
            return;
         }

         // Ignore the first identifier
         line = line.substring(pos + 1);

         while (line != null) {
            pos = line.indexOf("\\");
            String key = line.substring(0, pos);
            String value = "";
            line = line.substring(pos + 1);
            if (line.startsWith("\\")) {
               line = line.substring(1);
            } else {
               pos = line.indexOf("\\");
               if (pos < 0) {
                  value = line;
                  line = null;
               } else {
                  value = line.substring(0, pos);
                  line = line.substring(pos + 1);
               }
            }
            props.put(key, value);
         }
      } catch (FileNotFoundException err) {
         err.printStackTrace();
      } catch (IOException err) {
         err.printStackTrace();
      } finally {
         if (reader != null) {
            try {
               reader.close();
            } catch (IOException err) {
               err.printStackTrace();
            }
         }
      }

      List<String> keys = new ArrayList<String>();
      keys.addAll(props.keySet());
      Collections.sort(keys, String.CASE_INSENSITIVE_ORDER);

      StringBuilder builder = new StringBuilder();
      for (String key : keys) {
         if (builder.length() > 0) {
            builder.append("\n");
         }
         builder.append(key).append("=").append(props.get(key));
      }

      OutputStream output = null;
      try {
         output = new FileOutputStream(file);
         output.write(builder.toString().getBytes());
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