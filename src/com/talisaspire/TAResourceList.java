package com.talisaspire;

import java.util.*; 
import java.io.IOException;
import java.util.Iterator;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.ParseException;
import org.joda.time.format.ISODateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.oscelot.talis.Utils;

import blackboard.platform.log.Log;

import com.ocpsoft.pretty.time.PrettyTime;

public class TAResourceList  implements java.io.Serializable {

  private static final long serialVersionUID = -7230636066910523552L;
  
  String aspireBaseUrl = "";
  String targetKg = "";
  String regex = "";
  String regexrpl = "";
  String regextprpl = "";
  String regextp ="";
  String targetCode = "";
  String targetTimePeriod = "";
  String aspireLink = "";
  int code = 0;
  ArrayList<TAList> taLists = new ArrayList<TAList>();
  Log log = Utils.getLogger("talis");
  
  public TAResourceList(String aspireBaseUrl, String targetKg, String regex, String regexrpl, String regextp, String regextprpl, String courseIdSource, String timePeriodSource, String sectionMode, String debugMode) throws IOException, ParseException {
    this.aspireBaseUrl = aspireBaseUrl;
    this.targetKg = targetKg;
    this.regex = regex;
    this.regexrpl = regexrpl;
    this.regextp = regextp;
    this.regextprpl = regextprpl;
    this.taLists = new ArrayList<TAList>();
    
    if (regex != null && !regex.equals("")) {
      this.targetCode = courseIdSource.replaceAll(this.regex, this.regexrpl);
    } else {
      this.targetCode = courseIdSource;
    }
    if (regextp != null && !regex.equals("")) {
    	this.targetTimePeriod = timePeriodSource.replaceAll(this.regextp,this.regextprpl);
    } else {
    	this.targetTimePeriod = timePeriodSource;
    }
    
    this.aspireLink = aspireBaseUrl + "/" + targetKg.toLowerCase() + "/" + this.targetCode.toLowerCase() + "/lists";
    this.log.logInfo("TAResourceList: this.aspireLink " + this.aspireLink);
    JSONObject jsonRoot = Utils.getJSON(this.aspireLink);
    this.code = Utils.code;
    if  (this.code  >= 200 && this.code <  300 ) {
      
      JSONObject jsonModule = (JSONObject)jsonRoot.get(aspireBaseUrl + "/" + targetKg.toLowerCase() + "/" + this.targetCode.toLowerCase());
      JSONArray jsonLists  = (JSONArray)jsonModule.get("http://purl.org/vocab/resourcelist/schema#usesList");
      
      if (jsonLists == null) {
        return;
      }
      
      @SuppressWarnings("unchecked")
      Iterator<JSONObject> iter = jsonLists.iterator();
        
      while(iter.hasNext()) {
        TAList taList = new TAList();
        JSONObject jsonListEntry = iter.next();
        String listURI = (String)jsonListEntry.get("value");
        taList.setListURI(listURI);
        taList.setTargetCode(this.getTargetCode());
        JSONObject jsonList = (JSONObject)jsonRoot.get(listURI);
        
        // Deal with time periods
        try {
          String timePeriodListURI = (String)((JSONObject)((JSONArray)jsonList.get("http://lists.talis.com/schema/temp#hasTimePeriod")).get(0)).get("value");
          JSONObject jsonTimePeriodRoot = Utils.getJSON(timePeriodListURI);
          if (Utils.code == 404) {
            blackboard.platform.log.Log log = Utils.getLogger("talis");
            log.logDebug("No TP: " + timePeriodSource + " " + timePeriodListURI);
          }
          JSONObject jsonTimePeriodSlug = (JSONObject) jsonTimePeriodRoot.get(timePeriodListURI);
          String slug = (String)((JSONObject)((JSONArray)jsonTimePeriodSlug.get("http://lists.talis.com/schema/temp#slug")).get(0)).get("value");
          if (regextp != null && !regextp.equals("")) {
            if (!slug.equals(this.targetTimePeriod.toLowerCase())) continue;
          }
          
        } catch (NullPointerException npe) {};
        
        // List name
        taList.setListName("");
        try {
          String listName = (String)((JSONObject)((JSONArray)jsonList.get("http://rdfs.org/sioc/spec/name")).get(0)).get("value");
          taList.setListName(listName);
        } catch (NullPointerException npe) {};
        
        // Number of sections in list --- can be zero
        JSONArray containsArray = (JSONArray)jsonList.get("http://rdfs.org/sioc/spec/parent_of");
        // Ensure that if there are no sections we don't get into a mess
        taList.setSectionItems(0);
        if (containsArray != null) {
          taList.setSectionItems(containsArray.size());
        }
        
        // If section are wanted and sections are present, draw up the list
        if (sectionMode.equals("true") && taList.getSectionItems() > 0) {
          
          String[] sectionsSeq = new String[taList.getSectionItems()];
          int counter = 0;
          
          // Sort out size
          taList.initialiseSections(taList.getSectionItems());
          
          // Get the sequence of the sections --- this is worked out from looking at 
          // http://www.w3.org/1999/02/22-rdf-syntax-ns#_1,2,3 as the sections are listed
          // in the correct order amongst other items. 
          int loop = 1;
          try {
            while (true) {
              String  sectionURI = (String)((JSONObject)((JSONArray)jsonList.get("http://www.w3.org/1999/02/22-rdf-syntax-ns#_" + String.valueOf(loop))).get(0)).get("value");
              if(sectionURI.startsWith(aspireBaseUrl + "/sections/")) {
                sectionsSeq[counter] = sectionURI;
                counter++;
              }
            loop++;
            }
          } catch (NullPointerException npe) {};

          // Now read in the sections URIs
          for (int i = 0; i < containsArray.size(); i++) {
            String sectionURI = (String)((JSONObject)containsArray.get(i)).get("value");
            // Work out where the section appears in the sequence
            int position = 0;
            for (int j = 0; j < taList.getSectionItems(); j++) {
              if (sectionURI.equals(sectionsSeq[j])) {
                position = j;
                break;
              }
            }

            JSONObject jsonSectionRoot = Utils.getJSON(sectionURI);
            JSONObject jsonSectionName = (JSONObject) jsonSectionRoot.get(sectionURI);
            String name = (String)((JSONObject)((JSONArray)jsonSectionName.get("http://rdfs.org/sioc/spec/name")).get(0)).get("value");
            // Add the section name and URI in the appropriate place in the List
            taList.addSection(position, name, sectionURI);
          }
        }
        
        // Number of items in list
        int listItems = 0;
        containsArray = (JSONArray)jsonList.get("http://purl.org/vocab/resourcelist/schema#contains");
        
        taList.setListItems(0);
        if (containsArray != null) {
          for (int i = 0; i < containsArray.size(); i++) {
            String itemURI = (String)((JSONObject)containsArray.get(i)).get("value");
            if(itemURI.startsWith(aspireBaseUrl + "/items/"))
              listItems++;
          }
          taList.setListItems(listItems);
        }
        
        // List description
        String description = "";
        try {
          description = (String)((JSONObject)((JSONArray)jsonList.get("http://purl.org/vocab/resourcelist/schema#description")).get(0)).get("value");
        } catch (NullPointerException npe) {};
        taList.setDescription(description);
        
        // List last updated date
        String listLastUpdated = (String)((JSONObject)((JSONArray)jsonList.get("http://purl.org/vocab/resourcelist/schema#lastUpdated")).get(0)).get("value");
        String listUpdatedAgo = null;
        if (listLastUpdated != null) {
          DateTimeFormatter parser = ISODateTimeFormat.dateTimeNoMillis();            
          PrettyTime p = new PrettyTime();
          listUpdatedAgo = p.format(parser.parseDateTime(listLastUpdated).toDate());
          taList.setListLastUpdated(listUpdatedAgo);
        }

        taLists.add(taList);
      }
    }
  }
  
  public String getTargetCode() {
    return this.targetCode;
  }
  
  public String getTargetTimePeriod() {
	  return this.targetTimePeriod;
  }
  
  public String getAspireLink() {
    return this.aspireLink;
  }

  public int getCode() {
    return this.code;
  }
  
  public ArrayList<TAList> getLists() {
    return this.taLists;
  }
}
