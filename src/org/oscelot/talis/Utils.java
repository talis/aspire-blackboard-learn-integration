package org.oscelot.talis;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.ByteArrayOutputStream;
import java.io.ObjectOutputStream;
import java.io.ObjectInputStream;

import org.apache.commons.codec.binary.Base64;

import java.net.HttpURLConnection;
import javax.net.ssl.HttpsURLConnection;
import java.net.MalformedURLException;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;

import com.spvsoftwareproducts.blackboard.utils.B2Context;
import com.talisaspire.BbCategoryEmail;
import com.talisaspire.Section;
import com.talisaspire.TAResourceList;

import blackboard.data.course.Course;
import blackboard.persist.KeyNotFoundException;
import blackboard.persist.PersistenceException;
import blackboard.platform.BbServiceException;
import blackboard.platform.session.BbSession;

import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import blackboard.platform.log.Log;
import blackboard.platform.log.LogService;
import blackboard.platform.log.LogServiceFactory;

public class Utils {
  public static int code;
  public final static int SOCKETTIMEOUT = -1;

  public static String sectionHTML (List<Section> sections) {

    String sectionHTML = "";
    if (sections.size() == 0) return sectionHTML;

    for (int i = 0; i < sections.size(); i++) {
      sectionHTML += "<a href='" + sections.get(i).URI + "' target = '_blank'>" + sections.get(i).name + "</a><br />";
    }

    sectionHTML = sectionHTML.substring(0, sectionHTML.length() - 6);

    return sectionHTML;
  }

  public static JSONObject getJSON (String URI) {

    Log log = Utils.getLogger("talis");
    String baseLogMessage = "Utils.getJson: ";
    HttpURLConnection huc = null; 
    try {
      JSONObject jsonRoot = null;
      URL u = new URL(URI + ".json");
      log.logInfo("Getting JSON from: " + u.toString());
      huc = (HttpURLConnection) u.openConnection();
      huc.setRequestMethod ("GET");
      huc.setConnectTimeout(10000); //set timeout to 10 seconds
      huc.connect();
      Utils.code = huc.getResponseCode();
      log.logDebug(baseLogMessage + "Response Code: " + Utils.code);

      if(Utils.code == HttpURLConnection.HTTP_MOVED_PERM
          || Utils.code == HttpURLConnection.HTTP_MOVED_TEMP
          || Utils.code == HttpURLConnection.HTTP_SEE_OTHER){

        // get redirect url from "location" header field
        String newUrl = huc.getHeaderField("Location");
        log.logDebug(baseLogMessage + "Redirecting to: " + newUrl.toString());

        // get the cookie if need, for login
        String cookies = huc.getHeaderField("Set-Cookie");

        // close the first connection
        huc.disconnect();

        // open the new connection (which will be HTTPS)
        huc = (HttpsURLConnection) new URL(newUrl).openConnection();
        huc.setConnectTimeout(10000); //set timeout to 10 seconds
        huc.setRequestProperty("Cookie", cookies);

        huc.connect();
        Utils.code = huc.getResponseCode();
        log.logDebug(baseLogMessage + "Response Code: " + Utils.code);
      }

      if (Utils.code == HttpURLConnection.HTTP_OK) {
        InputStreamReader in = new InputStreamReader((InputStream) huc.getContent());
        jsonRoot = (JSONObject)new JSONParser().parse(in);
        log.logDebug(baseLogMessage + "Response json: " + jsonRoot.toJSONString());
      } else {
        if (huc instanceof HttpsURLConnection) {
          HttpsURLConnection secured = (HttpsURLConnection) huc;
          String cipher = secured.getCipherSuite();
          log.logDebug(baseLogMessage + "cipher: "  + cipher);
        }
      }

      huc.disconnect();
      return jsonRoot;
    }
    catch (SocketTimeoutException ste) {
      Utils.code = Utils.SOCKETTIMEOUT;
      log.logError(baseLogMessage + "Got a timeout", ste);
    }
    catch (MalformedURLException mu) {
        log.logError(baseLogMessage + "malformed Url", mu);
    }
    catch (IOException ioe) {
        log.logError(baseLogMessage + "IO Exception", ioe);
    }
    catch (ParseException pe) {
        log.logError(baseLogMessage + "ParseException", pe);
    }
    finally {
        if (huc != null) {
            try {
                huc.disconnect();
            }
            catch (Exception e) {
                log.logError(baseLogMessage + "Tried to "
                    + "tidy up the http connection", e);
            }
        }
    }

    return null;
  }

