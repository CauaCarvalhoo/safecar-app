# Guia didático do SafeCar

## 1. Ideia geral

O app agora trabalha de duas formas:

1. **Modo simulação**: o próprio aplicativo inventa estados do carro. Isso permite apresentar e testar o sistema mesmo sem sensores.
2. **Modo ESP32**: o aplicativo faz requisições HTTP para o ESP32. O ESP32 responde com um JSON contendo o estado do veículo.

A lógica é parecida com um restaurante:

- O app é o cliente perguntando: "Como está o carro?"
- O ESP32 é o garçom respondendo: "Portas trancadas, faróis apagados, vidros fechados..."
- Os sensores serão os olhos do ESP32.

## 2. Arquivos principais

### `lib/main.dart`

É a entrada do aplicativo. Ele define:

- o tema visual;
- as rotas/telas;
- a primeira tela exibida.

### `lib/theme/app_theme.dart`

Centraliza as cores e estilos do app. Se quiser mudar o padrão visual do SafeCar, comece por esse arquivo.

### `lib/models/vehicle_status.dart`

Representa o estado do veículo. Exemplo:

- portas trancadas;
- faróis acesos;
- vidros fechados;
- alarme ativo;
- impacto detectado;
- tensão da bateria.

Também gera alertas automaticamente quando encontra uma situação perigosa, como faróis acesos ou vidro aberto.

### `lib/services/safecar_service.dart`

É a ponte entre o aplicativo e os dados.

- Se o modo simulação estiver ligado, ele gera dados falsos para teste.
- Se o modo simulação estiver desligado, ele chama o ESP32 pela rede.

### `lib/screens/home_page.dart`

É a tela principal. Ela mostra:

- cartão de conexão;
- configuração do ESP32;
- cards de status;
- botões de ação;
- histórico de alertas.

### `firmware/esp32_safecar_mock/esp32_safecar_mock.ino`

É o código inicial do ESP32. Ele cria uma rede Wi-Fi própria chamada `SafeCar-ESP32` e responde ao app pelo IP `192.168.4.1`.

## 3. Como o app conversa com o ESP32

O app usa requisições HTTP simples.

Exemplo de leitura:

```text
GET http://192.168.4.1/status
```

Resposta esperada:

```json
{
  "connected": true,
  "doorsLocked": true,
  "headlightsOn": false,
  "windowsClosed": true,
  "alarmActive": true,
  "vibrationDetected": false,
  "movementDetected": false,
  "batteryVoltage": 12.4,
  "source": "ESP32 SafeCar"
}
```

Exemplo de comando:

```text
GET http://192.168.4.1/command?name=simulate_impact
```

## 4. Por que usar HTTP no começo?

Porque é mais fácil para um protótipo acadêmico:

- não precisa mexer com Bluetooth agora;
- dá para testar pelo navegador;
- o JSON é simples de entender;
- o ESP32 consegue criar uma rede Wi-Fi própria.

Depois, se o projeto evoluir, vocês podem migrar para MQTT, Firebase ou Bluetooth Low Energy.

## 5. Próximos passos técnicos

### Etapa 1: validar o app sem sensores

- Rodar o Flutter.
- Testar o modo simulação.
- Verificar se os alertas aparecem.

### Etapa 2: validar o ESP32 sem sensores

- Gravar o firmware no ESP32.
- Conectar o celular ao Wi-Fi do ESP32.
- Abrir o navegador e acessar `http://192.168.4.1/status`.
- Confirmar que aparece o JSON.

### Etapa 3: ligar sensores em bancada

Começar com sensores simples:

- botão ou reed switch para simular porta/vidro;
- sensor SW-420 para vibração;
- LDR para luminosidade;
- MPU6050 para inclinação/impacto.

### Etapa 4: substituir simulações por leituras reais

No firmware, trocar variáveis como:

```cpp
bool windowsClosed = true;
```

por leituras de pino, por exemplo:

```cpp
bool windowsClosed = digitalRead(PINO_SENSOR_VIDRO) == HIGH;
```

### Etapa 5: melhorar segurança

Antes de instalar em carro real:

- usar proteção elétrica;
- evitar ligação direta em 12V;
- usar divisor de tensão, optoacoplador ou módulos adequados;
- testar tudo em bancada.

## 6. Materiais recomendados

- ESP32;
- protoboard;
- jumpers;
- resistores;
- sensor de vibração SW-420;
- reed switch para portas/vidros;
- LDR para luminosidade;
- MPU6050 para inclinação;
- fonte USB estável para testes.

## 7. O que apresentar para o professor

Vocês podem dizer que o projeto possui três níveis:

1. **Aplicativo funcional** com dashboard, alertas e histórico.
2. **Comunicação com ESP32** por rede Wi-Fi local.
3. **Arquitetura preparada para sensores reais**, que serão adicionados conforme aquisição de materiais.
