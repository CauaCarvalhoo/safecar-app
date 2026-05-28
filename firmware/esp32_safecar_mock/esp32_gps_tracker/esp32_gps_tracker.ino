#include <WiFi.h>
#include <WebServer.h>
#include <TinyGPS++.h>

/*
  SafeCar Fleet - ESP32 GPS Tracker

  Hardware:
    ESP32 + NEO-6M

  Ligação:
    NEO-6M VCC -> ESP32 3V3
    NEO-6M GND -> ESP32 GND
    NEO-6M TX  -> ESP32 GPIO 16
    NEO-6M RX  -> ESP32 GPIO 17

  Wi-Fi:
    SSID: SafeCar-ESP32
    Senha: safecar123
    IP: 192.168.4.1

  Endpoints:
    GET /
    GET /gps/status
    GET /status
    GET /health
*/

const char* WIFI_SSID = "SafeCar-ESP32";
const char* WIFI_PASSWORD = "safecar123";

const char* FIRMWARE_VERSION = "SafeCar Fleet GPS v1.0.0";

IPAddress localIp(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

WebServer server(80);
TinyGPSPlus gps;
HardwareSerial gpsSerial(2);

const int GPS_RX_PIN = 16;
const int GPS_TX_PIN = 17;
const int GPS_BAUD = 9600;

unsigned long lastDebugAt = 0;

void addCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

String boolToJson(bool value) {
  return value ? "true" : "false";
}

bool gpsIsValid() {
  return gps.location.isValid() && gps.location.age() < 10000;
}

String gpsJson() {
  bool valid = gpsIsValid();

  double latitude = valid ? gps.location.lat() : 0.0;
  double longitude = valid ? gps.location.lng() : 0.0;
  double speedKmh = gps.speed.isValid() ? gps.speed.kmph() : 0.0;
  double altitude = gps.altitude.isValid() ? gps.altitude.meters() : 0.0;
  double course = gps.course.isValid() ? gps.course.deg() : 0.0;
  double hdop = gps.hdop.isValid() ? gps.hdop.hdop() : 99.99;
  int satellites = gps.satellites.isValid() ? gps.satellites.value() : 0;

  String json = "{";

  json += "\"connected\":true,";
  json += "\"gpsValid\":" + boolToJson(valid) + ",";
  json += "\"latitude\":" + String(latitude, 6) + ",";
  json += "\"longitude\":" + String(longitude, 6) + ",";
  json += "\"gpsSpeedKmh\":" + String(speedKmh, 2) + ",";
  json += "\"satellites\":" + String(satellites) + ",";
  json += "\"altitudeMeters\":" + String(altitude, 1) + ",";
  json += "\"courseDegrees\":" + String(course, 1) + ",";
  json += "\"hdop\":" + String(hdop, 2) + ",";
  json += "\"source\":\"ESP32 + NEO-6M\",";
  json += "\"firmwareVersion\":\"" + String(FIRMWARE_VERSION) + "\",";
  json += "\"ip\":\"192.168.4.1\",";
  json += "\"uptimeMs\":" + String(millis()) + ",";
  json += "\"charsProcessed\":" + String(gps.charsProcessed()) + ",";
  json += "\"failedChecksum\":" + String(gps.failedChecksum());

  json += "}";

  return json;
}

void sendJson(String json) {
  addCorsHeaders();
  server.send(200, "application/json", json);
}

void handleGpsStatus() {
  sendJson(gpsJson());

  Serial.println("[GET] /gps/status");
  Serial.println(gpsJson());
}

void handleHealth() {
  String json = "{";
  json += "\"ok\":true,";
  json += "\"device\":\"ESP32\",";
  json += "\"project\":\"SafeCar Fleet\",";
  json += "\"firmwareVersion\":\"" + String(FIRMWARE_VERSION) + "\",";
  json += "\"gpsCharsProcessed\":" + String(gps.charsProcessed()) + ",";
  json += "\"uptimeMs\":" + String(millis());
  json += "}";

  sendJson(json);
}

String htmlPage() {
  String html = "";

  html += "<!DOCTYPE html>";
  html += "<html lang='pt-BR'>";
  html += "<head>";
  html += "<meta charset='UTF-8'>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
  html += "<title>SafeCar GPS</title>";
  html += "<style>";
  html += "body{font-family:Arial,sans-serif;background:#F0FAFF;margin:0;padding:20px;color:#244B44;}";
  html += ".card{background:white;border-radius:20px;padding:18px;margin-bottom:16px;box-shadow:0 4px 12px rgba(0,0,0,.08);}";
  html += "h1{color:#3A6A60;text-align:center;}";
  html += "button{width:100%;padding:14px;margin:6px 0;border:0;border-radius:20px;background:#3A6A60;color:white;font-weight:bold;font-size:15px;}";
  html += "pre{background:#1f2937;color:#e5e7eb;padding:14px;border-radius:14px;overflow:auto;}";
  html += "</style>";
  html += "</head>";
  html += "<body>";

  html += "<h1>SafeCar GPS</h1>";

  html += "<div class='card'>";
  html += "<p><strong>Firmware:</strong> " + String(FIRMWARE_VERSION) + "</p>";
  html += "<p><strong>IP:</strong> 192.168.4.1</p>";
  html += "<p><strong>GPS:</strong> NEO-6M via UART</p>";
  html += "</div>";

  html += "<div class='card'>";
  html += "<h2>Status GPS</h2>";
  html += "<button onclick='refresh()'>Atualizar</button>";
  html += "<pre id='json'>Carregando...</pre>";
  html += "</div>";

  html += "<script>";
  html += "async function refresh(){";
  html += "const r=await fetch('/gps/status');";
  html += "const j=await r.json();";
  html += "document.getElementById('json').textContent=JSON.stringify(j,null,2);";
  html += "}";
  html += "refresh();";
  html += "setInterval(refresh,3000);";
  html += "</script>";

  html += "</body>";
  html += "</html>";

  return html;
}

void handleRoot() {
  addCorsHeaders();
  server.send(200, "text/html", htmlPage());
}

void handleOptions() {
  addCorsHeaders();
  server.send(204);
}

void handleNotFound() {
  addCorsHeaders();

  if (server.method() == HTTP_OPTIONS) {
    handleOptions();
    return;
  }

  String json = "{";
  json += "\"success\":false,";
  json += "\"message\":\"Rota nao encontrada\",";
  json += "\"uri\":\"" + server.uri() + "\"";
  json += "}";

  server.send(404, "application/json", json);
}

void setupRoutes() {
  server.on("/", HTTP_GET, handleRoot);
  server.on("/gps/status", HTTP_GET, handleGpsStatus);
  server.on("/status", HTTP_GET, handleGpsStatus);
  server.on("/health", HTTP_GET, handleHealth);

  server.onNotFound(handleNotFound);
}

void setupWiFiAccessPoint() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(localIp, gateway, subnet);

  bool started = WiFi.softAP(WIFI_SSID, WIFI_PASSWORD);

  Serial.println();
  Serial.println("==================================");
  Serial.println(" SafeCar Fleet GPS iniciado");
  Serial.println("==================================");

  if (started) {
    Serial.println("Rede Wi-Fi criada com sucesso!");
  } else {
    Serial.println("Falha ao criar rede Wi-Fi.");
  }

  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  Serial.print("Senha: ");
  Serial.println(WIFI_PASSWORD);

  Serial.print("IP: ");
  Serial.println(WiFi.softAPIP());

  Serial.println("----------------------------------");
  Serial.println("Acesse:");
  Serial.println("http://192.168.4.1");
  Serial.println("http://192.168.4.1/gps/status");
  Serial.println("==================================");
  Serial.println();
}

