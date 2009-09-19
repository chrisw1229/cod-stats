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
            builder.append("    { kx: 1000, ky: 1000, dx: 1000, dy: 1000 }");
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
}

/*
 * -----------------------------------------------------------------------------
 * (C) Ball Aerospace & Technologies Corp., 2009.
 * -----------------------------------------------------------------------------
 */