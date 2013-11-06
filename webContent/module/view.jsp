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
<%@page import="org.joda.time.DateTime"%>
<%@page import="java.util.*,
                java.text.*,
                com.talisaspire.*,
                com.spvsoftwareproducts.blackboard.utils.*,
                blackboard.platform.session.*, 
                blackboard.persist.*,
                blackboard.persist.course.*,
                blackboard.data.user.*, 
                blackboard.persist.user.*,
                blackboard.platform.plugin.*,
                blackboard.platform.log.Log,
                blackboard.data.course.*,org.oscelot.talis.*" 
 	    pageEncoding="UTF-8"
        errorPage="/error.jsp"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>
<%@ taglib uri="/bbData" prefix="bbData"%>

<!-- <bbData:context id="ctx"> -->
<bbNG:includedPage ctxId="ctx">
  <bbNG:jsBlock >
    <script type="text/javascript">
    function UpdateTitle(moduletitle) {
    
	  var names = document.getElementsByClassName("moduleTitle");
    
      for(i = 0; i < names.length; i++) {
        if (names[i].innerHTML == "My Resource Lists") {
    	  names[i].innerHTML = moduletitle;
        }
      }
    }
    </script>
  </bbNG:jsBlock>

  <bbNG:cssBlock>
    <style>
    /* ul.stepPanels {
      padding: 0px 0 0px 0;
      margin: 0;
      border: none;
    } 
    .noItems.divider {
      padding: 0px 0px;
    } 
    .portlet .portletList-img li img {
      display: inline;
    } */
    </style>
  </bbNG:cssBlock>

  <%
  // Get Log
  Log log = Utils.getLogger("talis"); 
  
  // Start timing
  Long start = System.currentTimeMillis();
  
  User user = ctx.getUser();
  B2Context b2Context = new B2Context(request);
  String aspireBaseUrl = b2Context.getSetting("aspireBaseUrl");
  String targetKg = b2Context.getSetting("targetNodeType");
  String useCourseName = b2Context.getSetting("useCourseName");
  String regex = b2Context.getSetting("regexCourseId");
  String regexrpl = b2Context.getSetting("regexCourseIdReplacement");
  String regextp = b2Context.getSetting("regexTimePeriod");
  String regextprpl = b2Context.getSetting("regexTimePeriodReplacement");
  String debugMode = b2Context.getSetting("debugMode");
  String helpUrl = b2Context.getSetting("helpurl");
  String sectionMode = b2Context.getSetting(true, false, "sectionMode");
  String userLocale = user.getLocale();
  String imageUrl = "";
  int total = 0;
  String sections = "";
  int i = 0;
  String listNo = "";
  String itemNo = "";
  String title = "";
  boolean maint = false;
  boolean timeout = false;
  boolean portal = false;
  String cache = "c";
  List<Course> cList = new ArrayList<Course>();
  List<Course> cExtras = new ArrayList<Course>();
  Collection<Course> cCollection = new ArrayList<Course>();

  // If course_id is present we are running in a course and so only need to worry about that
  // resource list

  String courseId = request.getParameter("course_id");
  
  if (courseId != null) {
    cList.add(ctx.getCourse());
  } else {
    // Running as portal module, get all courses
    portal = true;
    cList = (List<Course>) CourseDbLoader.Default.getInstance().loadByUserId(user.getId());
    
    // check to see if any of the courses are combined courses
   	HashSet<Id> all_courses = new HashSet();
    for(Course cl : cList){
      if (cl.isParent()){
        CourseCourseDbLoader ccdbl = CourseCourseDbLoader.Default.getInstance();
    	List<CourseCourse> c_relations = ccdbl.loadByParentId(cl.getId());
    	
    	for (int f=0 ; f<c_relations.size();f++){
    	  all_courses.add(c_relations.get(f).getChildCourseId());
   		}
      }
    }
    
    HashMap<String, Course> courseHashMap = new HashMap();
    CourseDbLoader cdbl = CourseDbLoader.Default.getInstance();
    for (Id ac : all_courses){
    	Course cc = cdbl.loadById(ac);
    	courseHashMap.put(cc.getCourseId(),cc);
    }
    for(Course cl : cList){
      courseHashMap.put(cl.getCourseId(),cl);
    }
    cCollection = courseHashMap.values();
  }
  
  if (b2Context.getSetting("maintenance").equals("true") && Utils.maintenancePeriodNow(b2Context.getSetting("starttime"), b2Context.getSetting("endtime"))) {
    out.println("<div class='noItems divider'>" + String.format(b2Context.getResourceString("page.system.maint.now"), Utils.endTimeHHMM(b2Context.getSetting("endtime"))) + "</div>");
    maint = true;
  }
  
  if (b2Context.getSetting("maintenance").equals("true") && Utils.maintenancePeriodFuture(b2Context.getSetting("starttime"))) {
    out.println("<div class='noItems divider'>" + String.format(b2Context.getResourceString("page.system.maint.infuture"), Utils.endTimeDMYHHMM(b2Context.getSetting("starttime")), Utils.endTimeHHMM(b2Context.getSetting("endtime"))) + "</div>");
  }

  if (!maint) {
    // if we are running as a course module there will be a course_id on the request
    for (Course c : cCollection) {
  
      if (c.getEndDate() != null && c.getEndDate().before(Calendar.getInstance())) continue;

      try{
	      CourseMembership cm = CourseMembershipDbLoader.Default.getInstance().loadByCourseAndUserId(c.getId(), user.getId());
	      if (!cm.getIsAvailable()) continue;
      }catch(KeyNotFoundException knfe){
      }
      // Get the course      
      BbSessionManagerService sessionService = BbSessionManagerServiceFactory.getInstance();
      BbSession bbSession = sessionService.getSession(request); 
      String resourceList = bbSession.getGlobalKey(c.getBatchUid());
      
      String courseIdSource = "";
      if(useCourseName.equals("true")){
    	courseIdSource = c.getTitle();
   	  } else {
   		courseIdSource = c.getCourseId();
      }

      String timePeriodSource = c.getCourseId();
      
      TAResourceList rl = null;
      if (resourceList == null) {
        rl = new TAResourceList(aspireBaseUrl, targetKg, regex, regexrpl, regextp, regextprpl, courseIdSource, timePeriodSource, sectionMode, debugMode);
        if (rl.getCode() == Utils.SOCKETTIMEOUT) {
          timeout = true;
          break;
        }
        cache = "n";
        Utils.setSessionKey(rl, c.getBatchUid(), bbSession);
      } else {
        rl = Utils.getObjectFromString(resourceList);
      }
      
      ArrayList<TAList> taLists = rl.getLists();
    
      total += taLists.size();
      
      out.println("<!-- User Lanaguage: " + userLocale + " -->");
      
      if (taLists.size() > 0) {
	
	    out.println("<ul class='portletList-img'>");
	    String path = PlugInUtil.getUri("tel", "aspire-bb-learn", "");
	    //Collections.sort(taLists);
        for (TAList list : taLists) {

          out.println("<li>");
        
	      imageUrl = "<img align='absmiddle' src='" + path + "images/logo_s12.png' alt='Resource List Link'>";
	      out.println(imageUrl);
	  
	      String sectionText = ((list.getSectionItems() == 1) ? b2Context.getResourceString("block.language.section") : b2Context.getResourceString("block.language.sections"));
          String itemText = ((list.getListItems() == 1) ? b2Context.getResourceString("block.language.item") : b2Context.getResourceString("block.language.items"));                 
     
	      if (sectionMode.equals("true") && list.getSectionItems() > 0) {
	  
	        out.println("[" + list.getTargetCode() + "] <a href='" + list.getListURI(userLocale) + "' target='_blank'>" + list.getListName() + "</a> (" + list.getListItems() + " " + itemText + ")");
	    
	        listNo = "List" + String.valueOf(i);
	        itemNo = "Item" + String.valueOf(i);
	        i++;
	    
	        sections = Utils.sectionHTML(list.getSections());
	        sectionText.replaceFirst(sectionText.substring(0,1), sectionText.substring(0,1).toUpperCase());
	        title  = sectionText.replaceFirst(sectionText.substring(0,1), sectionText.substring(0,1).toUpperCase()) + " - " + list.getSectionItems();
            %>
            <bbNG:collapsibleList isDynamic="false" id="<%=listNo%>">
        	  <bbNG:collapsibleListItem id="<%=itemNo %>" title="<%=title %>" expandOnPageLoad="false"
        	                            body="<%=sections %>">
              </bbNG:collapsibleListItem>
            </bbNG:collapsibleList>
            <%
        
	      } else {
	        out.println("[" + list.getTargetCode() + "] <a href='" + list.getListURI(userLocale) + "' target='_blank'>" + list.getListName() + "</a> (" + list.getSectionItems() + " " + sectionText + ", " +  list.getListItems() + " " + itemText + ")");
	      }
	      out.println("</li>");
        }	
	    out.println("</ul>");
	    //out.println("<div class='noItems divider'></div>");
      }
    }
  
    String titleText = "";
    if (timeout) {
      out.println("<div class='noItems divider'>" + b2Context.getResourceString("learningpage.noserver") + "</div>");
      titleText = b2Context.getResourceString("block.language.single");
    } else if (total == 0) {
      if (courseId == null) { // not sure if this logic is right...
        out.println("<div class='noItems divider'>" + b2Context.getResourceString("learningpage.nolists") + "</div>");
      } else {
        
        CourseMembership.Role role = CourseMembership.Role.STUDENT;
        // try/catch block that deals with admins not being a member of the module (they default to student)
        try {
        	CourseMembership cm = CourseMembershipDbLoader.Default.getInstance().loadByCourseAndUserId(cList.get(0).getId(), user.getId());
        	role = cm.getRole();
        }catch (KeyNotFoundException kfne) {
        }
        if (role == CourseMembership.Role.INSTRUCTOR ||
            role == CourseMembership.Role.COURSE_BUILDER ||
            role == CourseMembership.Role.TEACHING_ASSISTANT) {
          out.println(Utils.textForStaff(cList.get(0), b2Context));  
        } else {
          String studentMessage = b2Context.getSetting("studentMessage");
          out.println("<div class='noItems divider'>" + String.format(studentMessage, cList.get(0).getTitle(),cList.get(0).getCourseId()) + "</div>");
        }
      }
      titleText = b2Context.getResourceString("block.language.single");
    } else {
      titleText = (total == 1) ? b2Context.getResourceString("block.language.single") : b2Context.getResourceString("block.language.plural"); 
    }
    %>
    <bbNG:jsBlock>
  	  <script type="text/javascript">
	    UpdateTitle("<%=titleText%>");
	  </script>
    </bbNG:jsBlock>
    <% 
  }
  if (helpUrl != null && !helpUrl.equals("")) {
	out.println("<div class='moduleControlWrapper u_reverseAlign'><a class='button-6' href=' " + helpUrl + "' target='_blank '>" + b2Context.getResourceString("module.help") + "</a></div>");
  }

  Long end = System.currentTimeMillis();
  String smode = sectionMode.equals("true") ? "t" : "f";
  if (portal) {
    for(Course cl : cList){
    	log.logInfo("View: Enrolled Course= " + cl.getCourseId() + " " + cl.getTitle());
    }
    for(Course ce : cExtras){
    	log.logInfo("View: Extra Course= " + ce.getCourseId() + " " + ce.getTitle());
    }
    log.logInfo(String.format("View: %6.3f",  (end - start)/1000.0) + "s (u: " + user.getUserName() + ", sm: " +  smode + ", c: " + cache + ")");
  } else {
    log.logInfo(String.format("Tool: %6.3f",  (end - start)/1000.0) + "s (u: " + user.getUserName() + ", sm: " +  smode + ", c: " +  cache + ")");     
  }
  %>

  </bbNG:includedPage>
  <!--  </bbData:context> -->