package com.talisaspire;

import java.util.*;
import blackboard.admin.data.datasource.*;
import blackboard.admin.persist.datasource.*;
import blackboard.admin.data.category.*;
import blackboard.persist.PersistenceException;

public class BbCourseCategories {
  ArrayList<String> categories = new ArrayList<String>();
  int i = 0;
  
  public BbCourseCategories() throws PersistenceException {
    List<DataSource> dskList = DataSourceLoader.Default.getInstance().loadAll();
    ListIterator<DataSource> litr = dskList.listIterator();
    while(litr.hasNext()) {
      DataSource element = litr.next();
      
      blackboard.admin.data.category.CourseCategory srchTemplate = new blackboard.admin.data.category.CourseCategory();
      srchTemplate.setDataSourceId(element.getDataSourceId());
           
      List<CourseCategory> cc = blackboard.admin.persist.category.CourseCategoryLoader.Default.getInstance().load(srchTemplate);
      ListIterator<CourseCategory> ccIter = cc.listIterator();
      while (ccIter.hasNext()) {
        CourseCategory ccm = ccIter.next();
        categories.add(ccm.getTitle());
        i++;
      }
    }
  }
  
  public ArrayList<String> getCategories() {
    return categories;
  }
}
