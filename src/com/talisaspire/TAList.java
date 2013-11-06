package com.talisaspire;

import java.util.ArrayList;
import java.util.List;

public class TAList implements java.io.Serializable {
  /**
   * 
   */
  private static final long serialVersionUID = 3050671067468459534L;
  String listURI = "";
  String listName = "";
  int sectionItems = 0;
  int listItems = 0;
  String listLastUpdated = "";
  String description = "";
  List<Section> sections = new ArrayList<Section>();
  
  public TAList() {
  }
  
  public void setListURI(String listURI) {
    this.listURI = listURI;
  }
  
  public String getListURI() {
    return this.listURI;
  }
  
  public void setListName(String listName) {
    this.listName = listName;
  }
  
  public String getListName() {
    return this.listName;
  }
  
  public void setListLastUpdated(String listLastUpdated) {
    this.listLastUpdated = listLastUpdated;
  }
  
  public String getListLastUpdated() {
    return this.listLastUpdated;
  }

  public void setSectionItems(int sectionItems) {
    this.sectionItems = sectionItems;
  }
  
  public int getSectionItems() {
    return this.sectionItems;
  }
  
  public void setListItems(int listItems) {
    this.listItems = listItems;
  }
  
  public int getListItems() {
    return this.listItems;
  }
  
  public void setDescription(String description) {
    this.description = description;
  }
  
  public String getDescription() {
    return this.description; 
  }
  
  public void initialiseSections(int size) {
    for (int i = 0; i < size; i++) {
      sections.add(null);
    }
  }
  public void addSection(int position, String name, String URI) {
    sections.set(position, new Section(name, URI));
  }
  
  public List<Section> getSections() {
    return this.sections;
  }
}
