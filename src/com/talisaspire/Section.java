package com.talisaspire;

public class Section implements java.io.Serializable {

  private static final long serialVersionUID = 3844131843102642482L;
  public String name = "";
  public String URI = "";
  
  public Section(String name, String URI) {
    this.name = name;
    this.URI = URI;
  }
}
