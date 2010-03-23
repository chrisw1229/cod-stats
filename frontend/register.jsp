<%@ page import="java.io.*, java.util.*, java.net.*" %>

<%
  String basePath = config.getServletContext().getRealPath(".");
  File photoDir = new File(basePath + File.separator + "photos");
  File[] photoFiles = photoDir.listFiles(new FilenameFilter() {
    public boolean accept(File dir, String name) {
      return name.endsWith(".jpg");    
    }
  });

  StringBuilder nameData = new StringBuilder();
  BufferedReader reader = null;
  try {
     URL url = new URL("http://localhost/stats/players/index.json");
     URLConnection conn = url.openConnection();
     reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));

     String line = reader.readLine();
     while (line != null) {
         nameData.append(line);
         line = reader.readLine();
     }
   } catch(Throwable err) {
      err.printStackTrace();
   } finally {
      if (reader != null) {
         reader.close();
      }
   }
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>CoD:UO Stats - Register</title>
    <link type="image/x-icon" href="styles/images/favicon.png" rel="shortcut icon"/>

    <link type="text/css" href="theme/jquery-ui.css" rel="stylesheet"/>
    <link type="text/css" href="styles/common.css" rel="stylesheet"/>

    <style>
      #photos img {
        border: 1px solid #38563A;
        cursor: pointer;
        display: block;
        margin: 10px;
      }
      .entry {
        cursor: pointer;
        margin: 2px;
        padding: 4px;
      }
      .ip {
        padding-left: 32px;
        text-align: right;
      }
    </style>
    <script type="text/javascript" src="scripts/lib/jquery.js"></script>
    <script type="text/javascript" src="scripts/lib/jquery-ui.js"></script>

    <script type="text/javascript">
      $(function() {
        var selection = {};

        $("#photos").hide();
        $("#names").hide();

        var reg = eval($("#registration").text());
        var namesDiv = $("#names");
        for (var i = 0; i < reg.length; i++) {
          var entryDiv = $('<div class="ui-state-highlight entry"/>').appendTo(namesDiv);
          $('<span class="name">' + reg[i].name + '</span>').appendTo(entryDiv);
          $('<span class="ip">' + reg[i].ip + '</span>').appendTo(entryDiv);
        } 
        
        $("#photos img").click(function(e) {
          $(this).siblings().hide();
          selection.photo = $(this).attr("src");
        });

        $("#photo-button").click(function(e) {
          $("#photos").show();
          $("#photos img").show();
        });

        $("#name-button").click(function(e) {
          $("#names").show();
          $("#names div").show();
        });

        $("#names div").click(function(e) {
          $(this).siblings().hide();
          selection.name = $(".name", this).text();
          selection.ip = $(".ip", this).text();
        });

        $("#submit-button").click(function(e) {
          $("#message").text("Sending...");
          var options = {
            url: "http://gday/stats/registration",
            data: selection,
            success: function() { $("#message").text("Submitted.") },
            error: function() { $("#message").text("Failed.") }
          }
          $.ajax(options);
        });
      });
    </script>
  </head>

  <body>
    <div id="registration" style="display:none;"><%= nameData.toString() %></div>

    <table style="margin:10px;">
    <tr>
    <td>
    <div id="photo-button" class="ui-state-default ui-corner-all" style="cursor:pointer;padding:4px 0;">
      <div style="display:inline;margin-left:4px;">Choose Photo</div>
      <span class="ui-icon ui-icon-circle-triangle-s" style="float:right;margin:0 4px;"/>
    </div>
    </td>
    <td style="width:400px;">
    <div id="name-button" class="ui-state-default ui-corner-all" style="cursor:pointer;padding:4px 0;">
      <div style="display:inline;margin-left:4px;">Choose Name</div>
      <span class="ui-icon ui-icon-circle-triangle-s" style="float:right;margin:0 4px;"/>
    </div>
    </td>
    <td>
    <div id="submit-button" class="ui-state-default ui-corner-all" style="cursor:pointer;padding:4px 0;">
      <div style="margin:0 4px;">Submit</div>
    </div>
    </td>
    <td id="message"></td>
    </tr>
    <tr>
    <td valign="top">
    <div id="photos" style="float:left;">
      <% for (File photoFile : photoFiles) { %>
        <img src="photos/<%= photoFile.getName() %>"/>
      <% } %>
    </div>
    </td>
    <td valign="top">
    <div id="names">
    
    </div>
    </td>
    <td></td>
    <td></td>
    </tr>
    </table>
  </body>
</html>