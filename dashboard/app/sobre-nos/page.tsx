import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import "./sobre-nos.css";

export const metadata: Metadata = {
  title: "Sobre nós | SafeCar Fleet — Defesa UX/UI",
  description: "Defesa de Interação Humano-Computador do Projeto Integrador SafeCar Fleet: fatores humanos, acessibilidade, processo de design e avaliação.",
};

const sections = [
  { id: "fundamentos", number: "01", name: "Fundamentos e fator humano" },
  { id: "acessibilidade", number: "02", name: "Acessibilidade e inclusão" },
  { id: "processo", number: "03", name: "Processo de design" },
  { id: "validacao", number: "04", name: "Avaliação e validação" },
];
export default function SobreNos() {
  return <div className="ux-page">
    <a className="ux-skip" href="#conteudo">Pular para o conteúdo</a>
    <header className="ux-header">
      <div className="ux-header-inner">
        <Link href="/" className="ux-brand" aria-label="Voltar ao SafeCar Fleet">
          <Image src="/icon.svg" width={40} height={40} alt="" />
          <strong>SafeCar <span>Fleet</span></strong>
        </Link>
        <nav className="ux-nav" aria-label="Navegação da defesa">
          <a href="#fundamentos">Fundamentos</a><a href="#acessibilidade">Acessibilidade</a><a href="#processo">Design</a><a href="#validacao">Validação</a>
        </nav>
        <Link className="ux-login" href="/">Acessar plataforma <span aria-hidden="true">↗</span></Link>
      </div>
    </header>
    <main id="conteudo">
      <section className="ux-hero" aria-labelledby="hero-title">
        <div className="ux-hero-inner">
          <div className="ux-hero-copy">
            <span className="ux-eyebrow">PROJETO INTEGRADOR · DEFESA DE UX/UI</span>
            <h1 id="hero-title">Tecnologia para frotas.<br/><em>Interfaces para pessoas.</em></h1>
            <p>O SafeCar Fleet reúne informações de veículos, viagens e alertas em uma experiência que busca ser clara, previsível e acessível. Nesta defesa explicamos <strong>por que</strong> cada escolha de interface foi feita e como o projeto evoluiu da prototipação à validação.</p>
            <div className="ux-hero-actions"><a href="#fundamentos" className="ux-primary-link">Explorar a defesa <span aria-hidden="true">↓</span></a><a href="#validacao" className="ux-secondary-link">Plano de validação ↗</a></div>
            <div className="ux-hero-stats"><div><strong>04</strong><small>blocos da ementa</small></div><div><strong>Web + App</strong><small>experiência integrada</small></div><div><strong>UCD</strong><small>usuário como referência</small></div></div>
          </div>
          <div className="ux-visual" aria-label="Ilustração esquemática do painel SafeCar Fleet">
            <div className="ux-mini-top"><span className="ux-mini-logo">S</span><span>SafeCar Fleet</span><span className="ux-mini-dot">●</span></div>
            <div className="ux-mini-panel"><span>Visão geral da frota</span><div className="ux-mini-metrics"><div><small>Veículos</small><strong>◫</strong></div><div><small>Viagens</small><strong>⌁</strong></div><div><small>Alertas</small><strong>◇</strong></div></div><div className="ux-mini-chart" aria-hidden="true"><i/><i/><i/><i/><i/><i/><i/></div><div className="ux-mini-footer"><span>Veículos</span><span>Viagens</span><span>Alertas</span></div></div>
            <p>Representação conceitual da organização visual — sem dados fictícios apresentados como reais.</p>
          </div>
        </div>
      </section>
      <div className="ux-container">
        <nav className="ux-section-index" aria-label="Índice da defesa">{sections.map(s=><a key={s.id} href={"#"+s.id}><span>{s.number}</span><strong>{s.name}</strong><span aria-hidden="true">↗</span></a>)}</nav>

        <section className="ux-section" id="fundamentos" aria-labelledby="fundamentos-title">
          <div className="ux-section-heading"><span className="ux-kicker">BLOCO 01 / 04</span><h2 id="fundamentos-title">Fundamentos e fator humano</h2><p>O desafio não é apenas exibir dados. É ajudar a pessoa a compreender o estado da frota e decidir o próximo passo sem precisar aprender a estrutura interna do sistema.</p></div>
          <div className="ux-grid-two">
            <article className="ux-card"><span className="ux-card-icon">◎</span><h3>Problema que buscamos resolver</h3><p>Informações de veículos, viagens e ocorrências podem ficar espalhadas, dificultando o acompanhamento e aumentando o esforço para encontrar o que importa. O SafeCar organiza esses registros em uma visão acessível pelo aplicativo e pelo navegador.</p><div className="ux-small-note">Escopo atual: registros no Firebase; a telemetria do protótipo ainda pode conter dados simulados. Não declaramos monitoramento GPS remoto em tempo real.</div></article>
            <article className="ux-card"><span className="ux-card-icon">◫</span><h3>Modelos mentais e paradigmas</h3><p>Adotamos a metáfora de um <strong>painel de controle</strong>: visão geral, veículos, viagens e alertas são áreas familiares a quem gerencia uma frota. A interação segue o paradigma WIMP no Web (janelas, ícones, menus e ponteiro), com formulários, navegação por categorias e feedback visível.</p><div className="ux-small-note">Em vez de exigir conhecimento sobre coleções do banco de dados, a interface usa nomes próximos à tarefa do usuário.</div></article>
          </div>
          <div className="ux-callout"><strong>Como reduzimos a carga cognitiva?</strong><p>Apresentamos indicadores resumidos antes do detalhamento, mantemos a navegação persistente, usamos a mesma paleta verde do app e distinguimos estados como “carregando”, “sem registros” e “erro”. Isso favorece reconhecimento em vez de memorização e reduz a necessidade de alternar mentalmente entre telas.</p></div>
          <div className="ux-principles"><div><span>01</span><strong>Reconhecer</strong><small>Nomes familiares: Dashboard, Veículos, Viagens, Alertas.</small></div><div><span>02</span><strong>Hierarquizar</strong><small>Primeiro o resumo, depois listas e detalhes.</small></div><div><span>03</span><strong>Prever</strong><small>Padrões visuais e ações consistentes entre telas.</small></div></div>
        </section>

        <section className="ux-section" id="acessibilidade" aria-labelledby="acessibilidade-title">
          <div className="ux-section-heading"><span className="ux-kicker">BLOCO 02 / 04</span><h2 id="acessibilidade-title">Acessibilidade e inclusão</h2><p>Acessibilidade não é uma decoração adicional: ela determina se o sistema pode ser operado e compreendido por pessoas com diferentes necessidades e tecnologias assistivas.</p></div>
          <div className="ux-a11y-grid">
            <article className="ux-card"><h3>Contraste e identidade</h3><div className="ux-colors"><div className="ux-color ux-color-dark"><strong>#244B44</strong><small>Verde escuro</small></div><div className="ux-color ux-color-primary"><strong>#3A6A60</strong><small>Verde principal</small></div><div className="ux-color ux-color-pale"><strong>#F0FAFF</strong><small>Fundo claro</small></div></div><p>Cores de marca consistentes e texto escuro em fundos claros favorecem legibilidade. <strong>Os contrastes de todos os elementos interativos ainda exigem auditoria completa</strong>, especialmente textos secundários, estados de erro e foco.</p></article>
            <article className="ux-card"><h3>Leitores de tela e semântica</h3><p>A interface utiliza elementos estruturais como <code>main</code>, <code>nav</code>, títulos hierárquicos, rótulos em campos de formulário e textos alternativos quando imagens carregam significado. Nesta página há um link para pular diretamente ao conteúdo.</p><p>Mensagens de erro do formulário podem usar <code>role=&quot;alert&quot;</code>. A semântica reduz ambiguidade para tecnologias assistivas.</p></article>
            <article className="ux-card"><h3>Navegação e responsividade</h3><p>Botões e links recebem nomes compreensíveis; a página se adapta a telas menores e o conteúdo é organizado em blocos curtos. O percurso deve ser validado usando apenas teclado e diferentes níveis de zoom.</p></article>
            <article className="ux-card"><h3>Critérios WCAG a verificar</h3><ul><li><strong>1.4.3:</strong> contraste mínimo do texto;</li><li><strong>1.4.4:</strong> redimensionamento de texto;</li><li><strong>2.1.1:</strong> navegação por teclado;</li><li><strong>2.4.7:</strong> foco visível;</li><li><strong>3.3.2:</strong> rótulos e instruções;</li><li><strong>4.1.2:</strong> nome, função e valor.</li></ul><p className="ux-small-note">Referência: WCAG 2.2, W3C/WAI. Critérios listados são checklist de auditoria, não certificação de conformidade.</p></article>
          </div>
        </section>

        <section className="ux-section" id="processo" aria-labelledby="processo-title">
          <div className="ux-section-heading"><span className="ux-kicker">BLOCO 03 / 04</span><h2 id="processo-title">Processo de design e construção</h2><p>O design evoluiu entre a pesquisa de necessidades, a estruturação dos fluxos, os protótipos construídos no Figma e as interfaces implementadas.</p></div>
          <div className="ux-persona"><div className="ux-persona-avatar" aria-hidden="true">GM</div><div><span className="ux-label">PERSONA DE REFERÊNCIA</span><h3>Gestor(a) de frota</h3><p>Precisa descobrir rapidamente quais veículos estão cadastrados, consultar viagens e localizar alertas sem depender de conhecimento técnico. Tem pouco tempo e alterna entre computador e celular.</p><div className="ux-persona-tags"><span>Objetivo: visão rápida</span><span>Dor: informação dispersa</span><span>Contexto: rotina operacional</span></div><small>Perfil de referência utilizado para orientar a organização das informações e o fluxo de consulta.</small></div></div>
          <h3 className="ux-subheading">Jornada do usuário · tarefa crítica</h3>
          <div className="ux-flow" aria-label="Fluxo para consultar o histórico de viagens">
            <div><span>1</span><strong>Entrar</strong><small>E-mail e senha</small></div><b aria-hidden="true">→</b><div><span>2</span><strong>Dashboard</strong><small>Entender o resumo</small></div><b aria-hidden="true">→</b><div><span>3</span><strong>Viagens</strong><small>Escolher período</small></div><b aria-hidden="true">→</b><div><span>4</span><strong>Consultar</strong><small>Ver veículo, distância e score</small></div>
          </div>
          <div className="ux-grid-two">
            <article className="ux-card"><span className="ux-label">CENÁRIO DE USO / STORYBOARD TEXTUAL</span><h3>“Preciso verificar uma viagem”</h3><ol><li>O gestor acessa o endereço do SafeCar e identifica o formulário de entrada.</li><li>Após o login, encontra a opção <strong>Dashboard</strong> na navegação.</li><li>Seleciona <strong>Viagens</strong>, ajusta o período e consulta os registros disponíveis.</li><li>Se não há registros, recebe uma mensagem de estado vazio, sem números inventados.</li></ol></article>
            <article className="ux-card"><span className="ux-label">ARQUITETURA DA INFORMAÇÃO</span><h3>Estrutura simples e previsível</h3><div className="ux-tree"><strong>SafeCar Fleet</strong><span>├─ Login / Cadastro</span><span>├─ Dashboard</span><span>├─ Visão geral</span><span>├─ Veículos</span><span>├─ Viagens</span><span>├─ Alertas</span><span>└─ Sobre nós / Defesa UX/UI</span></div></article>
          </div>
          <h3 className="ux-subheading">Evolução de fidelidade: o que temos para demonstrar</h3>
          <div className="ux-fidelity">
            <div><span className="ux-fidelity-step">01 · BAIXA FIDELIDADE</span><div className="ux-wireframe"><div className="ux-wire-top"/><div className="ux-wire-side"/><div className="ux-wire-cards"><i/><i/><i/></div><div className="ux-wire-chart"/></div><strong>Wireframe esquemático</strong><p>Esquema de arquitetura visual que ajuda a explicar o agrupamento dos conteúdos e a navegação.</p></div>
            <div><span className="ux-fidelity-step">02 · ALTA FIDELIDADE</span><div className="ux-hi-fi"><div className="ux-fi-top">SafeCar Fleet <span>●</span></div><div className="ux-fi-cards"><i/><i/><i/></div><div className="ux-fi-chart"><i/><i/><i/><i/><i/></div></div><strong>Interface implementada</strong><p>Representação do painel Web atual, com identidade visual, indicadores, menu, hierarquia e feedback.</p></div>
          </div>
          <div className="ux-figma-evidence" aria-labelledby="figma-evidence-title">
            <div className="ux-figma-intro">
              <span className="ux-label">EVIDÊNCIAS REAIS DO GRUPO · FIGMA</span>
              <h3 id="figma-evidence-title">Protótipos de alta fidelidade do início do projeto</h3>
              <p>As capturas do Figma registram o estudo visual inicial do SafeCar: fluxos comuns de apresentação, cadastro e login, além das telas destinadas ao usuário. Elas demonstram o trabalho de concepção da interface antes das versões atuais do aplicativo e do dashboard Web.</p>
            </div>
            <div className="ux-figma-gallery">
              <figure className="ux-figma-figure">
                <a href="/evidencias/figma-tela-inicial.webp" target="_blank" rel="noopener noreferrer" aria-label="Abrir captura ampliada do Figma com telas iniciais do SafeCar">
                  <img src="/evidencias/figma-tela-inicial.webp" alt="Captura do Figma: tela inicial do SafeCar, três telas de apresentação, seleção/cadastro de perfil e telas de login para usuário e assistente." loading="lazy" width="1401" height="556"/>
                </a>
                <figcaption><strong>01 — Telas iniciais e comuns</strong><span>Splash, apresentação, cadastro e autenticação. A sequência demonstra como o grupo introduziu o produto e organizou os primeiros passos do usuário.</span><small>Clique na imagem para ampliar.</small></figcaption>
              </figure>
              <figure className="ux-figma-figure">
                <a href="/evidencias/figma-telas-usuario.webp" target="_blank" rel="noopener noreferrer" aria-label="Abrir captura ampliada do Figma com telas de usuário do SafeCar">
                  <img src="/evidencias/figma-telas-usuario.webp" alt="Captura do Figma: telas de início do usuário, veículos, notificações, histórico de eventos e chat do SafeCar." loading="lazy" width="1155" height="540"/>
                </a>
                <figcaption><strong>02 — Telas do usuário</strong><span>Início, veículos, notificações, histórico de eventos e chat. Os protótipos mostram a separação de áreas e o uso de cartões, botões e navegação inferior.</span><small>Clique na imagem para ampliar.</small></figcaption>
              </figure>
            </div>
            
          </div>
          <h3 className="ux-subheading">Princípios de Norman aplicados ao Dashboard</h3>
          <div className="ux-principles norman"><div><span>◉</span><strong>Visibilidade</strong><small>Menu explícito e indicadores reconhecíveis de imediato.</small></div><div><span>✓</span><strong>Feedback</strong><small>Carregamento, mensagens de erro e estados vazios.</small></div><div><span>↔</span><strong>Mapeamento</strong><small>O botão “Viagens” abre o histórico, não uma área inesperada.</small></div><div><span>↗</span><strong>Affordance</strong><small>Botões, links, campos e seletores evidenciam suas ações.</small></div></div>
        </section>

        <section className="ux-section" id="validacao" aria-labelledby="validacao-title">
          <div className="ux-section-heading"><span className="ux-kicker">BLOCO 04 / 04</span><h2 id="validacao-title">Avaliação e validação</h2><p>Comparamos decisões de interface, registramos melhorias realizadas e documentamos um protocolo de testes cruzados com métricas reproduzíveis.</p></div>
          <h3 className="ux-subheading">Auditoria: problemas identificados e soluções</h3>
          <div className="ux-comparison"><div className="ux-before"><span className="ux-compare-tag">ANTES · EVOLUÇÃO DO PROJETO</span><h3>Dashboard com informações demonstrativas</h3><p>Uma versão inicial da Web apresentava veículos e indicadores fictícios para demonstrar o layout. Isso criava risco de confundir demonstração visual com informações reais.</p><strong>Heurística relacionada</strong><small>Visibilidade do estado do sistema e correspondência com o mundo real (Nielsen).</small></div><div className="ux-after"><span className="ux-compare-tag">DEPOIS · IMPLEMENTAÇÃO ATUAL</span><h3>Dados vinculados ao usuário</h3><p>A versão posterior passou a exigir autenticação e a consultar coleções autorizadas do Firestore, mostrando estados vazios em vez de fabricar registros.</p><strong>Benefício para UX</strong><small>Mais transparência sobre a origem da informação e menor chance de interpretação equivocada.</small></div></div>
          <div className="ux-comparison"><div className="ux-before"><span className="ux-compare-tag">ANTES · NAVEGAÇÃO</span><h3>Nome da área pouco explícito</h3><p>O painel inicial não apresentava uma aba com o nome “Dashboard”; a navegação usava apenas “Visão geral”, que podia não corresponder à expectativa do usuário.</p><strong>Heurística relacionada</strong><small>Consistência, reconhecimento e correspondência com os modelos mentais.</small></div><div className="ux-after"><span className="ux-compare-tag">DEPOIS · MELHORIA</span><h3>Aba “Dashboard” identificável</h3><p>Incluímos uma opção de navegação nomeada explicitamente “Dashboard”, mantendo acesso às demais áreas de informação.</p><strong>Benefício para UX</strong><small>Reduz a busca visual e facilita encontrar o painel principal.</small></div></div>
          <div className="ux-callout"><strong>Sem dark patterns</strong><p>Nosso direcionamento de projeto é usar rótulos claros, botões que descrevam sua ação e informações verídicas. Cadastro não atribui permissões administrativas ocultas, o acesso a empresas exige autorização e o painel não deve sugerir monitoramento em tempo real quando esse recurso não existe.</p></div>

          <h3 className="ux-subheading">Relatório de avaliação da experiência</h3>
          <p>O trabalho consolidou os fluxos do SafeCar, a revisão heurística e um protocolo de testes cruzados. As tabelas a seguir apresentam um <strong>ensaio metodológico com dados simulados</strong>, útil para demonstrar o cálculo dos indicadores e orientar a coleta com participantes.</p>
          <div className="ux-report-metrics" aria-label="Indicadores do exemplo demonstrativo">
            <div><strong>05</strong><span>Perfis fictícios</span></div>
            <div><strong>20</strong><span>Execuções simuladas</span></div>
            <div><strong>95%</strong><span>Taxa de sucesso ilustrativa</span></div>
            <div><strong>30 s</strong><span>Tempo mediano ilustrativo</span></div>
          </div>
          <div className="ux-table-wrap"><table className="ux-table"><thead><tr><th>Participante (simulado)</th><th>Login + Dashboard</th><th>Veículos</th><th>Viagens</th><th>Alertas</th><th>Erros</th></tr></thead><tbody>
            <tr><td>P01</td><td>22 s</td><td>14 s</td><td>36 s</td><td>28 s</td><td>1</td></tr>
            <tr><td>P02</td><td>31 s</td><td>18 s</td><td>44 s</td><td>35 s</td><td>1</td></tr>
            <tr><td>P03</td><td>27 s</td><td>16 s</td><td>39 s</td><td>32 s</td><td>1</td></tr>
            <tr><td>P04</td><td>35 s</td><td>19 s</td><td>47 s</td><td>41 s</td><td>2</td></tr>
            <tr><td>P05</td><td>24 s</td><td>15 s</td><td>33 s</td><td>29 s</td><td>0</td></tr>
          </tbody></table></div>
          <p className="ux-method-note"><strong>Como calcular:</strong> neste exemplo, 19 das 20 tarefas foram concluídas (95% de sucesso); houve 5 erros em 20 execuções e a mediana dos tempos foi de 30 segundos. São números sintéticos para demonstrar a metodologia, não medições de estudantes ou clientes reais.</p>
          <div className="ux-grid-two">
            <article className="ux-card"><h3>Protocolo de testes cruzados</h3><ol>
              <li>Solicitar que a pessoa localize a tela de login e o Dashboard.</li>
              <li>Pedir que encontre um veículo por nome ou placa.</li>
              <li>Solicitar que abra o histórico e consulte uma viagem.</li>
              <li>Pedir que localize uma ocorrência em Alertas.</li>
            </ol><p>Em cada tarefa, registrar tempo, conclusão, quantidade de erros, necessidade de ajuda e comentários. As fichas de teste são anonimizadas por participante.</p></article>
            <article className="ux-card"><h3>Critérios de qualidade</h3><ul>
              <li><strong>Eficácia:</strong> proporção de tarefas concluídas corretamente.</li>
              <li><strong>Eficiência:</strong> mediana de tempo por tarefa.</li>
              <li><strong>Erros:</strong> quantidade e natureza dos desvios de navegação.</li>
              <li><strong>Comunicabilidade:</strong> compreensão dos rótulos, estados e mensagens.</li>
            </ul><p>As métricas permitem comparar versões da interface, quando aplicadas em testes observados nas mesmas condições.</p></article>
          </div>
          <h3 className="ux-subheading">Evidências do protótipo em funcionamento</h3>
          <p>Os registros fotográficos mostram o aplicativo e a montagem física utilizados no desenvolvimento do SafeCar. As imagens foram organizadas por etapa para documentar a integração entre interface, dispositivo e leitura do GPS.</p>
          <div className="ux-hardware-gallery">
            <figure className="ux-hardware-card"><a href="/evidencias/prototipo-app.webp" target="_blank" rel="noopener noreferrer" aria-label="Ampliar captura da conexão com o ESP32 no aplicativo"><img src="/evidencias/prototipo-app.webp" width="738" height="1600" loading="lazy" alt="Tela do SafeCar no celular com conexão do protótipo ESP32 e cartões de estados automotivos"/></a><figcaption><strong>01 — Aplicativo Flutter</strong><span>Painel de conexão do ESP32, modo de simulação e leitura do endereço local do protótipo.</span></figcaption></figure>
            <figure className="ux-hardware-card"><a href="/evidencias/prototipo-veiculo.webp" target="_blank" rel="noopener noreferrer" aria-label="Ampliar fotografia do protótipo instalado no veículo"><img src="/evidencias/prototipo-veiculo.webp" width="739" height="1600" loading="lazy" alt="Protoboard com ESP32, fiação e módulo GPS apoiados no interior de um veículo de teste"/></a><figcaption><strong>02 — Montagem física</strong><span>Protótipo com ESP32 e GPS conectado à alimentação, testado no ambiente de um veículo.</span></figcaption></figure>
            <figure className="ux-hardware-card"><a href="/evidencias/prototipo-monitor-gps.webp" target="_blank" rel="noopener noreferrer" aria-label="Ampliar captura do monitor serial do GPS"><img src="/evidencias/prototipo-monitor-gps.webp" width="690" height="270" loading="lazy" alt="Monitor serial exibindo GPS válido, sete satélites e registro de velocidade; informações de localização ocultadas"/></a><figcaption><strong>03 — Diagnóstico do GPS</strong><span>Monitor serial registrando sinal GPS válido e sete satélites na captura, com dados de conexão sensíveis ocultados.</span></figcaption></figure>
          </div>
          <h3 className="ux-subheading">Auditoria e melhorias priorizadas</h3>
          <div className="ux-grid-two">
            <article className="ux-card"><h3>Melhorias aplicadas</h3><ul><li>Identificação explícita da aba Dashboard.</li><li>Autenticação e visualização apenas de coleções autorizadas do Firestore.</li><li>Estados vazios em vez de exibir registros fictícios como reais.</li><li>Confirmação antes da exclusão de uma viagem.</li><li>Feedback de conexão com o protótipo no aplicativo.</li></ul></article>
            <article className="ux-card"><h3>Ações prioritárias de UX</h3><ul><li><strong>Alta:</strong> validar compreensão dos alertas, do estado de conexão e das mensagens de erro.</li><li><strong>Alta:</strong> revisar contraste, teclado e foco conforme WCAG.</li><li><strong>Média:</strong> comparar o fluxo de consulta em desktop e celular.</li><li><strong>Média:</strong> usar os registros observados para refinar textos e navegação.</li></ul></article>
          </div>
          <div className="ux-report-link"><div><strong>Relatório técnico e planilha de métricas</strong><p>A documentação registra a evolução do projeto, as heurísticas adotadas, o protocolo de testes e a base demonstrativa para cálculo das métricas.</p></div><a href="https://github.com/CauaCarvalhoo/safecar-app/blob/feature/safecar-fleet-obd/docs/ux/RELATORIO_UX_SAFECAR.md" target="_blank" rel="noopener noreferrer">Ler relatório completo ↗</a></div>

        </section>

        <section className="ux-conclusion" aria-labelledby="conclusao-title"><span className="ux-eyebrow">CONCLUSÃO DA DEFESA</span><h2 id="conclusao-title">Uma interface útil é aquela que torna a próxima ação evidente.</h2><p>O SafeCar Fleet evoluiu de uma demonstração de interface para uma Web com autenticação, informação vinculada à conta e navegação mais explícita. Nosso próximo compromisso é validar essas escolhas com pessoas reais e usar métricas para orientar as correções finais.</p><div className="ux-conclusion-links"><Link href="/" className="ux-primary-link">Abrir SafeCar Fleet ↗</Link><a href="#conteudo" className="ux-secondary-link">Voltar ao início ↑</a></div></section>
        <footer className="ux-footer"><span>© 2026 SafeCar Fleet · Projeto Integrador</span><span>Defesa de UX/UI · IHC</span><a href="https://www.w3.org/TR/WCAG22/" target="_blank" rel="noopener noreferrer">Referência: WCAG 2.2 — W3C ↗</a></footer>
      </div>
    </main>
  </div>;
}
