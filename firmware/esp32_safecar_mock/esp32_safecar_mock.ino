#include <WiFi.h>
#include <WebServer.h>

/*
  SafeCar - Firmware ESP32 sensor-ready

  Este firmware cria uma rede Wi-Fi local e disponibiliza endpoints HTTP
  para o aplicativo SafeCar consultar e alterar o estado do veículo.

  Ele possui dois modos:

  1. Modo simulação:
     - O app e o painel web alteram os estados manualmente.
     - Ideal para apresentação sem sensores.

  2. Modo sensores:
     - O ESP32 passa a ler pinos físicos preparados para sensores.
     - Ideal para bancada com protoboard.

  Rede:
    SSID: SafeCar-ESP32
    Senha: safecar123
    IP: 192.168.4.1

  Endpoints:
    GET  /
    GET  /status
    GET  /health
    GET  /command?cmd=nome_do_comando
    POST /command?cmd=nome_do_comando
    GET  /reset
*/

#include <Arduino.h>

const char* WIFI_SSID = "SafeCar-ESP32";
const char* WIFI_PASSWORD = "safecar123";

const char* FIRMWARE_VERSION = "SafeCar ESP32 v1.2.0 sensor-ready";

IPAddress localIp(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

WebServer server(80);

// ==============================
// Pinos preparados para sensores
// ==============================
const int PIN_STATUS_LED = 2;

const int PIN_IMPACT_SENSOR = 27;
const int PIN_DOOR_SENSOR = 26;
const int PIN_WINDOW_SENSOR = 25;

const int PIN_LIGHT_SENSOR = 34;
const int PIN_BATTERY_SENSOR = 35;

// ==============================
// Configurações dos sensores
// ==============================

// Sensores digitais com INPUT_PULLUP:
// HIGH = normal
// LOW  = evento detectado
//
// Se seu sensor funcionar invertido depois, basta trocar true/false aqui.
const bool DIGITAL_SENSOR_ACTIVE_LOW = true;

// Limiares analógicos iniciais.
// Depois ajustamos olhando os valores reais no painel web.
const int LIGHT_THRESHOLD = 2200;
const int BATTERY_LOW_RAW_THRESHOLD = 1800;

// Conversão simulada para bateria.
// Isso será calibrado depois com divisor de tensão real.
const float BATTERY_NORMAL_VOLTAGE = 12.4;
const float BATTERY_LOW_VOLTAGE = 11.5;

// ==============================
// Estados do veículo
// ==============================
bool sensorMode = false;

bool doorsLocked = true;
bool headlightsOn = false;
bool windowsClosed = true;
bool alarmActive = true;
bool vibrationDetected = false;
bool movementDetected = false;
float batteryVoltage = 12.4;

int rawImpact = 1;
int rawDoor = 1;
int rawWindow = 1;
int rawLight = 0;
int rawBattery = 0;

unsigned long lastCommandAt = 0;
String lastCommand = "Nenhum comando recebido";

unsigned long lastSensorReadAt = 0;
unsigned long lastBlinkAt = 0;
bool ledState = false;

// ==============================
// Utilidades
// ==============================
void addCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

String boolToJson(bool value) {
  return value ? "true" : "false";
}

bool digitalDetected(int rawValue) {
  if (DIGITAL_SENSOR_ACTIVE_LOW) {
    return rawValue == LOW;
  }

  return rawValue == HIGH;
}

void resetVehicleState() {
  doorsLocked = true;
  headlightsOn = false;
  windowsClosed = true;
  alarmActive = true;
  vibrationDetected = false;
  movementDetected = false;
  batteryVoltage = BATTERY_NORMAL_VOLTAGE;

  lastCommand = "reset";
  lastCommandAt = millis();
}

void readSensors() {
  if (!sensorMode) {
    return;
  }

  rawImpact = digitalRead(PIN_IMPACT_SENSOR);
  rawDoor = digitalRead(PIN_DOOR_SENSOR);
  rawWindow = digitalRead(PIN_WINDOW_SENSOR);

  rawLight = analogRead(PIN_LIGHT_SENSOR);
  rawBattery = analogRead(PIN_BATTERY_SENSOR);

  vibrationDetected = digitalDetected(rawImpact);
  movementDetected = vibrationDetected;

  // Para reed switch:
  // sensor detectado = condição fechada/segura.
  doorsLocked = digitalDetected(rawDoor);
  windowsClosed = digitalDetected(rawWindow);

  // LDR/farol:
  // se passar do limite, interpretamos como luz/farol detectado.
  headlightsOn = rawLight > LIGHT_THRESHOLD;

  // Bateria simulada:
  // sem divisor real, isso serve como preparação.
  batteryVoltage = rawBattery < BATTERY_LOW_RAW_THRESHOLD
      ? BATTERY_LOW_VOLTAGE
      : BATTERY_NORMAL_VOLTAGE;
}

String statusJson() {
  String json = "{";

  json += "\"connected\":true,";
  json += "\"sensorMode\":" + boolToJson(sensorMode) + ",";
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
  json += "\"lastCommand\":\"" + lastCommand + "\",";
  json += "\"rawImpact\":" + String(rawImpact) + ",";
  json += "\"rawDoor\":" + String(rawDoor) + ",";
  json += "\"rawWindow\":" + String(rawWindow) + ",";
  json += "\"rawLight\":" + String(rawLight) + ",";
  json += "\"rawBattery\":" + String(rawBattery);

  json += "}";

  return json;
}

void sendJson(String json) {
  addCorsHeaders();
  server.send(200, "application/json", json);
}

// ==============================
// Handlers HTTP
// ==============================
void handleStatus() {
  readSensors();
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
  json += "\"sensorMode\":" + boolToJson(sensorMode) + ",";
  json += "\"uptimeMs\":" + String(millis());
  json += "}";

  sendJson(json);

  Serial.println("[GET] /health");
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

  if (command == "mode_simulation") {
    sensorMode = false;
    return true;
  }

  if (command == "mode_sensors") {
    sensorMode = true;
    readSensors();
    return true;
  }

  if (command == "toggle_mode") {
    sensorMode = !sensorMode;
    readSensors();
    return true;
  }

  /*
    Em modo sensores, alguns comandos manuais continuam liberados,
    mas os estados lidos fisicamente podem sobrescrever no próximo refresh.
  */

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
    batteryVoltage = BATTERY_LOW_VOLTAGE;
    return true;
  }

  if (command == "battery_normal") {
    batteryVoltage = BATTERY_NORMAL_VOLTAGE;
    return true;
  }

  if (command == "reset") {
    sensorMode = false;
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

  readSensors();

  String json = "{";
  json += "\"success\":true,";
  json += "\"command\":\"" + command + "\",";
  json += "\"status\":" + statusJson();
  json += "}";

  server.send(200, "application/json", json);
}

void handleReset() {
  sensorMode = false;
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
  html += ".danger{background:#DC2626;}";
  html += "pre{background:#1f2937;color:#e5e7eb;padding:14px;border-radius:14px;overflow:auto;}";
  html += ".status{font-weight:bold;color:#3A6A60;}";
  html += ".grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;}";
  html += ".pin{background:#F0FAFF;border-radius:14px;padding:10px;font-size:14px;}";
  html += "</style>";
  html += "</head>";
  html += "<body>";

  html += "<h1>SafeCar ESP32</h1>";

  html += "<div class='card'>";
  html += "<p><strong>Firmware:</strong> " + String(FIRMWARE_VERSION) + "</p>";
  html += "<p><strong>IP:</strong> 192.168.4.1</p>";
  html += "<p><strong>Rede:</strong> SafeCar-ESP32</p>";
  html += "<p class='status'>Servidor local ativo</p>";
  html += "</div>";

  html += "<div class='card'>";
  html += "<h2>Modo de operação</h2>";
  html += "<button onclick=\"cmd('mode_simulation')\">Modo simulação</button>";
  html += "<button onclick=\"cmd('mode_sensors')\">Modo sensores</button>";
  html += "<button class='secondary' onclick=\"cmd('toggle_mode')\">Alternar modo</button>";
  html += "</div>";

  html += "<div class='card'>";
  html += "<h2>Mapa de pinos</h2>";
  html += "<div class='grid'>";
  html += "<div class='pin'><strong>GPIO 27</strong><br>Impacto</div>";
  html += "<div class='pin'><strong>GPIO 26</strong><br>Porta</div>";
  html += "<div class='pin'><strong>GPIO 25</strong><br>Vidro</div>";
  html += "<div class='pin'><strong>GPIO 34</strong><br>LDR/Farol</div>";
  html += "<div class='pin'><strong>GPIO 35</strong><br>Bateria</div>";
  html += "<div class='pin'><strong>GPIO 2</strong><br>LED status</div>";
  html += "</div>";
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
  html += "<button class='danger' onclick=\"cmd('reset')\">Resetar estados</button>";
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

  String uri = server.uri();

  if (uri.startsWith("/")) {
    uri.remove(0, 1);
  }

  if (uri.length() > 0) {
    bool success = executeCommand(uri);

    if (success) {
      readSensors();

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

void setupPins() {
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);

  pinMode(PIN_IMPACT_SENSOR, INPUT_PULLUP);
  pinMode(PIN_DOOR_SENSOR, INPUT_PULLUP);
  pinMode(PIN_WINDOW_SENSOR, INPUT_PULLUP);

  pinMode(PIN_LIGHT_SENSOR, INPUT);
  pinMode(PIN_BATTERY_SENSOR, INPUT);
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

void updateStatusLed() {
  unsigned long now = millis();

  unsigned long interval = sensorMode ? 250 : 800;

  if (now - lastBlinkAt >= interval) {
    lastBlinkAt = now;
    ledState = !ledState;
    digitalWrite(PIN_STATUS_LED, ledState ? HIGH : LOW);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  setupPins();
  resetVehicleState();
  setupWiFiAccessPoint();
  setupRoutes();

  server.begin();

  Serial.println("Servidor HTTP iniciado.");
  Serial.println("Modo inicial: simulacao.");
}

void loop() {
  server.handleClient();

  if (sensorMode && millis() - lastSensorReadAt >= 300) {
    lastSensorReadAt = millis();
    readSensors();
  }

  updateStatusLed();
}