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
      1.0.6 15-Mar-13 Handle no response from server (output message saying try again later)
--%>
<%@page import="sun.security.jca.GetInstance"%>
<%@page
	import="com.talisaspire.*,
                blackboard.persist.*,
                blackboard.persist.course.*,
                blackboard.data.course.*,
                blackboard.platform.plugin.*,
                blackboard.platform.security.*,
                blackboard.platform.session.*,
                blackboard.platform.log.*,
                com.spvsoftwareproducts.blackboard.utils.*,
                java.util.*,
                java.net.*,
                org.oscelot.talis.*"
	pageEncoding="UTF-8" errorPage="error.jsp"%>

<%@taglib uri="/bbNG" prefix="bbNG"%>
<%@taglib uri="/bbData" prefix="bbData"%>

<bbData:context id="ctx">
	<%
	  String onload = "";
	  String message = "";
	  String head = "";
	  String tail = "";
	  String listNo = "";
	  String itemNo = "";
	  ArrayList<String> text = new ArrayList<String>(); 
	  String url = "";
	  boolean timeout = false;
	  String cache = "c";
      
      Log log = Utils.getLogger("talis");
	  
          // Default role --- used when admins try the link and aren't enroled in the module
	  CourseMembership.Role role = CourseMembership.Role.STUDENT;
	  Course course = ctx.getCourse();
	  String path = PlugInUtil.getUri("tel", "aspire-bb-learn", "");
	  ArrayList<String> sections = new ArrayList<String>();
	  
	  B2Context b2Context = new B2Context(request);
	  String aspireBaseUrl = b2Context.getSetting("aspireBaseUrl");
	  String targetKg = b2Context.getSetting("targetNodeType");
	  String regex = b2Context.getSetting("regexCourseId");
	  String regexrpl = b2Context.getSetting("regexCourseIdReplacement");
	  String regextp = b2Context.getSetting("regexTimePeriod");
	  String regextprpl = b2Context.getSetting("regexTimePeriodReplacement");
	  String staffMessage = b2Context.getSetting("staffMessage");
	  String studentMessage = b2Context.getSetting("studentMessage");
	  String debugMode = b2Context.getSetting("debugMode");
	  String helpUrl = b2Context.getSetting("helpurl");
	  String sectionMode = b2Context.getSetting(true, false, "sectionMode");
	  String useCourseName = b2Context.getSetting("useCourseName");
	  String sessionCourseId = course.getCourseId();
	  String sessionCourseTitle = course.getTitle();
	  
	  pageContext.setAttribute("bundle", b2Context.getResourceStrings());
	  
	    if (b2Context.getSetting("maintenance").equals("true") && Utils.maintenancePeriodNow(b2Context.getSetting("starttime"), b2Context.getSetting("endtime"))) {
	%>
	<bbNG:learningSystemPage onLoad="${onload}">
		<bbNG:pageHeader>
			<bbNG:breadcrumbBar>
				<bbNG:breadcrumb title="${bundle['learningpage.title.single']}" />
			</bbNG:breadcrumbBar>
			<bbNG:pageTitleBar title="${bundle['learningpage.title.single']}"></bbNG:pageTitleBar>
		</bbNG:pageHeader>
		<%
		  out.println("<div class='noItems'>" + String.format(b2Context.getResourceString("page.system.maint.now"), Utils.endTimeHHMM(b2Context.getSetting("endtime"))) + "</div>");
		    
		    if (helpUrl != null && !helpUrl.equals("")) {
		  out.println("<div class='moduleControlWrapper u_reverseAlign'><a class='button-6' href=' " + helpUrl + "' target='_blank '>" + b2Context.getResourceString("module.help") + "</a></div>");
		    }
		%>
	</bbNG:learningSystemPage>
	<%
	  return;
	  }
	  

	  HashSet<Id> all_courses = new HashSet();
	  
	  // get child modules if this is a parent
	  if (course.isParent()){
		// this is a Child, so get all the courses in this relationship
		CourseCourseDbLoader ccdbl = CourseCourseDbLoader.Default.getInstance();
		List<CourseCourse> c_relations = ccdbl.loadByParentId(course.getId());		
		for (int i=0 ; i<c_relations.size();i++){
			all_courses.add(c_relations.get(i).getChildCourseId());
		}
		  all_courses.add(course.getId());
	  } else {
		  all_courses.add(course.getId());
	  }
	  
	  log.logDebug("CourseTool: all_courses " + Arrays.toString(all_courses.toArray()));

	  // get our session ready
	  BbSessionManagerService sessionService = BbSessionManagerServiceFactory.getInstance();
	  BbSession bbSession = sessionService.getSession(request);
	  
	  // start our page building
	  // TODO pluralisation is never going to work because taLists is empty here.
	    pageContext.setAttribute("onload", onload);
	%>

	<bbNG:learningSystemPage onLoad="${onload}">
		<bbNG:pageHeader>
			<bbNG:breadcrumbBar>			
				<bbNG:breadcrumb title="${bundle['learningpage.title.breadcrumb']}" />
			</bbNG:breadcrumbBar>
			<bbNG:pageTitleBar title="${bundle['learningpage.title.pagetitle']}"></bbNG:pageTitleBar>
		</bbNG:pageHeader>
		<bbNG:jsBlock>
			<script language="javascript" type="text/javascript">
				function doAction(jurl) {
					window.open(jurl);
				}
			</script>
		</bbNG:jsBlock>
		<%
		  // for each course
		      for (Id ac : all_courses) {
		        // show the course
		        CourseDbLoader cdbl = CourseDbLoader.Default.getInstance();
		        Course c = cdbl.loadById(ac);
		        String resourceList = bbSession.getGlobalKey(c.getBatchUid());
		        log.logDebug("CourseTool: ac= " + ac);
		        TAResourceList rl = null;
		        ArrayList<TAList> taLists = new ArrayList<TAList>();
		    	  
		        // load a resource list from session or from Talis Aspire
		        if (resourceList == null) {
		          
		          String courseIdSource = "";
		          if (useCourseName.equals("true")) {
		            courseIdSource = c.getTitle();
		          } else {
		            courseIdSource = c.getCourseId();
		          }
		          
		          String timePeriodSource = c.getCourseId();
		          
		          rl = new TAResourceList(aspireBaseUrl, targetKg, regex, regexrpl,
		              regextp, regextprpl, courseIdSource, timePeriodSource,
		              sectionMode, debugMode);
		          if (rl.getCode() == Utils.SOCKETTIMEOUT) {
		            log.logInfo("Timeout for URL: " + rl.getAspireLink());
		            timeout = true;
		          } else {
		            cache = "n";
		            Utils.setSessionKey(rl, c.getBatchUid(), bbSession);
		          }
		        } else {
		          rl = Utils.getObjectFromString(resourceList);
		        }
		        
		        // display the resource list
		        boolean isAdmin = SecurityUtil
		            .userHasEntitlement("system.administration.top.VIEW");
		        
		        head = "";
		        message = "";
		        tail = "";
		        text.clear();
		        sections.clear();
		        taLists.clear();
		        
		        if (debugMode.equals("true") && isAdmin) {
		          log.logInfo("CourseTool: Showing Debug Message for "+c.getCourseId());
		          head = "<h3>"
		              + b2Context.getResourceString("learningpage.debug.title")
		              + "</h3>";
		          message = "<p><strong>"
		              + b2Context.getResourceString("learningpage.debug.heading")
		              + "</strong><br />";
		          message += b2Context
		              .getResourceString("learningpage.debug.debugmode") + "</p>";
		          message += "<table><tr><th>"
		              + b2Context.getResourceString("learningpage.debug.property")
		              + "</th><th>"
		              + b2Context.getResourceString("learningpage.debug.value")
		              + "</th></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.baseURL")
		              + "</td><td>" + aspireBaseUrl + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.target")
		              + "</td><td>" + targetKg + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.course")
		              + "</td><td>" + sessionCourseId + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context
		                  .getResourceString("learningpage.debug.coursetitle")
		              + "</td><td>" + sessionCourseTitle + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.regex")
		              + "</td><td>" + regex + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.regexrpl")
		              + "</td><td>" + regexrpl + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.regextp")
		              + "</td><td>" + regextp + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context
		                  .getResourceString("learningpage.debug.regextprpl")
		              + "</td><td>" + regextprpl + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.code")
		              + "</td><td>" + rl.getTargetCode() + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context
		                  .getResourceString("learningpage.debug.timeperiod")
		              + "</td><td>" + rl.getTargetTimePeriod() + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.link")
		              + "</td><td>" + rl.getAspireLink() + "</td></tr>";
		          message += "<tr><td>"
		              + b2Context.getResourceString("learningpage.debug.relations")
		              + "</td><td>" + Arrays.toString(all_courses.toArray())
		              + "</td></tr>";
		          tail = "<tr><td>"
		              + "HTTP Response Code"
		              + "</td><td>" + rl.getCode() + "</td></tr></table>";
		          text.add(0, message);
		        } 
		        
		        if (!head.isEmpty()) {
		          out.println(head);
		        }
		        if (!message.isEmpty()) {
		          out.println(message);
		        }
		        if (!tail.isEmpty()) {
		          out.println(tail);
		        }
		        
		        taLists = rl.getLists();
		        //Collections.sort(taLists);
		        log.logInfo("CourseTool: taLists.size" + taLists.size());
		        if (timeout) {
		          log.logInfo("CourseTool: Showing Timeout Message for "+c.getCourseId());
		          message = "<div class='noItems'>"
		              + b2Context.getResourceString("learningpage.noserver")
		              + "</div>";
		          text.add(0, message);
		        } else if (taLists.size() == 0 || rl.getCode() == 404) {
		          log.logInfo("CourseTool: Showing no list message for "+c.getCourseId());
		          // try/catch block that deals with admins not being a member of the module (they default to student)
		          try {
		            CourseMembershipDbLoader cmLoader = (CourseMembershipDbLoader) CourseMembershipDbLoader.Default
		                .getInstance();
		            CourseMembership cm = cmLoader.loadByCourseAndUserId(ctx
		                .getCourse().getId(), ctx.getUser().getId());
		            role = cm.getRole();
		          } catch (KeyNotFoundException kfne) {
		          }
		          
		          if (b2Context.getSetting("maintenance").equals("true")
		              && Utils.maintenancePeriodFuture(b2Context
		                  .getSetting("starttime"))) {
		            message = "<div class='noItems'>"
		                + String.format(b2Context
		                    .getResourceString("page.system.maint.infuture"), Utils
		                    .endTimeDMYHHMM(b2Context.getSetting("starttime")),
		                    Utils.endTimeHHMM(b2Context.getSetting("endtime")))
		                + "</div>";
		          }
		          if (role == CourseMembership.Role.INSTRUCTOR
		              || role == CourseMembership.Role.COURSE_BUILDER
		              || role == CourseMembership.Role.TEACHING_ASSISTANT) {
		            message += Utils.textForStaff(c, b2Context);
		          } else {
		            message += "<div class='noItems'>"
		                + String.format(studentMessage, c.getTitle(),
		                    c.getCourseId()) + "</div>";
		          }
		          text.add(0, message);
		        } else if (taLists.size() == 1) {
		          log.logInfo("CourseTool: Showing single list for "+c.getCourseId());
		          head = "<h3>"
		              + b2Context.getResourceString("learningpage.heading.single")
		              + "</h3><ul class='contentList'>";
		          if (b2Context.getSetting("maintenance").equals("true")
		              && Utils.maintenancePeriodFuture(b2Context
		                  .getSetting("starttime"))) {
		            head += "<div class='noItems'>"
		                + String.format(b2Context
		                    .getResourceString("page.system.maint.infuture"), Utils
		                    .endTimeDMYHHMM(b2Context.getSetting("starttime")),
		                    Utils.endTimeHHMM(b2Context.getSetting("endtime")))
		                + "</div>";
		          }
		          message = "<li class='clearfix read'>";
		          message += "<img align='absmiddle' src='"
		              + path
		              + "images/logo.png' alt='Resource List Link' class='item_icon'>";
		          message += "<div class='item clearfix'>";
		          message += "<h3><a href='" + taLists.get(0).getListURI(ctx.getUser().getLocale())
		              + "' target='_blank'>" + taLists.get(0).getListName()
		              + "</a></h3><br />";
		          message += "</div><div class='details'>";
		          String sectionText = ((taLists.get(0).getSectionItems() == 1) ? b2Context
		              .getResourceString("block.language.section") : b2Context
		              .getResourceString("block.language.sections"));
		          String itemText = ((taLists.get(0).getListItems() == 1) ? b2Context
		              .getResourceString("block.language.item") : b2Context
		              .getResourceString("block.language.items"));
		          message += "(" + taLists.get(0).getSectionItems() + " "
		              + sectionText + ", " + taLists.get(0).getListItems() + " "
		              + itemText + ")";
		          message += ", <span class='updated' title='"
		              + taLists.get(0).getDescription() + "'>"
		              + taLists.get(0).getDescription() + "</span>";
		          message += "</div>";
		          tail = "</li></ul>";
		          log.logInfo("CourseTool: message= "+ message);
		          text.add(0, message);
		          log.logInfo("courseTool: text.size= "+ text.size());
		          onload = "doAction(\"" + taLists.get(0).getListURI(ctx.getUser().getLocale()) + "\");";
		          b2Context.setReceipt(
		              b2Context.getResourceString("learningpage.newwindow"), true);
		          sections.add(0, Utils.sectionHTML(taLists.get(0).getSections()));
		          log.logInfo("CourseTool: section=" + sections.get(0));
		        } else {
		          log.logInfo("CourseTool: Showing multiple lists for "+c.getCourseId());
		          head = "<h3>"
		              + b2Context.getResourceString("learningpage.heading.plural")
		              + "</h3><ul class='contentList'>";
		          if (b2Context.getSetting("maintenance").equals("true")
		              && Utils.maintenancePeriodFuture(b2Context
		                  .getSetting("starttime"))) {
		            head += "<div class='noItems'>"
		                + String.format(b2Context
		                    .getResourceString("page.system.maint.infuture"), Utils
		                    .endTimeDMYHHMM(b2Context.getSetting("starttime")),
		                    Utils.endTimeHHMM(b2Context.getSetting("endtime")))
		                + "</div>";
		          }
		          for (int i = 0; i < taLists.size(); i++) {
		            message = "<li class='clearfix read' id='readinglist-"+ i +"'>";
		            message += "<img align='absmiddle' src='"
		                + path
		                + "images/logo.png' alt='Resource List Link' class='item_icon'>";
		            message += "<div class='item clearfix'>";
		            message += "<h3><a href='" + taLists.get(i).getListURI(ctx.getUser().getLocale())
		                + "' target='_blank'>" + taLists.get(i).getListName()
		                + "</a></h3><br />";
		            message += "</div><div class='details'>";
		            String sectionText = ((taLists.get(i).getSectionItems() == 1) ? b2Context
		                .getResourceString("block.language.section") : b2Context
		                .getResourceString("block.language.sections"));
		            String itemText = ((taLists.get(i).getListItems() == 1) ? b2Context
		                .getResourceString("block.language.item") : b2Context
		                .getResourceString("block.language.items"));
		            message += "(" + taLists.get(i).getSectionItems() + " "
		                + sectionText + ", " + taLists.get(i).getListItems() + " "
		                + itemText + ")";
		            message += ", <span class='updated' title='"
		                + taLists.get(i).getDescription() + "'>"
		                + taLists.get(i).getDescription() + "</span>";
		            message += "</li>";
		            text.add(i, message);
		            
		            sections
		                .add(i, Utils.sectionHTML(taLists.get(i).getSections()));
		          }
		          tail += "</ul>";
		        }
		        
		        out.print(head);
		        
		        if (debugMode.equals("true") && isAdmin) {
		          out.println(text.get(0));
		        } else if (timeout || taLists.size() == 0 || rl.getCode() == 404) {
		          out.println(text.get(0));
		          log.logInfo("CourseTool: Single/404/timeout: text= "+text.get(0));
		        } else {
		          String section = "";
		          for (int i = 0; i < taLists.size(); i++) {
		            out.println(text.get(i));
		            if (sectionMode.equals("true")
		                && taLists.get(i).getSectionItems() > 0) {
		              section = sections.get(i);
		              listNo = "List" + String.valueOf(i);
		              itemNo = "Item" + String.valueOf(i);
		%>
		<bbNG:collapsibleList isDynamic="false" id="<%=listNo%>">
			<bbNG:collapsibleListItem id="<%=itemNo%>" title="Sections"
				expandOnPageLoad="false" body="<%=section%>" />

		</bbNG:collapsibleList>
		<%
		        	} 
		          }// end output of each list if
		          out.println(tail);
		          if (helpUrl != null && !helpUrl.equals("")) {
		            out.println("<div class='moduleControlWrapper u_reverseAlign'><a class='button-6' href=' "
		                + helpUrl
		                + "' target='_blank '>"
		                + b2Context.getResourceString("module.help") + "</a></div>");
		          }
		        }
		      } // end overall for loop
		      String smode = sectionMode.equals("true") ? "t" : "f";
		      
		      log.logInfo("CourseTool: "
		          + course.getCourseId().toString().replaceAll(regex, regexrpl) + "(sm: "
		          + smode + ", c: " + cache + ")");
		%>

	</bbNG:learningSystemPage>
</bbData:context>