<%--
    Talis - Building Block to provide support for Talis aspire
    Copyright (C) 2013  Simon P Booth and Talis Education Limited

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    Contact: s.p.booth@stir.ac.uk

    Version history:
      1.0.0 11-Feb-13 Initial release
      1.0.1 13-Feb-13 Fixed bug with missing description
      1.0.2 18-Feb-13 Sections in correct order and time-period implemented
      1.0.3 28-Feb-13 Maintenance periods
      1.0.4 05-Mar-13 BbSession used to cache data
      1.0.5 06-Mar-13 Fixed bug with cached sections
      1.0.6 15-Mar-13 Handle no server (output message saying try again later)
--%>
<%@page language="java" 
        import="org.oscelot.talis.*,
                com.spvsoftwareproducts.blackboard.utils.*,
                com.talisaspire.*,
                java.net.*,
                java.util.*,
                java.text.*,
				java.text.*,
				blackboard.data.content.Content,
				blackboard.data.user.User,
				blackboard.data.course.*,
				blackboard.persist.course.*,
				blackboard.platform.log.Log,
				org.apache.commons.lang.StringEscapeUtils"
        contentType="application/rss+xml; charset=UTF-8"
        errorPage="error.jsp"
        pageEncoding="UTF-8"%>

<%-- 
  This file generates an RSS feed of a users' talis ASPIRE Resource 
  Lists. The username is passed userid. Security is provided by a
  shared secret. The incoming parameters are
  
  utc    - utc time
  userid - username of the feed required
  mac    - MD5(utc + username + secret)
  
  if the passed in mac equals the locally calculated then the feed is sent
  
 --%>
  <%

  String macStr = "";
  String protocol = request.getProtocol();

  // Get settings
  B2Context b2Context = new B2Context(request);
  String aspireBaseUrl = b2Context.getSetting("aspireBaseUrl");
  String targetKg = b2Context.getSetting("targetNodeType");
  String debugMode = b2Context.getSetting("debugMode");
  String sectionMode = b2Context.getSetting(true, false, "sectionMode");
  String rss = b2Context.getSetting("rss");
  String regex = b2Context.getSetting("regexCourseId");
  String regexrpl = b2Context.getSetting("regexCourseIdReplacement");
  String regextp = b2Context.getSetting("regexTimePeriod");
  String regextprpl = b2Context.getSetting("regexTimePeriodReplacement");
  String useCourseName = b2Context.getSetting("useCourseName");

  
  // RSS option is off
  if (!rss.equals("true")) {
    out.println("RSS not enabled");
    return;
  }
  
  String secret = b2Context.getSetting("secret");
  String serverName = protocol.substring(0, protocol.indexOf("/")) + "://" + request.getHeader("host");

  // For calculating MAC --- get utc
  Date now = new Date();
  Long lnow = now.getTime();
  
  // Special check for Stirling
  String userAgent = request.getHeader("user-agent");
  if (!userAgent.equals("mStir")) {
    response.sendRedirect("Sorry.jsp");
    return;
  }

  String UTC = request.getParameter("utc");
  String Mac = request.getParameter("mac");
  String username = request.getParameter("userid");
  String type = "";
  
  MD5 digest = new MD5(UTC + username + secret);
  String check = digest.getMD5();

  if (!check.equals(Mac)) {
    throw new Exception("security failed");
  }
 
  Format fomatter = new SimpleDateFormat("E, dd MMM yyyy HH:mm:ss Z");
  String pubDate = fomatter.format(System.currentTimeMillis());
  
  out.println("<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?>");
  out.println("<rss version=\"2.0\">");
  
  // Get the user object
  blackboard.persist.user.UserDbLoader uLoader = blackboard.persist.user.UserDbLoader.Default.getInstance();
  User user = uLoader.loadByUserName(username);

  out.println("<channel>");
  out.println("  <title>Resource Lsts for " + user.getGivenName() + " " + user.getFamilyName()+ "</title>");
  out.println("    <link>" + serverName + "/</link>");
  out.println("    <description>Talis ASPIRE Resource Lists</description>");
  
  // Get list of courses for the user
  List<Course>cList = (List<Course>) CourseDbLoader.Default.getInstance().loadByUserId(user.getId()); 

  for (Course c : cList) {
    
    // Check that course hasn't closed
    if (c.getEndDate() != null && c.getEndDate().before(Calendar.getInstance())) continue;

    // Get CourseMembership
    CourseMembership cm = CourseMembershipDbLoader.Default.getInstance().loadByCourseAndUserId(c.getId(), user.getId());
    if (!cm.getIsAvailable()) continue;
    

	String courseIdSource ="";
	if (useCourseName.equals("true")){
		courseIdSource = c.getTitle();
	} else {
		courseIdSource = c.getCourseId();
	}

	String timePeriodSource = c.getCourseId();


    TAResourceList rl = new TAResourceList(aspireBaseUrl, targetKg, regex, regexrpl, regextp, regextprpl, courseIdSource, timePeriodSource, debugMode, sectionMode);
    ArrayList<TAList> taLists = rl.getLists();
    if (rl.getCode() != Utils.SOCKETTIMEOUT) {
      for (TAList list : taLists) {
        String sectionText = ((list.getSectionItems() == 1) ? b2Context.getResourceString("block.language.section") : b2Context.getResourceString("block.language.sections"));
        String itemText = ((list.getListItems() == 1) ? b2Context.getResourceString("block.language.item") : b2Context.getResourceString("block.language.items"));                 
     
        out.println("  <item>");
        out.println("    <title>" +  StringEscapeUtils.escapeHtml(list.getListName()) +  "</title>");
        out.println("    <link><![CDATA["  + list.getListURI() +  "]]></link>");
        out.println("    <description>(" + list.getSectionItems() + " " + sectionText + ", " + list.getListItems() + " " + itemText + ")</description>");
        out.println("    <pubDate>" + pubDate + "</pubDate>");
        out.println("  </item>");
      } 
    } else {
      out.println("  <item>");
      out.println("    <title>" +  b2Context.getResourceString("learningpage.noserver") +  "</title>");
      out.println("    <link></link>");
      out.println("    <description></description>");
      out.println("    <pubDate>" + pubDate + "</pubDate>");
      out.println("  </item>");
      break;
    }
  }
  
  out.println("</channel>");
  out.println("</rss>");
  
  Log log = Utils.getLogger("talis");
  log.logInfo("RSS: " + username);

  %>