void readGpsSerial() {
  while (gpsSerial.available() > 0) {
    char c = gpsSerial.read();
    gps.encode(c);
  }
}

void printGpsDebug() {
  if (millis() - lastDebugAt < 3000) {
    return;
  }

  lastDebugAt = millis();

  Serial.println("------ GPS DEBUG ------");
  Serial.print("Chars processados: ");
  Serial.println(gps.charsProcessed());

  Serial.print("Checksum com falha: ");
  Serial.println(gps.failedChecksum());

  Serial.print("GPS valido: ");
  Serial.println(gpsIsValid() ? "SIM" : "NAO");

  Serial.print("Satelites: ");
  Serial.println(gps.satellites.isValid() ? gps.satellites.value() : 0);

  Serial.print("Latitude: ");
  Serial.println(gpsIsValid() ? String(gps.location.lat(), 6) : "Aguardando fix...");

  Serial.print("Longitude: ");
  Serial.println(gpsIsValid() ? String(gps.location.lng(), 6) : "Aguardando fix...");

  Serial.print("Velocidade km/h: ");
  Serial.println(gps.speed.isValid() ? String(gps.speed.kmph(), 2) : "Sem dados");

  Serial.println("-----------------------");
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  setupWiFiAccessPoint();
  setupRoutes();

  server.begin();

  Serial.println("Servidor HTTP iniciado.");
  Serial.println("Aguardando dados do GPS...");
}

void loop() {
  readGpsSerial();
  server.handleClient();
  printGpsDebug();
}