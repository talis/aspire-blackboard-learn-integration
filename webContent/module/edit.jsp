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
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">
<%@page import="com.spvsoftwareproducts.blackboard.utils.B2Context,
                blackboard.data.course.Course,
                blackboard.platform.session.*,
                blackboard.persist.course.CourseDbLoader,
                java.util.*"
   errorPage="../error.jsp"%>
<%@taglib uri="/bbNG" prefix="bbNG" %>
<%@ taglib uri="/bbData" prefix="bbData"%>

<bbData:context id="ctx">
<bbNG:genericPage title="${bundle['page.system.title']}">

<%
  String LOCATION_FIELD_NAME = "talis";
  String SECTION_FIELD_NAME = "sectionMode";
  String cancelUrl = "";
  
  B2Context b2Context = new B2Context(request);
  b2Context.setSaveEmptyValues(false);
  
  // Work out whether this settings page has been invoked from with a
  // course or a tab
  String recallUrl = request.getParameter("recallUrl");
  if (recallUrl != null) {
    // We have been called from a tab
    cancelUrl = recallUrl;
  } else {
    // In the course tools area
    cancelUrl = b2Context.getNavigationItem("course_tools_area").getHref();
  }

  if (request.getMethod().equalsIgnoreCase("POST")) {
    String initialSetting = b2Context.getSetting(true, false, SECTION_FIELD_NAME, "false");
    String sectionMode = b2Context.getRequestParameter(SECTION_FIELD_NAME, "").trim();
    b2Context.setSetting(true, false, SECTION_FIELD_NAME, sectionMode);

    b2Context.persistSettings(true, false);
    
    // Is sectionMode being switched on --- need to go back to Talis. Clear the cached data and this will happen.
    if (initialSetting.equals("false") && sectionMode.equals("true")) {
      // Get all courses
      List<Course> cList = (List<Course>) CourseDbLoader.Default.getInstance().loadByUserId(ctx.getUserId());
      
      // Get the BbSession
      BbSessionManagerService sessionService = BbSessionManagerServiceFactory.getInstance();
      BbSession bbSession = sessionService.getSession(request); 

      // Clear session keys
      for (Course c : cList) {
        bbSession.removeGlobalKey(c.getBatchUid());
      }
    }

    response.sendRedirect(b2Context.setReceiptOptions(cancelUrl, b2Context.getResourceString("receipt.success"), ""));
  }
  
  if (b2Context.getSetting(true, false, SECTION_FIELD_NAME).length() <= 0) {
    b2Context.setSetting(true, false, SECTION_FIELD_NAME, "false");
  }

  pageContext.setAttribute("bundle", b2Context.getResourceStrings());
  pageContext.setAttribute("cancelUrl", cancelUrl);
  String imageUrl = b2Context.getServerUrl() + b2Context.getPath() + "/images/logo.png";
  pageContext.setAttribute("imageUrl", imageUrl);
%>
  <bbNG:pageHeader instructions="${bundle['page.system.user.instructions']}">
    <bbNG:breadcrumbBar environment= "COURSE" navItem = "course_tools_area">
      <bbNG:breadcrumb href= "${cancelUrl} " title = "${bundle['plugin.name']} " />
      <bbNG:breadcrumb title= "${bundle['page.system.user.title']} " />
    </bbNG:breadcrumbBar >
    <bbNG:pageTitleBar iconUrl="${imageUrl}" showTitleBar="true" title="${bundle['page.system.user.title']}"/>
  </bbNG:pageHeader>

  <bbNG:form action="" id="id_userForm" name="userForm" method="post" onsubmit="return validateForm();">
  <bbNG:dataCollection markUnsavedChanges="true" showSubmitButtons="true">
    <bbNG:step hideNumber="false" id="stepOne" title="${bundle['page.system.user.step1.title']}" instructions="${bundle['page.system.user.step1.instructions']}">
      <bbNG:dataElement isRequired="false" label="${bundle['page.system.user.step1.home.label']}">
        <input id="email" type="checkbox" name="<%=SECTION_FIELD_NAME%>" value="true" <% if (b2Context.getSetting(true, false, SECTION_FIELD_NAME).equals("true")) { out.print("checked=\"checked\"");} %>/>
      </bbNG:dataElement>
    </bbNG:step>
    <bbNG:stepSubmit hideNumber="false" showCancelButton="true" cancelUrl="${cancelUrl}" />
  </bbNG:dataCollection>
  </bbNG:form>
</bbNG:genericPage>
</bbData:context>
