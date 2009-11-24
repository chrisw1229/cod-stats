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
public class TestServlet extends HttpServlet {

   private static final long serialVersionUID = 24992353373816849L;

   private List<Packet> packets;

   /**
    * The default constructor.
    */
   public TestServlet() {
      super();

      packets = new ArrayList<Packet>();
      packets.add(new GamePacket("carentan", "tdm", 30));
      packets.add(new MapPacket(-416.63, 727.973, -499.359, 1945.19));
      packets.add(new MapPacket(-95.1254, 712.424, -511.364, 1941.27));
      packets.add(new MapPacket(302.01, 751.127, -521.318, 1937.3));
      packets.add(new MapPacket(1398.96, 1071.05, 1734.44, 1872.86));
      packets.add(new MapPacket(370.459, 2927.74, -723, 2162));
      packets.add(new GamePacket("peaks", "tdm", 30));
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

         int ts = Integer.valueOf(request.getParameter("ts"));
         builder.append("[");
         builder.append(new TimePacket(ts + 1));
         if (ts < packets.size()) {
            builder.append(", ");
            builder.append(packets.get(ts));
         }
         builder.append("]");

         byte[] data = builder.toString().getBytes();
         response.setHeader("Cache-Control", "no-cache");
         response.setContentType("application/json");
         response.setContentLength(data.length);
         response.getOutputStream().write(data);
      }
      response.getOutputStream().close();
   }

   abstract class Packet {

      private String type;

      public Packet(String type) {
         super();

         this.type = type;
      }

      public abstract String getData();

      @Override
      public String toString() {
         return "{ type: \"" + type + "\", data: " + getData() + " }";
      }
   }

   class TimePacket extends Packet {

      private int time;

      public TimePacket(int time) {
         super("ts");

         this.time = time;
      }

      @Override
      public String getData() {
         return String.valueOf(time);
      }
   }

   class GamePacket extends Packet {

      private String map, gameType;

      private int time;

      public GamePacket(String map, String gameType, int time) {
         super("game");

         this.map = map;
         this.gameType = gameType;
         this.time = time;
      }

      @Override
      public String getData() {
         return "{ map: \"" + map + "\", type: \"" + gameType + "\", time: "
               + time + " }";
      }
   }

   class MapPacket extends Packet {

      private int dx, dy, kx, ky;

      public MapPacket(double dx, double dy, double kx, double ky) {
         super("map");

         this.dx = convertX(dx, dy);
         this.dy = convertY(dx, dy);
         this.kx = convertX(kx, ky);
         this.ky = convertY(kx, ky);
      }

      private int convertX(double x, double y) {
         return (int) (1085.8 - 0.0142 * x + 0.7238 * y);
      }

      private int convertY(double x, double y) {
         return (int) (1654.0 + 0.7171 * x + 0.0083 * y);
      }

      @Override
      public String getData() {
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