  public static String textForStaff (Course c, B2Context b2Context) {

    String staffMessage = b2Context.getSetting("staffMessage");
    String message = "<div class='noItems divider'>" + String.format(staffMessage, c.getTitle(), c.getCourseId()) + "</div>";
    // Check if email link(s) are wanted
    if (b2Context.getSetting("emailMode").equals("true")) {
      // Check if we some email addresses to use
      BbCategoryEmail bbcg;
      try {
        bbcg = new BbCategoryEmail(c, b2Context);

        String email = bbcg.getEmails(b2Context.getSetting("separator"));
        if (!email.equals("")) {
          String rawEmailMessage = b2Context.getSetting("emailMsg");
          if (!rawEmailMessage.equals("")) {
            String[] emailText = rawEmailMessage.split("_");
            message += "<div class='noItems divider'>" + emailText[0] + "<a href='mailto:" + email + "'>" + emailText[1] + "</a>" + emailText[2] + "</div>";
          }
        }
      }
      catch (KeyNotFoundException e) {}
      catch (PersistenceException e) {}
    }
    return message;
  }

  public static boolean maintenancePeriodNow (String startTime, String endTime) {
    boolean maintenance = false;
    Calendar start = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(startTime);
    Calendar end = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(endTime);
    Calendar now = Calendar.getInstance();

    try {
      if (now.after(start) && now.before(end)) maintenance = true;
    } catch (NullPointerException npe) {};

    return maintenance;
  }

  public static boolean maintenancePeriodFuture(String startTime) {
    boolean inFuture = false;
    Calendar start = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(startTime);
    Calendar now = Calendar.getInstance();

    try {
      if (start.after(now)) inFuture = true;
    } catch (NullPointerException npe) {};

    return inFuture;
  }

  public static String endTimeHHMM (String endTime) {
    String endTimeFormatted = "";
    Calendar end = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(endTime);

    SimpleDateFormat formatter = new SimpleDateFormat("HH:mm");
    endTimeFormatted = formatter.format(end.getTime());

    return endTimeFormatted;
  }

  public static String endTimeDMYHHMM (String endTime) {
    String endTimeFormatted = "";
    Calendar end = blackboard.servlet.util.DatePickerUtil.pickerDatetimeStrToCal(endTime);

    SimpleDateFormat formatter = new SimpleDateFormat("dd-MMM-yyyy:HH:mm");
    endTimeFormatted = formatter.format(end.getTime());

    return endTimeFormatted;
  }

  public static void setSessionKey(TAResourceList rl, String name, BbSession bbSession) {
    try {
      ByteArrayOutputStream baos = new ByteArrayOutputStream();
      ObjectOutputStream oos;
      oos = new ObjectOutputStream(baos);

      oos.writeObject(rl);
      oos.close();
      String resourceList = Base64.encodeBase64String(baos.toByteArray());
      bbSession.setGlobalKey(name, resourceList);
    } catch (IOException e) {}
      catch (PersistenceException pe) {}
  }

  public static TAResourceList getObjectFromString (String resourceList) {
    try {
      byte [] data = Base64.decodeBase64(resourceList);
      ObjectInputStream ois = new java.io.ObjectInputStream(new java.io.ByteArrayInputStream(data));
      Object o  = ois.readObject();
      ois.close();

      TAResourceList rl = (TAResourceList) o;

      return rl;
    } catch (IOException e) {}
      catch (ClassNotFoundException cnf) {}

    return null;
  }

  public static Log getLogger(String name) {
    // Set up log
    LogService logService = LogServiceFactory.getInstance();
    Log log = logService.getConfiguredLog(name);

    if (log == null) {
      try {
        logService = LogServiceFactory.getInstance();
        logService.defineNewFileLog(name, "logs" + java.io.File.separator + name + ".log", LogService.Verbosity.INFORMATION, false);
        log = logService.getConfiguredLog(name);
        log.logInfo("Talis ASPIRE Logging");
      } catch (BbServiceException e) {
        log = null;
      }
    } else {
      log.setVerbosityLevel(LogService.Verbosity.INFORMATION);
    }

    return log;
  }
}
