#include <WiFi.h>
#include <WebServer.h>

/*
  SafeCar - Firmware de protótipo para ESP32

  Este firmware cria uma rede Wi-Fi local e disponibiliza endpoints HTTP
  para o aplicativo SafeCar consultar e alterar o estado simulado do veículo.

  Rede:
    SSID: SafeCar-ESP32
    Senha: safecar123
    IP: 192.168.4.1

  Endpoints:
    GET  /status
    GET  /health
    GET  /
    GET  /command?cmd=nome_do_comando
    POST /command?cmd=nome_do_comando
    GET  /reset
*/

const char* WIFI_SSID = "SafeCar-ESP32";
const char* WIFI_PASSWORD = "safecar123";

const char* FIRMWARE_VERSION = "SafeCar ESP32 v1.1.0";

IPAddress localIp(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

WebServer server(80);

// Estados simulados do veículo
bool doorsLocked = true;
bool headlightsOn = false;
bool windowsClosed = true;
bool alarmActive = true;
bool vibrationDetected = false;
bool movementDetected = false;
float batteryVoltage = 12.4;

unsigned long lastCommandAt = 0;
String lastCommand = "Nenhum comando recebido";

void addCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

String boolToJson(bool value) {
  return value ? "true" : "false";
}

String statusJson() {
  String json = "{";

  json += "\"connected\":true,";
  json += "\"doorsLocked\":" + boolToJson(doorsLocked) + ",";
  json += "\"headlightsOn\":" + boolToJson(headlightsOn) + ",";
  json += "\"windowsClosed\":" + boolToJson(windowsClosed) + ",";
  json += "\"alarmActive\":" + boolToJson(alarmActive) + ",";
  json += "\"vibrationDetected\":" + boolToJson(vibrationDetected) + ",";
  json += "\"movementDetected\":" + boolToJson(movementDetected) + ",";
  json += "\"batteryVoltage\":" + String(batteryVoltage, 1) + ",";
  json += "\"source\":\"ESP32 SafeCar\",";
  json += "\"firmwareVersion\":\"" + String(FIRMWARE_VERSION) + "\",";
  json += "\"ip\":\"192.168.4.1\",";
  json += "\"uptimeMs\":" + String(millis()) + ",";
  json += "\"lastCommand\":\"" + lastCommand + "\"";

  json += "}";

  return json;
}

void sendJson(String json) {
  addCorsHeaders();
  server.send(200, "application/json", json);
}

void handleStatus() {
  sendJson(statusJson());

  Serial.println("[GET] /status");
  Serial.println(statusJson());
}

void handleHealth() {
  String json = "{";
  json += "\"ok\":true,";
  json += "\"device\":\"ESP32\",";
  json += "\"project\":\"SafeCar\",";
  json += "\"firmwareVersion\":\"" + String(FIRMWARE_VERSION) + "\",";
  json += "\"uptimeMs\":" + String(millis());
  json += "}";

  sendJson(json);

  Serial.println("[GET] /health");
}

void resetVehicleState() {
  doorsLocked = true;
  headlightsOn = false;
  windowsClosed = true;
  alarmActive = true;
  vibrationDetected = false;
  movementDetected = false;
  batteryVoltage = 12.4;
  lastCommand = "reset";
  lastCommandAt = millis();
}

bool executeCommand(String command) {
  command.trim();

  if (command.length() == 0) {
    return false;
  }

  lastCommand = command;
  lastCommandAt = millis();

  Serial.print("[COMMAND] ");
  Serial.println(command);

  if (command == "lock_doors") {
    doorsLocked = true;
    return true;
  }

  if (command == "unlock_doors") {
    doorsLocked = false;
    return true;
  }

  if (command == "toggle_doors") {
    doorsLocked = !doorsLocked;
    return true;
  }

  if (command == "toggle_alarm") {
    alarmActive = !alarmActive;
    return true;
  }

  if (command == "activate_alarm") {
    alarmActive = true;
    return true;
  }

  if (command == "deactivate_alarm") {
    alarmActive = false;
    return true;
  }

  if (command == "toggle_lights") {
    headlightsOn = !headlightsOn;
    return true;
  }

  if (command == "turn_off_lights") {
    headlightsOn = false;
    return true;
  }

  if (command == "turn_on_lights") {
    headlightsOn = true;
    return true;
  }

  if (command == "toggle_windows") {
    windowsClosed = !windowsClosed;
    return true;
  }

  if (command == "close_windows") {
    windowsClosed = true;
    return true;
  }

  if (command == "open_windows") {
    windowsClosed = false;
    return true;
  }

  if (command == "simulate_impact") {
    vibrationDetected = true;
    movementDetected = true;
    return true;
  }

  if (command == "simulate_movement") {
    movementDetected = true;
    return true;
  }

  if (command == "clear_events") {
    vibrationDetected = false;
    movementDetected = false;
    return true;
  }

  if (command == "battery_low") {
    batteryVoltage = 11.5;
    return true;
  }

  if (command == "battery_normal") {
    batteryVoltage = 12.4;
    return true;
  }

  if (command == "reset") {
    resetVehicleState();
    return true;
  }

  return false;
}

String getCommandFromRequest() {
  if (server.hasArg("cmd")) {
    return server.arg("cmd");
  }

  if (server.hasArg("command")) {
    return server.arg("command");
  }

  if (server.hasArg("name")) {
    return server.arg("name");
  }

  if (server.hasArg("action")) {
    return server.arg("action");
  }

  return "";
}

void handleCommand() {
  addCorsHeaders();

  String command = getCommandFromRequest();

  bool success = executeCommand(command);

  if (!success) {
    String errorJson = "{";
    errorJson += "\"success\":false,";
    errorJson += "\"message\":\"Comando invalido ou ausente\",";
    errorJson += "\"received\":\"" + command + "\"";
    errorJson += "}";

    server.send(400, "application/json", errorJson);
    return;
  }

  String json = "{";
  json += "\"success\":true,";
  json += "\"command\":\"" + command + "\",";
  json += "\"status\":" + statusJson();
  json += "}";

  server.send(200, "application/json", json);
}

void handleReset() {
  resetVehicleState();

  String json = "{";
  json += "\"success\":true,";
  json += "\"message\":\"Estados resetados\",";
  json += "\"status\":" + statusJson();
  json += "}";

  sendJson(json);

  Serial.println("[GET] /reset");
}

String htmlPage() {
  String html = "";

  html += "<!DOCTYPE html>";
  html += "<html lang='pt-BR'>";
  html += "<head>";
  html += "<meta charset='UTF-8'>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
  html += "<title>SafeCar ESP32</title>";
  html += "<style>";
  html += "body{font-family:Arial,sans-serif;background:#F0FAFF;margin:0;padding:20px;color:#244B44;}";
  html += ".card{background:#fff;border-radius:20px;padding:18px;margin-bottom:16px;box-shadow:0 4px 12px rgba(0,0,0,.08);}";
  html += "h1{color:#3A6A60;text-align:center;}";
  html += "button{width:100%;padding:14px;margin:6px 0;border:0;border-radius:20px;background:#3A6A60;color:white;font-weight:bold;font-size:15px;}";
  html += ".secondary{background:white;color:#3A6A60;border:1px solid #3A6A60;}";
  html += "pre{background:#1f2937;color:#e5e7eb;padding:14px;border-radius:14px;overflow:auto;}";
  html += ".status{font-weight:bold;color:#3A6A60;}";
  html += "</style>";
  html += "</head>";
  html += "<body>";

  html += "<h1>SafeCar ESP32</h1>";

  html += "<div class='card'>";
  html += "<p><strong>Firmware:</strong> " + String(FIRMWARE_VERSION) + "</p>";
  html += "<p><strong>IP:</strong> 192.168.4.1</p>";
  html += "<p class='status'>Servidor local ativo</p>";
  html += "</div>";

  html += "<div class='card'>";
  html += "<h2>Ações rápidas</h2>";
  html += "<button onclick=\"cmd('lock_doors')\">Trancar portas</button>";
  html += "<button onclick=\"cmd('unlock_doors')\">Destrancar portas</button>";
  html += "<button onclick=\"cmd('toggle_alarm')\">Ativar/Desativar alarme</button>";
  html += "<button onclick=\"cmd('toggle_lights')\">Alternar faróis</button>";
  html += "<button onclick=\"cmd('toggle_windows')\">Alternar vidros</button>";
  html += "<button onclick=\"cmd('simulate_impact')\">Simular impacto</button>";
  html += "<button onclick=\"cmd('clear_events')\">Limpar eventos</button>";
  html += "<button onclick=\"cmd('battery_low')\">Simular bateria baixa</button>";
  html += "<button onclick=\"cmd('battery_normal')\">Normalizar bateria</button>";
  html += "<button class='secondary' onclick=\"cmd('reset')\">Resetar estados</button>";
  html += "</div>";

  html += "<div class='card'>";
  html += "<h2>Status JSON</h2>";
  html += "<pre id='json'>Carregando...</pre>";
  html += "</div>";

  html += "<script>";
  html += "async function refresh(){";
  html += "const r=await fetch('/status');";
  html += "const j=await r.json();";
  html += "document.getElementById('json').textContent=JSON.stringify(j,null,2);";
  html += "}";
  html += "async function cmd(c){";
  html += "await fetch('/command?cmd='+encodeURIComponent(c));";
  html += "refresh();";
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

  Serial.println("[GET] /");
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

  /*
    Compatibilidade:
    Se algum cliente chamar /lock_doors, /toggle_lights etc.,
    o ESP32 tenta interpretar o caminho como comando.
  */
  String uri = server.uri();

  if (uri.startsWith("/")) {
    uri.remove(0, 1);
  }

  if (uri.length() > 0) {
    bool success = executeCommand(uri);

    if (success) {
      String json = "{";
      json += "\"success\":true,";
      json += "\"command\":\"" + uri + "\",";
      json += "\"status\":" + statusJson();
      json += "}";

      server.send(200, "application/json", json);
      return;
    }
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
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/health", HTTP_GET, handleHealth);
  server.on("/reset", HTTP_GET, handleReset);

  server.on("/command", HTTP_GET, handleCommand);
  server.on("/command", HTTP_POST, handleCommand);
  server.on("/command", HTTP_OPTIONS, handleOptions);

  server.onNotFound(handleNotFound);
}

void setupWiFiAccessPoint() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(localIp, gateway, subnet);

  bool started = WiFi.softAP(WIFI_SSID, WIFI_PASSWORD);

  Serial.println();
  Serial.println("==================================");
  Serial.println(" SafeCar ESP32 iniciado");
  Serial.println("==================================");

  if (started) {
    Serial.println("Rede Wi-Fi criada com sucesso!");
  } else {
    Serial.println("Falha ao criar a rede Wi-Fi.");
  }

  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  Serial.print("Senha: ");
  Serial.println(WIFI_PASSWORD);

  Serial.print("IP: ");
  Serial.println(WiFi.softAPIP());

  Serial.println("----------------------------------");
  Serial.println("Acesse no navegador:");
  Serial.println("http://192.168.4.1");
  Serial.println("http://192.168.4.1/status");
  Serial.println("==================================");
  Serial.println();
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  resetVehicleState();
  setupWiFiAccessPoint();
  setupRoutes();

  server.begin();

  Serial.println("Servidor HTTP iniciado.");
}

void loop() {
  server.handleClient();
}