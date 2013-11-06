package org.oscelot.talis;

import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class MD5 {

  String message = "";
  
  public MD5 (String message) {
    this.message = message;
  }
  
  public String getMD5() {
    byte[] bytesOfMessage;
    StringBuffer sb = new StringBuffer();
    
    try {
      bytesOfMessage = this.message.getBytes("UTF-8");
      MessageDigest md = MessageDigest.getInstance("MD5");
      byte[] thedigest = md.digest(bytesOfMessage);
          for (int i = 0; i < thedigest.length; ++i) {
            sb.append(Integer.toHexString((thedigest[i] & 0xFF) | 0x100).substring(1,3));
          }
    } catch (UnsupportedEncodingException e) {
      //e.printStackTrace();
    } catch (NoSuchAlgorithmException nsae) {
      //e.printStackTrace();      
    }
    
    return sb.toString();
  }
}