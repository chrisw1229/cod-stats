package org.stoop;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

   private Map<String, List<String>> tests;

   /**
    * The default constructor.
    */
   public TestServlet() {
      super();

      this.tests = new HashMap<String, List<String>>();
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

      // Just mirror the input back if requested
      String mirror = request.getParameter("mirror");
      if (mirror != null) {
         response.getOutputStream().write(mirror.getBytes());
      } else {

         // Get the request time stamp and test case name
         int ts = Integer.valueOf(request.getParameter("ts"));
         String testName = request.getParameter("test");

         // Build the response including the next time stamp
         StringBuilder builder = new StringBuilder();
         builder.append("[");
         builder.append("{ type: \"ts\", data: ").append(ts + 1).append(" }");

         // Attempt to load the requested test case
         List<String> packets = loadTest(testName);
         if (packets != null && ts < packets.size()) {

            // Append the packets for the current time
            String packet = packets.get(ts);
            if (packet.trim().length() > 0) {
               builder.append(", ").append(packet);
            }
         }
         builder.append("]");

         // Write the packet response
         byte[] data = builder.toString().getBytes();
         response.setHeader("Cache-Control", "no-cache");
         response.setContentType("application/json");
         response.setContentLength(data.length);
         response.getOutputStream().write(data);
      }
      response.getOutputStream().close();
   }

   private List<String> loadTest(String testName) {
      List<String> packets = tests.get(testName);
      if (packets != null) {
         return packets;
      }

      // Allocate a new list of packets
      packets = new ArrayList<String>();
      tests.put(testName, packets);

      BufferedReader reader = null;
      try {

         // Attempt to load the requested test case
         InputStream input = Thread.currentThread().getContextClassLoader()
               .getResourceAsStream("conf/" + testName + ".json");
         reader = new BufferedReader(new InputStreamReader(input));

         // Copy each line as a packet to test
         String line = reader.readLine();
         while (line != null) {
            packets.add(line);
            line = reader.readLine();
         }
      } catch (IOException err) {
         System.out.println("Unable to load test case: " + testName);
         err.printStackTrace();
      } finally {
         if (reader != null) {
            try {
               reader.close();
            } catch (IOException err) {
               System.out.println("Unable to close test case: " + testName);
               err.printStackTrace();
            }
         }
      }
      return packets;
   }
}