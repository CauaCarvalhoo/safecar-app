# Testes de segurança do Firestore — SafeCar Fleet

Estes testes validam **apenas** as regras de acesso do Firestore usando dados
fictícios no **Firebase Emulator**, sem acessar o projeto real de produção.

## Pré-requisitos (Windows)
- Git instalado
- Node.js LTS (Node 22 ou superior) com npm
- Java JDK 21 instalado (comando `java -version` deve funcionar)

## Como executar
Abra o PowerShell ou terminal do VS Code:

```powershell
git clone https://github.com/CauaCarvalhoo/safecar-app.git
cd safecar-app
git fetch origin
git switch feature/safecar-fleet-obd
git pull --ff-only origin feature/safecar-fleet-obd

node --version
npm --version
java -version
npm install
npx firebase-tools@latest emulators:exec --config firebase.emulator.json --project demo-safecar-rules --only firestore "npm test"
```

Se já tiver a pasta clonada, pule `git clone` e entre nela.

## Resultado esperado
- Emulador Firestore inicia em `127.0.0.1:8080`.
- Testes Jest executam os sete cenários em `security/firestore.rules.test.js`.
- Resultado final: `Test Suites: 1 passed` e `Tests: 7 passed`.
- O processo finaliza com código 0.

## Falhas comuns
- `java is not recognized`: instale/configure JDK 21 e reinicie o terminal.
- `npm is not recognized`: instale Node.js LTS e reinicie o terminal.
- `Port 8080 already in use`: feche o emulador existente ou ajuste a porta
  em `firebase.emulator.json`.
- Sem acesso à rede na primeira execução: o Firebase CLI pode precisar baixar
  os binários do emulador.
- Se aparecer `Cannot find module`, rode `npm install` na raiz do projeto.
- Se falhar uma asserção `assertSucceeds`/`assertFails`, **não faça deploy**:
  registre a saída completa do teste para corrigir a regra.

## Por que usar um projeto demo?
O ID `demo-safecar-rules` não é o Firebase real do aplicativo; seu uso ajuda a
evitar alterações acidentais nos dados de produção.

## Limitações
- Passar nos sete testes **não garante** que todo o sistema é seguro.
- Ainda faltam testes de integração do backend, provisionamento de organizações
  e perfis, e testes funcionais do app Flutter.
- O CI será executado no GitHub após o merge deste PR (e para PRs que
  incluam o workflow).
