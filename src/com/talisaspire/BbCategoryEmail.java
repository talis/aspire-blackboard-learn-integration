package com.talisaspire;

import java.util.List;
import java.util.HashSet;
import blackboard.admin.data.category.CourseCategory;
import blackboard.admin.data.category.CourseCategoryMembership;
import blackboard.admin.persist.category.CourseCategoryLoader;
import blackboard.admin.persist.category.CourseCategoryMembershipLoader;
import blackboard.data.course.Course;
import blackboard.persist.KeyNotFoundException;
import blackboard.persist.PersistenceException;
import com.spvsoftwareproducts.blackboard.utils.*;

public class BbCategoryEmail {

  HashSet<String> emailaddresses = new HashSet<String>();
  public BbCategoryEmail(Course course, B2Context b2Context) throws KeyNotFoundException, PersistenceException {
    
    // Course Category
    CourseCategoryMembership srchTemplate = new CourseCategoryMembership();
    srchTemplate.setCourseSiteId(course.getId());
    
    List<CourseCategoryMembership> ccMemberships = CourseCategoryMembershipLoader.Default.getInstance().load(srchTemplate);

    for (CourseCategoryMembership ccm : ccMemberships) {
        CourseCategory cc = CourseCategoryLoader.Default.getInstance().load(ccm.getCategoryBatchUid());
        emailaddresses.add(b2Context.getSetting(cc.getTitle()));
    }
  }
  
  public String getEmails(String separator) {
    StringBuffer addresses = new StringBuffer();
    String separate = separator.equals("true") ? ";" : ",";
    for (String email : emailaddresses) {
      addresses.append(email + separate);
    }
    
    // If nothing has been appended return the empty string
    if (addresses.length() == 0) {
      return "";
    } else {
      return addresses.toString().substring(0, addresses.length()-1);
    }
  }
}
