# SafeCar - Protótipo Flutter + ESP32

Este projeto é o aplicativo piloto do SafeCar, um sistema de segurança automotiva com monitoramento por sensores e alertas no celular.

## O que já está funcional

- Fluxo de abertura, introdução, login e painel principal.
- Tela principal com estado do veículo: portas, faróis, vidros, alarme, impacto e bateria.
- Modo simulação para testar o app mesmo sem sensores físicos.
- Histórico de alertas.
- Comunicação HTTP preparada para o ESP32.
- Firmware de exemplo para ESP32 em `firmware/esp32_safecar_mock`.

## Como rodar o app

```bash
flutter pub get
flutter run
```

## Como testar sem sensores

1. Abra o app.
2. Faça login com qualquer e-mail válido e senha com 6 ou mais caracteres.
3. Deixe o "Modo simulação" ativado.
4. Use os botões de ação para simular faróis acesos, vidro aberto e impacto suspeito.

## Como testar com o ESP32

1. Abra `firmware/esp32_safecar_mock/esp32_safecar_mock.ino` na Arduino IDE.
2. Grave no ESP32.
3. No celular, conecte ao Wi-Fi `SafeCar-ESP32` com a senha `safecar123`.
4. No app, desligue o "Modo simulação".
5. Use o IP `192.168.4.1` e toque em "Conectar ao ESP32".

## Endpoints do ESP32

- `GET /status`: retorna o estado atual do veículo.
- `GET /command?name=lock_doors`: tranca portas.
- `GET /command?name=unlock_doors`: destranca portas.
- `GET /command?name=toggle_alarm`: ativa/desativa alarme.
- `GET /command?name=toggle_lights`: alterna faróis.
- `GET /command?name=turn_off_lights`: apaga faróis.
- `GET /command?name=toggle_windows`: alterna vidros.
- `GET /command?name=close_windows`: fecha vidros.
- `GET /command?name=simulate_impact`: simula impacto.
- `GET /command?name=clear_events`: limpa evento de impacto.

## Próximos componentes sugeridos

- Sensor de vibração/impacto SW-420 ou módulo acelerômetro MPU6050.
- Sensor magnético reed switch para portas/vidros.
- Sensor de luminosidade LDR ou leitura elétrica protegida para faróis.
- Módulo relé apenas para testes seguros em bancada, sem ligação direta ao carro real.
- Protoboard, jumpers, resistores e fonte adequada para o ESP32.

> Atenção: não conecte o ESP32 diretamente ao sistema elétrico real do carro sem proteção, divisor de tensão, optoacoplador ou módulo adequado. Para apresentação acadêmica, faça primeiro em bancada.
