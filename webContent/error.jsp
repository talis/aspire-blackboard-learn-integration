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
<%@page import="java.io.*,
                com.spvsoftwareproducts.blackboard.utils.B2Context"%>
<%@page isErrorPage="true"%>
<%@taglib uri="/bbNG" prefix="bbNG"%>

<%
  B2Context b2Context = new B2Context(request);
  pageContext.setAttribute("bundle", b2Context.getResourceStrings());
%>

<bbNG:learningSystemPage>
  <bbNG:pageHeader>
    <bbNG:pageTitleBar showTitleBar="true" title="${bundle['plugin.name']}: ${bundle['page.error.title']}"/>
  </bbNG:pageHeader>
  <bbNG:breadcrumbBar/>
  <h1>${bundle['page.error.introduction']}</h1>

  <%-- Exception Handler --%>
  <font color="red">
    <%= exception.toString() %><br>
  </font>
 
  <%
  out.println("<!--");

  StringWriter sw = new StringWriter();
  PrintWriter pw = new PrintWriter(sw);
  exception.printStackTrace(pw);
  out.print(sw);
  sw.close();
  pw.close();

  out.println("-->");
  %>
  
</bbNG:learningSystemPage>