# Base fictícia segura para demonstração UX

O SafeCar usa o Firebase Cloud Firestore. Para facilitar testes de interface sem inserir clientes falsos na aplicação real, foi criada uma rotina de carga para o **Firestore Emulator local**.

A rotina gera **duas empresas fictícias**, três veículos, três viagens e dois alertas de exemplo, com o campo `demo: true`. Nenhum documento é gravado no Firebase de produção.

## Como popular o emulador

Na **raiz** do projeto (onde está `firestore.rules`):

```bash
npm install
npx firebase-tools@latest emulators:start --config firebase.emulator.json --project demo-safecar-ux --only firestore
```

Em um **segundo terminal**, ainda na raiz:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node security/seed_demo_ux.mjs
```

Para executar no PowerShell:

```powershell
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
node security/seed_demo_ux.mjs
```

**Importante:** o app Web atual usa o projeto Firebase real; ele **não acessa automaticamente o emulador**. Esta base é apropriada para desenvolvimento local ou testes automatizados futuros. Não execute cargas de teste no projeto de produção com usuários reais.

## Indicadores de usabilidade

A planilha `docs/ux/testes-cruzados-demonstracao.csv` contém dados **inteiramente simulados**, úteis para demonstrar cálculo de eficácia (sucessos), eficiência (tempo) e erros. Não são medições de participantes reais. O relatório completo está em `docs/ux/RELATORIO_UX_SAFECAR.md`.
