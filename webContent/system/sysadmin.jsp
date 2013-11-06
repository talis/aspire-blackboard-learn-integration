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
<%@page import="blackboard.portal.external.*,
                blackboard.data.navigation.*,
                blackboard.persist.navigation.*,
                com.talisaspire.*,
                com.spvsoftwareproducts.blackboard.utils.*,
                java.util.*"
        errorPage="/error.jsp"%>
<%@taglib uri="/bbNG" prefix="bbNG"%>
<%@taglib uri="/bbData" prefix="bbData"%>

<%
  B2Context b2Context = new B2Context(request);
  pageContext.setAttribute("bundle", b2Context.getResourceStrings());
%>
  
<bbData:context>
  <bbNG:learningSystemPage title="${bundle['page.system.title']}">

  <bbNG:jsBlock>
    <script type="text/javascript">
      // Manage showing and hiding two data elements
      page.steps.hideShowAndRenumber(page.steps.HIDE, ["catlist"]);
      page.steps.hideShowAndRenumber(page.steps.HIDE, ["separate"]);
      
      // This determines whether targetted emails are being used
      av = document.getElementsByName("emailMode");
	  
      // if emails are being used show the elements
      if (av[0].checked == true) {
    	page.steps.hideShowAndRenumber(page.steps.SHOW, ["emailmsg"]);
		page.steps.hideShowAndRenumber(page.steps.SHOW, ["catlist"]);
		page.steps.hideShowAndRenumber(page.steps.SHOW, ["separate"]);
	  }      
      // Switch around
      $('email').observe('click', function(event) {
    	if (event.target.tagName === 'INPUT') {
    	  if (av[0].checked == true) {
    		page.steps.hideShowAndRenumber(page.steps.SHOW, ["emailmsg"]);
    	    page.steps.hideShowAndRenumber(page.steps.SHOW, ["catlist"]);
    	    page.steps.hideShowAndRenumber(page.steps.SHOW, ["separate"]);
    	  } else {
    		page.steps.hideShowAndRenumber(page.steps.HIDE, ["emailmsg"]);
    		page.steps.hideShowAndRenumber(page.steps.HIDE, ["catlist"]);  
    		page.steps.hideShowAndRenumber(page.steps.HIDE, ["separate"]);
    	  }
    	}
      });
    </script>
  </bbNG:jsBlock>
  <% 
  
  String BASE_URL = "aspireBaseUrl";
  String TARGET = "targetNodeType";
  String REGEX = "regexCourseId";
  String REGEXTP = "regexTimePeriod";
  String DEBUG = "debugMode";
  String STUDMSG = "studentMessage";
  String STAFFMSG = "staffMessage";
  String EMAIL = "emailMode";
  String EMAILMSG = "emailMsg";
  String SEPARATE = "separator";
  String RSS = "rss";
  String SECRET = "secret";
  String HELPURL = "helpurl";
  String STARTTIME = "starttime";
  String ENDTIME = "endtime";
  
  String MAINTENANCE = "maintenance";
  
  // Get array of the categories in Bb
  BbCourseCategories cc = new BbCourseCategories();
  ArrayList<String> courseCategories = cc.getCategories();
  
  // Create emails array to hold email addresses
  ArrayList<String> emails = new ArrayList<String>(courseCategories.size());
  
  // Use the context object with our data which will be in POST request
  String cancelUrl = b2Context.getNavigationItem("admin_plugin_manage").getHref();
  if (request.getMethod().equalsIgnoreCase("POST")) {
    String location = b2Context.getRequestParameter(BASE_URL, "").trim();
    b2Context.setSetting(BASE_URL, location);
    
    String targetKg = b2Context.getRequestParameter(TARGET, "Courses").trim();
    b2Context.setSetting(TARGET, targetKg);
    
    String regexCourseId = b2Context.getRequestParameter(REGEX, "").trim();
    b2Context.setSetting(REGEX, regexCourseId);

    String regexTimePeriod = b2Context.getRequestParameter(REGEXTP, "").trim();
    b2Context.setSetting(REGEXTP, regexTimePeriod);
    
    String staffMessage = b2Context.getRequestParameter(STAFFMSG, "").trim();
    b2Context.setSetting(STAFFMSG, staffMessage);
    
    String studentMessage = b2Context.getRequestParameter(STUDMSG, "").trim();
    b2Context.setSetting(STUDMSG, studentMessage);

    String emailMode = b2Context.getRequestParameter(EMAIL, "").trim();
    b2Context.setSetting(EMAIL, emailMode);
    
    String emailMsg = b2Context.getRequestParameter(EMAILMSG, "").trim();
    b2Context.setSetting(EMAILMSG, emailMsg);
    
    for (int i = 0; i< courseCategories.size(); i++) {
      emails.add(b2Context.getRequestParameter((String)courseCategories.get(i), "").trim());
      b2Context.setSetting((String) courseCategories.get(i), emails.get(i));
    }

    String separator = b2Context.getRequestParameter(SEPARATE, "").trim();
    b2Context.setSetting(SEPARATE, separator);
    
    String rss = b2Context.getRequestParameter(RSS, "").trim();
    b2Context.setSetting(RSS, rss);
    
    String secret = b2Context.getRequestParameter(SECRET, "").trim();
    b2Context.setSetting(SECRET, secret);

    String helpurl = b2Context.getRequestParameter(HELPURL, "").trim();
    b2Context.setSetting(HELPURL, helpurl);
    
    b2Context.setSetting(STARTTIME, null);
    b2Context.setSetting(ENDTIME, null);
    
    String debugMode = b2Context.getRequestParameter(DEBUG, "").trim();
    b2Context.setSetting(DEBUG, debugMode);
    
    b2Context.persistSettings();
    
    b2Context.setSetting(MAINTENANCE, "false");
    try {
      
      if (request.getParameter("maint_start_checkbox").equals("1") && request.getParameter("maint_end_checkbox").equals("1")) {
      
        b2Context.setSetting(STARTTIME, request.getParameter("maint_start_datetime"));
        b2Context.setSetting(ENDTIME, request.getParameter("maint_end_datetime"));
      
        Calendar now = Calendar.getInstance();
        Calendar start = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(b2Context.getSetting(STARTTIME));
        Calendar end = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(b2Context.getSetting(ENDTIME));
        if (now.after(end)) {
          response.sendRedirect(b2Context.setReceiptOptions(cancelUrl, "", b2Context.getResourceString("page.system.maint.endbeforenow")));
        }
        
        b2Context.setSetting(MAINTENANCE, "true");
        b2Context.persistSettings();
      }
    } catch (NullPointerException npe) {};
    
    response.sendRedirect(b2Context.setReceiptOptions(cancelUrl, b2Context.getResourceString("page.system.receipt.success"), ""));
    
  }
  String imageUrl = b2Context.getServerUrl() + b2Context.getPath() + "/images/logo.png";
  pageContext.setAttribute("imageUrl", imageUrl);
  pageContext.setAttribute("cancelUrl", cancelUrl);
  
  %>
  <bbNG:pageHeader instructions="${bundle['page.system.instructions']}">
     <bbNG:breadcrumbBar environment="SYS_ADMIN" navItem="admin_plugin_manage"> 
      <bbNG:breadcrumb href="${cancelUrl}" title="${bundle['plugin.name']}" />
      <bbNG:breadcrumb title="${bundle['page.system.title']}" />
    </bbNG:breadcrumbBar>
    <bbNG:pageTitleBar iconUrl="${imageUrl}" showTitleBar="true" title="${bundle['page.system.user.title']}"/>
  </bbNG:pageHeader>
  <form method="post" action="sysadmin.jsp">
    <bbNG:dataCollection markUnsavedChanges="true" showSubmitButtons="true">
	  <bbNG:step title="${bundle['page.system.step.url.title']}" id="url"
	             instructions="${bundle['page.system.step.url.instructions']}">
	  <bbNG:dataElement isRequired="true" label="${bundle['page.system.step.url.label']}">
	    <input type="text" size="100" name="<%=BASE_URL %>" value="<%=b2Context.getSetting(BASE_URL)%>" />
	  </bbNG:dataElement>
	  </bbNG:step>
	
	  <bbNG:step title="${bundle['page.system.step.node.title']}" id="node" 
	             instructions="${bundle['page.system.step.node.instructions']}">
	    <bbNG:dataElement isRequired="true" label="${bundle['page.system.step.node.label']}">
		<select name="<%=TARGET %>">
			<option value="courses"    <% if (b2Context.getSetting(TARGET).equals("courses"))    { out.print("selected=\"selected\"");} %>>Courses</option>
			<option value="modules"    <% if (b2Context.getSetting(TARGET).equals("modules"))    { out.print("selected=\"selected\"");} %>>Modules</option>
			<option value="units"      <% if (b2Context.getSetting(TARGET).equals("units"))      { out.print("selected=\"selected\"");} %>>Units</option>
			<option value="programmes" <% if (b2Context.getSetting(TARGET).equals("programmes")) { out.print("selected=\"selected\"");} %>>Programmes</option>
			<option value="subjects"   <% if (b2Context.getSetting(TARGET).equals("subjects"))   { out.print("selected=\"selected\"");} %>>Subjects</option>
		</select>
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.regex.title']}" id="regex" 
	             instructions="${bundle['page.system.step.regex.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.regex.label']}">
	      <input type="text" name="<%=REGEX %>" value="<%=b2Context.getSetting(REGEX)%>"/>
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.regextp.title']}" id="regextp" 
	             instructions="${bundle['page.system.step.regextp.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.regextp.label']}">
	      <input type="text" name="<%=REGEXTP %>" value="<%=b2Context.getSetting(REGEXTP)%>"/>
	    </bbNG:dataElement>
	  </bbNG:step>

	  <bbNG:step title="${bundle['page.system.step.staffmsg.title']}" id="staffmsg" 
	             instructions="${bundle['page.system.step.staffmsg.instructions']}">
	    <bbNG:dataElement isRequired="true" label="${bundle['page.system.step.staffmsg.label']}">
	      <input type="text" name="<%=STAFFMSG %>" value="<%=b2Context.getSetting(STAFFMSG)%>" size="50"/>
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.studmsg.title']}" id="studmsg" 
	             instructions="${bundle['page.system.step.studmsg.instructions']}">
	    <bbNG:dataElement isRequired="true" label="${bundle['page.system.step.studmsg.label']}">
	      <input type="text" name="<%=STUDMSG %>" value="<%=b2Context.getSetting(STUDMSG)%>" size="50" />
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.email.title']}" id="email"
	             instructions="${bundle['page.system.step.email.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.email.label']}">
	      <input id="email" type="checkbox" name="<%=EMAIL %>" value="true" <% if (b2Context.getSetting(EMAIL).equals("true")) { out.print("checked=\"checked\"");} %>/>
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.emailmsg.title']}" id="emailmsg" 
	             instructions="${bundle['page.system.step.emailmsg.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.emailmsg.label']}">
	      <input type="text" name="<%=EMAILMSG %>" value="<%=b2Context.getSetting(EMAILMSG)%>" size="50" />
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.catlist.title']}" id="catlist" 
	             instructions="${bundle['page.system.step.catlist.instructions']}">
