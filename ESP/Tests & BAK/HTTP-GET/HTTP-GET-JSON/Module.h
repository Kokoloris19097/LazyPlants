#include "Arduino.h"
#include <Arduino.h>
#include <vector>
#include <WiFi.h>
#include <Arduino_JSON.h>
#include <HTTPClient.h>


bool connect(const char* ssid,const char* password){
    WiFi.begin(ssid, password);
    delay(500);
    Serial.println();
    Serial.print("Connecting to WiFi..");
    bool Stop = false;
    int counter =0;

    while ((WiFi.status() != WL_CONNECTED) && !(Stop)) {
      counter ++;
      delay(1000);
      Serial.print(".");
      if (counter == 8){
        Serial.println();
        WiFi.begin(ssid, password);
        delay(500);
      }
      if (counter >= 20){
        Stop = true;
        Serial.println();
        Serial.println("No Connection!!!");
        Serial.println("scan start");
        // WiFi.scanNetworks will return the number of networks found
        int n = WiFi.scanNetworks();
        Serial.println("scan done");
        if (n == 0) {
            Serial.println("no networks found");
        } else {
            Serial.print(n);
            Serial.println(" networks found: ");
            for (int i = 0; i < n; ++i) {
                // Print SSID and RSSI for each network found
                Serial.print(i + 1);
                Serial.print(": ");
                Serial.print(WiFi.SSID(i));
                Serial.print(" (");
                Serial.print(WiFi.RSSI(i));
                Serial.print(")");
                Serial.println((WiFi.encryptionType(i) == WIFI_AUTH_OPEN)?" ":"*");
                delay(10);
            }
        }
        //ESP.restart();
        return false;
      }
    }
    if (counter < 30){
      Serial.println();
      Serial.println("Connected to the WiFi network");
      Serial.println();
      return true;
    }
    

}

String converte_AtoJ(String Message[][2], int length_Message){
  //msg zusammenbauen im JSON Format ("{\"UserID\":\"1\",\"PlantID\":\"1\",\"water\":\"false\"\"}")
  String msg = "{";
  for (int i=0;i < length_Message; i++){
    msg = msg + "\"" + Message[i][0] + "\":\"" + Message[i][1] +"\",";
  }
  msg.remove(msg.length()-1); //löschen des letzten ',' da kein weiterer Parameter kommt
  msg = msg + "}";
  return msg;
}

int patch(String ServerPath, String Message){
    // http://178.238.227.46:3000/api/plants_data?access_token=Fm8ctl15LypUYt6ICN6kA3M2BlVrwF9KCMijBPSfqAGtHMv220PAZSHvisDZxBq6 //POST
    // HTTP header
    // TEST
    HTTPClient http;
    //http.begin(ServerPath + "&filter[where][UserID]=1&filter[where][PlantID]=1");
    http.begin(ServerPath);
    http.addHeader("Content-Type", "application/json"); //Typ des Body auf json Format festlegen
    //int httpResponseCode = http.PATCH("{\"UserID\":\"1\",\"PlantID\":\"1\",\"water\":\"false\"}");
    int httpResponseCode = http.PATCH(Message);
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);    
    
    http.end();
    return httpResponseCode;
  }

int post(String ServerPath, String Message){
    HTTPClient http;
    http.begin(ServerPath);
    http.addHeader("Content-Type", "application/json"); //Typ des Body auf json Format festlegen

    int httpResponseCode = http.POST(Message);

    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);    
    
    http.end();
    return httpResponseCode;
  }
