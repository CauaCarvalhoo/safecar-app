# SafeCar Fleet — Relatório acadêmico de UX/UI e validação

**Projeto Integrador:** SafeCar Fleet  
**Tema:** Experiência do usuário na consulta de dados automotivos, viagens e alertas  
**Objetivo:** Explicar e avaliar a clareza, a consistência e a capacidade de execução de tarefas na interface móvel e no dashboard Web.

## 1. Materiais e evolução documentados

**Evidências visuais do grupo:**
- Protótipos de alta fidelidade no Figma para apresentação, cadastro e login;
- Protótipos do usuário: início, veículos, notificações, histórico de eventos e chat;
- Captura do aplicativo Flutter na seção "Conexão do protótipo", com endereço local do ESP32 e controles de estados automotivos;
- Foto da montagem em protoboard com ESP32 e GPS no interior do veículo;
- Registro do monitor serial com "GPS válido: SIM" e sete satélites identificados no momento da captura.

As imagens demonstram implementação e experimentação do protótipo, **mas a foto do hardware não comprova a precisão da localização nem que as indicações de portas, faróis e alarme foram lidas por sensores reais**. As mensagens do protótipo e o resultado do monitor serial devem ser descritos no escopo exato em que foram observados.

### Linha de evolução visual

1. **Figma:** concepção de telas de apresentação, login, veículos, notificações e outras áreas do usuário.
2. **Flutter:** criação de telas funcionais para veículos, conexões com protótipo, viagens e alertas.
3. **Web:** dashboard responsivo com autenticação Firebase, navegação explícita e consulta a registros autorizados.
4. **Revisões de IHC:** distinção de dados demonstrativos, confirmação antes de excluir viagens, estados vazios, menu denominado "Dashboard" e mensagens de conexão.

## 2. Persona de referência e tarefa crítica

**Persona de referência:** gestor(a) de frota que utiliza computador e celular durante a rotina operacional.

**Objetivo principal:** localizar o registro de uma viagem e consultar os alertas associados sem depender de conhecimento técnico.

**Tarefa crítica (fluxo):** login → Dashboard → Viagens → seleção de período → leitura da viagem e seus indicadores.

**Ações observáveis:** localizar menus, perceber mudança de tela, filtrar, encontrar informação e recuperar-se de um erro de navegação.

## 3. Procedimento recomendado para testes cruzados

**Participantes:** colegas de outro grupo, identificados apenas como P01, P02 etc.  
**Ambiente:** navegador em computador, navegador de celular e, quando necessário, app Flutter.  
**Instrumentos:** cronômetro, ficha de erros, checklist de acessibilidade e perguntas curtas ao final.

### Tarefas e critérios

| Código | Tarefa | Critério de conclusão | Possível erro |
| --- | --- | --- | --- |
| T1 | Entrar e localizar o Dashboard | Login concluído e tela correta localizada | Procura prolongada por menu ou erro de navegação |
| T2 | Localizar um veículo | Encontrar placa/nome solicitado na lista | Buscar em menu incorreto ou não perceber campo de busca |
| T3 | Consultar uma viagem | Identificar viagem e seus dados no período escolhido | Selecionar período errado ou confundir dados |
| T4 | Consultar alertas | Acessar lista de alertas e identificar uma ocorrência | Não localizar o menu ou interpretar estado incorretamente |

Registrar: tempo em segundos, erro(s), conclusão, necessidade de ajuda e relato espontâneo. Testar consentimento dos participantes e anonimizar quaisquer observações.

## 4. Base de treinamento demonstrativa — NÃO é teste com usuários realizado

Para ensaiar a planilha e a apresentação do método, criamos **20 execuções simuladas de tarefas, correspondentes a cinco participantes fictícios e quatro tarefas cada**. Esses dados não são resultados de entrevistas, observações de colegas ou medições de uso real.

Arquivo: `docs/ux/testes-cruzados-demonstracao.csv`.

| Indicador ilustrativo | Resultado do conjunto simulado | Cálculo |
| --- | --- | --- |
| Execuções de tarefa | 20 | 5 participantes fictícios × 4 tarefas |
| Conclusões | 19 | soma da coluna `concluiu = sim` |
| Taxa de sucesso | 95% | 19 ÷ 20 × 100 |
| Número de erros | 5 | soma da coluna `erros` |
| Tarefas com erro | 25% | 5 tarefas com erro ÷ 20 × 100 |
| Tempo mediano | 30 s | mediana dos 20 tempos |

**Uso correto:** apresentar esta tabela como *exemplo de cálculo das métricas* e substituí-la pelas medições dos testes cruzados do grupo quando estiverem disponíveis.

## 5. Auditoria heurística e correções

| Identificação | Fundamentação de IHC | Correção realizada ou ação |
| --- | --- | --- |
| Dados fictícios apresentados em dashboard protótipo | Nielsen: visibilidade do estado e compatibilidade com mundo real | Dashboard passou a consultar dados da conta autenticada; ausência de registros mostra estado vazio |
| Menu não nomeava explicitamente Dashboard | Nielsen: correspondência com modelo mental e reconhecimento | Inserida aba Dashboard |
| Excluir viagens sem confirmação | Nielsen: prevenção de erros e controle do usuário | Confirmação antes da exclusão, com opção de cancelar |
| Mensagens de conexão não suficientemente claras | Norman: feedback e visibilidade | Exibição de conexão/estado no app; revisar linguagem em testes cruzados |
| Contraste, teclado e foco de controles | WCAG 2.2 | Auditoria manual e automatizada adicional |

**Severidade proposta:** alta prioridade para clareza da origem dos dados, prevenção de exclusão acidental, contraste/foco e interpretação dos alertas. A classificação final deve usar observações de participantes reais.

## 6. Resultados verificáveis hoje

- Existe protótipo Figma com telas iniciais e telas do usuário, documentado por screenshots fornecidas pelo grupo.
- A captura do app mostra controles e mensagem relacionada à conexão local do ESP32.
- A foto documenta montagem física de ESP32/GPS em veículo.
- O monitor serial registra GPS válido e sete satélites na captura.
- A Web está publicada e utiliza autenticação e Firestore (segundo testes funcionais do desenvolvimento).
- Os testes automatizados do repositório verificam regras de acesso do Firestore e build do frontend.

Não se deve usar a base simulada como resultado real de teste cruzado; as fotos não substituem observações de usabilidade com participantes.

## 7. Plano de validação final

1. Recrutar pelo menos três colegas externos ao grupo, com consentimento.
2. Executar as quatro tarefas, sem orientar os cliques.
3. Registrar tempo, erros, conclusão e dificuldade de cada participante.
4. Preencher planilha com resultados observados e recalcular indicadores.
5. Revisar severidade de problemas (alta, média, baixa) e associá-los às heurísticas.
6. Capturar antes/depois das telas corrigidas, além do Figma e das fotos do protótipo.
7. Apresentar evidências no site público `/sobre-nos`.

**Nota de privacidade:** os prints do monitor serial para publicação foram preparados sem senha de rede e com coordenadas ocultadas.
