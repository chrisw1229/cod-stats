/*
 * RCS $Id: Exp $
 * -----------------------------------------------------------------------------
 * (C) Ball Aerospace & Technologies Corp., 2009. Copyright Act of the United
 * States: Certain ideas and concepts also contained in this material are trade
 * secrets of BSEO. Unauthorized copying or other disclosure of this material
 * will make you liable for substantial penalties. This material is the property
 * of Ball Aerospace & Technologies Corp. If the end user is the U. S.
 * Government, this proprietary software package is furnished with Restricted
 * Rights in accordance with FAR 52.227-14. This material (software and user
 * documentation) is subject to export controls imposed by the United States
 * Export Administration Act of 1979, as amended, and the International Traffic
 * In Arms Regulations (ITAR), 22 CFR 120-130. This material is for use only at
 * authorized destinations and Licensee (user) will not knowingly permit
 * exportation or re-exportation in violation of the above law and regulations
 * or any successor laws or regulations.
 * -----------------------------------------------------------------------------
 */

package org.stoop;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * This servlet acts a test harness for returning live statistics in real-time.
 * 
 * @author Chris Ward
 */
public class StatsLiveTestServlet extends HttpServlet {

   private static final long serialVersionUID = 24992353373816849L;

   private List<Entry> entries;

   /**
    * The default constructor.
    */
   public StatsLiveTestServlet() {
      super();

      entries = new ArrayList<Entry>();
      entries.add(new Entry(-416.63, 727.973, -499.359, 1945.19));
      entries.add(new Entry(-95.1254, 712.424, -511.364, 1941.27));
      entries.add(new Entry(302.01, 751.127, -521.318, 1937.3));
      entries.add(new Entry(1398.96, 1071.05, 1734.44, 1872.86));
      entries.add(new Entry(370.459, 2927.74, -723, 2162));
   }

   /*
    * (non-Javadoc)
    * 
    * @see
    * javax.servlet.http.HttpServlet#doGet(javax.servlet.http.HttpServletRequest
    * , javax.servlet.http.HttpServletResponse)
    */
   @Override
   public void doGet(final HttpServletRequest request,
         final HttpServletResponse response) throws ServletException,
         IOException {
      String input = request.getParameter("input");
      if (input != null) {
         response.getOutputStream().write(input.getBytes());
      } else {
         StringBuilder builder = new StringBuilder();

         String ts = request.getParameter("ts");
         if (ts != null) {
            builder.append("[");
            builder.append("{ type: \"map\",");
            builder.append("  data: [");
            for (int i = 0; i < entries.size(); i++) {
               builder.append(entries.get(i).toString());
               if (i < entries.size() - 1) {
                  builder.append(",");
               }
            }
            builder.append("  ]");
            builder.append("}");
            builder.append("]");
         } else {
            builder.append("[]");
         }

         byte[] data = builder.toString().getBytes();
         response.setHeader("Cache-Control", "no-cache");
         response.setContentType("application/json");
         response.setContentLength(data.length);
         response.getOutputStream().write(data);
      }
      response.getOutputStream().close();
   }

   class Entry {

      int dx, dy, kx, ky;

      public Entry(double dx, double dy, double kx, double ky) {
         super();

         this.dx = convertX(dx, dy);
         this.dy = 4096 - convertY(dx, dy);
         this.kx = convertX(kx, ky);
         this.ky = 4096 - convertY(kx, ky);
      }

      public int convertX(double x, double y) {
         return (int) (1070.3 - 0.0051 * x + 0.7253 * y);
      }

      public int convertY(double x, double y) {
         return (int) (1643.3 + 0.7346 * x + 0.0061 * y);
      }

      @Override
      public String toString() {
         return "{ kx: " + kx + ", ky: " + ky + ", dx: " + dx + ", dy: " + dy
               + " }";
      }
   }
}

/*
 * -----------------------------------------------------------------------------
 * (C) Ball Aerospace & Technologies Corp., 2009.
 * -----------------------------------------------------------------------------
 */