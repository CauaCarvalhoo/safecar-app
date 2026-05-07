# SafeCar - Aplicativo de Segurança Automotiva

O **SafeCar** é um projeto integrador desenvolvido para o curso de Engenharia de Computação da UNISAL.  
A proposta do sistema é criar uma solução de segurança automotiva baseada em aplicativo mobile, sensores e integração futura com ESP32.

O aplicativo permite monitorar o estado do veículo, simular alertas e futuramente receber informações reais de sensores instalados em um protótipo físico.

---

## Objetivo do Projeto

Desenvolver um sistema de monitoramento automotivo capaz de alertar o usuário sobre possíveis situações de risco ou descuido, como:

- Faróis esquecidos acesos
- Vidros abertos
- Portas destrancadas
- Impactos ou vibrações suspeitas
- Estado do alarme
- Comunicação futura com ESP32

---

## Tecnologias Utilizadas

- Flutter
- Dart
- ESP32
- HTTP
- IoT
- Git e GitHub

---

## Funcionalidades Atuais

- Tela inicial com identidade visual do SafeCar
- Telas de introdução
- Cadastro e login em modo protótipo
- Home com status do veículo
- Modo simulação
- Histórico de alertas
- Simulação de impacto
- Simulação de faróis acesos
- Simulação de vidro aberto
- Preparação para comunicação com ESP32 via Wi-Fi

---

## Estrutura do Projeto

```text
lib/
├── main.dart
├── models/
│   └── vehicle_status.dart
├── screens/
│   ├── splash_screen.dart
│   ├── intro_page.dart
│   ├── login_page.dart
│   ├── register_page.dart
│   └── home_page.dart
├── services/
│   └── safecar_service.dart
└── theme/
    └── app_theme.dart