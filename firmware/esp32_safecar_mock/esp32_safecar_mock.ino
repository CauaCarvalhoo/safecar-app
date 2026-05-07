#include <WiFi.h>
#include <WebServer.h>

/*
  SafeCar - Firmware de protótipo para ESP32

  Como usar:
  1. Grave este arquivo no ESP32 pela Arduino IDE.
  2. No celular, conecte no Wi-Fi "SafeCar-ESP32" com a senha "safecar123".
  3. No app, desligue o "Modo simulação" e use o IP 192.168.4.1.

  Observação:
  Como vocês ainda não possuem sensores físicos, este firmware simula os estados.
  Quando os sensores chegarem, basta trocar as variáveis booleanas por leituras digitais/analógicas.
*/

const char* WIFI_NAME = "SafeCar-ESP32";
const char* WIFI_PASSWORD = "safecar123";

WebServer server(80);

bool doorsLocked = true;
bool headlightsOn = false;
bool windowsClosed = true;
bool alarmActive = true;
bool vibrationDetected = false;
bool movementDetected = false;
float batteryVoltage = 12.4;

String statusJson() {
  String json = "{";
  json += "\"connected\":true,";
  json += "\"doorsLocked\":" + String(doorsLocked ? "true" : "false") + ",";
  json += "\"headlightsOn\":" + String(headlightsOn ? "true" : "false") + ",";
  json += "\"windowsClosed\":" + String(windowsClosed ? "true" : "false") + ",";
  json += "\"alarmActive\":" + String(alarmActive ? "true" : "false") + ",";
  json += "\"vibrationDetected\":" + String(vibrationDetected ? "true" : "false") + ",";
  json += "\"movementDetected\":" + String(movementDetected ? "true" : "false") + ",";
  json += "\"batteryVoltage\":" + String(batteryVoltage, 1) + ",";
  json += "\"source\":\"ESP32 SafeCar\"";
  json += "}";
  return json;
}

void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

void handleRoot() {
  sendCorsHeaders();
  server.send(200, "text/html", "<h1>SafeCar ESP32</h1><p>Use /status para ver o JSON do veiculo.</p>");
}

void handleStatus() {
  sendCorsHeaders();
  server.send(200, "application/json", statusJson());
}

void handleCommand() {
  sendCorsHeaders();

  String command = server.arg("name");

  if (command == "lock_doors") {
    doorsLocked = true;
  } else if (command == "unlock_doors") {
    doorsLocked = false;
  } else if (command == "toggle_alarm") {
    alarmActive = !alarmActive;
  } else if (command == "turn_off_lights") {
    headlightsOn = false;
  } else if (command == "toggle_lights") {
    headlightsOn = !headlightsOn;
  } else if (command == "close_windows") {
    windowsClosed = true;
  } else if (command == "toggle_windows") {
    windowsClosed = !windowsClosed;
  } else if (command == "simulate_impact") {
    vibrationDetected = true;
    movementDetected = true;
  } else if (command == "clear_events") {
    vibrationDetected = false;
    movementDetected = false;
  }

  server.send(200, "application/json", statusJson());
}

void handleNotFound() {
  sendCorsHeaders();
  server.send(404, "application/json", "{\"error\":\"Rota nao encontrada\"}");
}

void setup() {
  Serial.begin(115200);

  WiFi.softAP(WIFI_NAME, WIFI_PASSWORD);
  Serial.println();
  Serial.println("SafeCar ESP32 iniciado.");
  Serial.print("Wi-Fi: ");
  Serial.println(WIFI_NAME);
  Serial.print("IP: ");
  Serial.println(WiFi.softAPIP());

  server.on("/", handleRoot);
  server.on("/status", handleStatus);
  server.on("/command", handleCommand);
  server.onNotFound(handleNotFound);
  server.begin();
}

void loop() {
  server.handleClient();
}
