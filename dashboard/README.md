# SafeCar Fleet — Dashboard Web (MVP)

Painel administrativo responsivo desenvolvido com **Next.js + React + TypeScript**.

> **IMPORTANTE:** Nesta primeira versão, todos os dados e indicadores apresentados são **demonstrativos e fictícios**. O dashboard não tem autenticação nem acesso ao Firebase real. Não insira credenciais, tokens ou dados de clientes neste projeto.

## Telas
- Visão geral: cards de KPIs, gráfico de atividade, status da frota, veículos e ocorrências
- Veículos: busca por veículo, placa e motorista
- Motoristas: ranking por score ilustrativo
- Alertas: lista de eventos simulados
- Relatórios: resumo gráfico demonstrativo
- Filtro de período e layout responsivo

## Executar localmente
No terminal, a partir da raiz do repositório:

```bash
cd dashboard
npm install
npm run dev
```

Acesse http://localhost:3000 no navegador.

Para validar o build:

```bash
npm run lint
npm run build
```

## Publicar na Vercel
1. Acesse https://vercel.com/new e conecte sua conta GitHub.
2. Importe `CauaCarvalhoo/safecar-app` como um novo projeto.
3. Em **Root Directory**, escolha `dashboard` (crítico: o Next.js está numa subpasta).
4. Framework Preset: **Next.js**; Build Command: `npm run build`; Output Directory: padrão.
5. Branch de produção: use `feature/safecar-fleet-obd` **depois que o Pull Request for mergeado**.
   Se a integração exigir a branch padrão, faça a integração planejada da branch de desenvolvimento à `main` e configure o deployment conforme sua política.
6. Clique em **Deploy**. A Vercel exibirá a URL real atribuída ao projeto (não é possível antecipar o endereço).
7. Verifique as cinco páginas, filtros e layout no celular.

Na primeira publicação não são necessárias variáveis de ambiente.

## Próximas entregas
- Login via Firebase Authentication e autorização por organização
- API de leitura segura das organizações, veículos e viagens
- Agregações reais e filtros com consultas eficientes
- Ingestão normalizada dos dados do ESP32 e futuramente 4G
- Testes de componentes e integração