<%      for (int i = 0; i < courseCategories.size(); i++) { %>
		  <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.catlist.label']}">
		    <%=courseCategories.get(i) %>&nbsp;&nbsp;<input type="text" name="<%=courseCategories.get(i)%>" value="<%=b2Context.getSetting((String)courseCategories.get(i))%>" size="50" />
          </bbNG:dataElement>
<%      } %>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.separate.title']}" id="separate"
	             instructions="${bundle['page.system.step.separate.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.separator.label']}">
	      <input id="separate" type="checkbox" name="<%=SEPARATE %>" value="true" <% if (b2Context.getSetting(SEPARATE).equals("true")) { out.print("checked=\"checked\"");} %>/>
	    </bbNG:dataElement>
	  </bbNG:step>

	  <bbNG:step title="${bundle['page.system.step.rss.title']}" id="rss"
	             instructions="${bundle['page.system.step.rss.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.rss.label']}">
	      <input id="rss" type="checkbox" name="<%=RSS %>" value="true" <% if (b2Context.getSetting(RSS).equals("true")) { out.print("checked=\"checked\"");} %>/>
	    </bbNG:dataElement>
	  </bbNG:step>

	  <bbNG:step title="${bundle['page.system.step.secret.title']}" id="secret" 
	             instructions="${bundle['page.system.step.secret.instructions']}">
	    <bbNG:dataElement label="${bundle['page.system.step.secret.label']}">
	      <input type="text" name="<%=SECRET %>" value="<%=b2Context.getSetting(SECRET)%>" size="50" />
	    </bbNG:dataElement>
	  </bbNG:step>

	  <bbNG:step title="${bundle['page.system.step.help.title']}" id="help"
	             instructions="${bundle['page.system.step.help.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.help.label']}">
	      <input type="text" name="<%=HELPURL %>" value="<%=b2Context.getSetting(HELPURL) %>" size="50"/>
	    </bbNG:dataElement>
	  </bbNG:step>
	  
	  <bbNG:step title="${bundle['page.system.step.maint.title']}" id="maint"
	             instructions="${bundle['page.system.step.maint.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.maint.label']}">
	      <bbNG:dateRangePicker baseFieldName="maint" showTime="true"
	                            showStartCheckbox="true"
	                            showEndCheckbox="true"
	                            startDateTime="<%=blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(b2Context.getSetting(STARTTIME)) %>"
	                            endDateTime="<%=blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(b2Context.getSetting(ENDTIME)) %>"
	                            endCaption="${bundle['page.system.step.maint.end']}"
	                            startCaption="${bundle['page.system.step.maint.start']}" /> 
	    </bbNG:dataElement>       
	  </bbNG:step>
	  	  	
	  <bbNG:step title="${bundle['page.system.step.debug.title']}" id="debug"
	             instructions="${bundle['page.system.step.debug.instructions']}">
	    <bbNG:dataElement isRequired="false" label="${bundle['page.system.step.debug.label']}">
	      <input id="debug" type="checkbox" name="<%=DEBUG %>" value="true" <% if (b2Context.getSetting(DEBUG).equals("true")) { out.print("checked=\"checked\"");} %>/>
	    </bbNG:dataElement>
	  </bbNG:step>
	
	  <bbNG:stepSubmit title="${bundle['page.system.step.submit']}" showCancelButton="true" cancelUrl="${cancelUrl}"/>
	  </bbNG:dataCollection>
	</form>
  </bbNG:learningSystemPage>
</bbData:context>