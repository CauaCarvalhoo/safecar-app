"use client";

import { useMemo, useState } from "react";

type View = "overview" | "vehicles" | "drivers" | "alerts" | "reports";
type Period = "7" | "30" | "90";

type Vehicle = { plate: string; name: string; driver: string; status: "Em rota" | "Parado" | "Offline"; score: number; distance: number };
const vehicles: Vehicle[] = [
  {plate:"ABC-1D23",name:"Fiorino 01",driver:"João Silva",status:"Em rota",score:94,distance:483},
  {plate:"EFG-4H56",name:"Strada 02",driver:"Marcos Oliveira",status:"Parado",score:97,distance:316},
  {plate:"IJK-7L89",name:"Saveiro 03",driver:"Pedro Santos",status:"Em rota",score:86,distance:428},
  {plate:"MNO-1P23",name:"Master 04",driver:"Rafael Lima",status:"Em rota",score:69,distance:602},
  {plate:"QRS-4T56",name:"Sprinter 05",driver:"Gabriel Souza",status:"Offline",score:80,distance:377},
];
const events = [
  {type:"Excesso de velocidade",vehicle:"Master 04",time:"Hoje · 14:32",level:"Crítico"},
  {type:"Frenagem brusca",vehicle:"Saveiro 03",time:"Hoje · 11:08",level:"Atenção"},
  {type:"Dispositivo offline",vehicle:"Sprinter 05",time:"Hoje · 09:41",level:"Informativo"},
  {type:"Aceleração brusca",vehicle:"Fiorino 01",time:"Ontem · 17:13",level:"Atenção"},
];
const weekly=[42,68,55,79,72,94,83];
const menu: { id: View; icon: string; label: string }[] = [
  {id:"overview",icon:"▦",label:"Visão geral"},
  {id:"vehicles",icon:"▤",label:"Veículos"},
  {id:"drivers",icon:"♙",label:"Motoristas"},
  {id:"alerts",icon:"◇",label:"Alertas"},
  {id:"reports",icon:"▥",label:"Relatórios"},
];
const viewTitle: Record<View,string> = {overview:"Visão geral",vehicles:"Veículos da frota",drivers:"Desempenho dos motoristas",alerts:"Central de alertas",reports:"Relatórios operacionais"};

export default function Dashboard() {
  const [view,setView] = useState<View>("overview");
  const [period,setPeriod] = useState<Period>("7");
  const [search,setSearch] = useState("");
  const [mobileMenu,setMobileMenu] = useState(false);
  const factor=Number(period)/7;
  const distance=vehicles.reduce((s,v)=>s+v.distance,0);
  const avgScore=Math.round(vehicles.reduce((s,v)=>s+v.score,0)/vehicles.length);
  const filtered=useMemo(()=>vehicles.filter(v=>(v.name+" "+v.plate+" "+v.driver).toLowerCase().includes(search.toLowerCase())),[search]);
  const totals={active:vehicles.filter(v=>v.status==="Em rota").length,stopped:vehicles.filter(v=>v.status==="Parado").length,offline:vehicles.filter(v=>v.status==="Offline").length};

  const vehicleTable = <div className="table-wrap"><table><thead><tr><th>Veículo</th><th>Motorista</th><th>Situação</th><th>Score</th><th>Distância</th></tr></thead><tbody>{filtered.map(v=><tr key={v.plate}><td><div className="car-cell"><span className="car-icon">▰</span><span><strong>{v.name}</strong><small>{v.plate}</small></span></div></td><td>{v.driver}</td><td><span className={"status "+(v.status==="Em rota"?"moving":v.status==="Parado"?"stopped":"offline")}><i/>{v.status}</span></td><td><span className={"score "+(v.score<75?"low":"")}>{v.score}/100</span></td><td>{v.distance} km</td></tr>)}</tbody></table>{filtered.length===0&&<p className="empty">Nenhum veículo encontrado.</p>}</div>;
  return <div className="app-shell">
    <aside className={"sidebar "+(mobileMenu?"show":"")}>
      <div className="brand"><div className="brand-icon">S</div><div><strong>SafeCar<span> Fleet</span></strong><small>CENTRAL DE OPERAÇÕES</small></div></div>
      <div className="workspace-label">WORKSPACE</div>
      <div className="workspace"><span className="workspace-icon">SF</span><div><strong>Minha frota</strong><small>Ambiente demonstrativo</small></div><span className="chevron">⌄</span></div>
      <div className="menu-label">PRINCIPAL</div>
      <nav aria-label="Navegação principal">{menu.map(m=><button type="button" key={m.id} className={"nav-link "+(view===m.id?"selected":"")} onClick={()=>{setView(m.id);setMobileMenu(false);}}><span className="nav-icon">{m.icon}</span>{m.label}{m.id==="alerts"&&<span className="nav-count">4</span>}</button>)}</nav>
      <div className="sidebar-bottom"><div className="sidebar-help"><div className="help-icon">↗</div><strong>Plataforma em evolução</strong><p>Dashboard inicial com dados fictícios. Integração segura ao Firebase será adicionada nas próximas entregas.</p></div><div className="sidebar-footer"><span className="avatar">SC</span><span><strong>Modo demonstração</strong><small>SafeCar Fleet · v0.1</small></span></div></div>
    </aside>
    {mobileMenu&&<button className="scrim" aria-label="Fechar menu" onClick={()=>setMobileMenu(false)}/>}
    <main className="main">
      <header className="topbar"><div className="top-left"><button className="mobile-toggle" aria-label="Abrir menu" onClick={()=>setMobileMenu(true)}>☰</button><span>Área administrativa</span><span className="crumb">/</span><strong>{viewTitle[view]}</strong></div><div className="top-right"><span className="demo-dot"/> Dados simulados <div className="top-avatar">SC</div></div></header>
      <div className="content">
        <div className="page-head"><div><span className="eyebrow">SAFECAR INTELLIGENCE</span><h1>{viewTitle[view]}</h1><p>{view==="overview"?"Acompanhe a operação da sua frota em um só lugar.":view==="reports"?"Indicadores consolidados para apoiar suas decisões.":"Informações organizadas para o acompanhamento operacional."}</p></div><div className="head-actions"><span className="demo-tag"><span/> Ambiente demonstrativo</span><select aria-label="Selecionar período" value={period} onChange={e=>setPeriod(e.target.value as Period)}><option value="7">Últimos 7 dias</option><option value="30">Últimos 30 dias</option><option value="90">Últimos 90 dias</option></select></div></div>
        <div className="notice"><span>ⓘ</span><p><strong>Prévia do dashboard.</strong> Os indicadores, nomes e eventos desta página são fictícios para demonstração de interface. Ainda não existe conexão com os dados reais da frota.</p></div>
        {(view==="overview"||view==="reports")&&<>
        <section className="metrics" aria-label="Indicadores principais">
          <div className="metric-card"><div className="metric-top"><span>Total de veículos</span><span className="metric-symbol blue">▰</span></div><div className="metric-value">{vehicles.length.toString().padStart(2,"0")}</div><div className="metric-foot">Veículos cadastrados</div></div>
          <div className="metric-card"><div className="metric-top"><span>Veículos em rota</span><span className="metric-symbol green">↗</span></div><div className="metric-value">{totals.active.toString().padStart(2,"0")} <span className="metric-percent">{Math.round(totals.active/vehicles.length*100)}%</span></div><div className="metric-foot"><span className="green-dot"/> Operando normalmente</div></div>
          <div className="metric-card"><div className="metric-top"><span>Distância no período</span><span className="metric-symbol purple">⌁</span></div><div className="metric-value">{Math.round(distance*factor).toLocaleString("pt-BR")} <span className="unit">km</span></div><div className="metric-foot">Estimativa ilustrativa · {period} dias</div></div>
          <div className="metric-card"><div className="metric-top"><span>Score de condução</span><span className="metric-symbol orange">✦</span></div><div className="metric-value">{avgScore}<span className="unit">/100</span></div><div className="metric-foot">Média dos motoristas</div></div>
        </section>
        <section className="charts"><div className="panel chart-panel"><div className="panel-header"><div><h2>Atividade da frota</h2><p>Distância percorrida por dia · dados demonstrativos</p></div><span className="pill blue-pill">↗ Tendência</span></div><div className="bar-chart"><div className="chart-grid"><span>100</span><span>75</span><span>50</span><span>25</span><span>0</span></div><div className="bars">{weekly.map((v,i)=><div className="bar-col" key={i}><div className="bar-bg"><div className={"bar "+(i===5?"highlight":"")} style={{height:(v)+"%"}} title={v+" km"} /></div><span>{["Seg","Ter","Qua","Qui","Sex","Sáb","Dom"][i]}</span></div>)}</div></div></div>
        <div className="panel status-panel"><div className="panel-header"><div><h2>Situação dos veículos</h2><p>Distribuição por status</p></div></div><div className="donut-wrap"><div className="donut" style={{background:`conic-gradient(#25c59a 0 ${totals.active/vehicles.length*100}%, #f3b95a 0 ${(totals.active+totals.stopped)/vehicles.length*100}%, #8290a9 0 100%)`}}><div className="donut-middle"><strong>{vehicles.length}</strong><span>veículos</span></div></div></div><div className="legend"><div><span><i className="legend-dot mint"/>Em rota</span><strong>{totals.active}</strong></div><div><span><i className="legend-dot yellow"/>Parados</span><strong>{totals.stopped}</strong></div><div><span><i className="legend-dot gray"/>Offline</span><strong>{totals.offline}</strong></div></div></div></section>
        </>}
        {(view==="overview"||view==="vehicles")&&<section className="panel fleet-panel"><div className="panel-header"><div><h2>Veículos da frota</h2><p>Visão operacional e pontuação dos condutores</p></div><button className="outline-button" onClick={()=>setView(view==="vehicles"?"overview":"vehicles")}>{view==="vehicles"?"Voltar à visão geral":"Ver todos →"}</button></div><div className="panel-tools"><label className="search"><span>⌕</span><input aria-label="Buscar veículo" placeholder="Buscar veículo, placa ou motorista" value={search} onChange={e=>setSearch(e.target.value)} /></label><span className="count">{filtered.length} veículos</span></div>{vehicleTable}</section>}
        {view==="drivers"&&<section className="panel fleet-panel"><div className="panel-header"><div><h2>Ranking de condução</h2><p>Pontuação experimental por motorista · dados fictícios</p></div></div><div className="driver-list">{[...vehicles].sort((a,b)=>b.score-a.score).map((v,i)=><div className="driver-row" key={v.plate}><span className="rank">{String(i+1).padStart(2,"0")}</span><div className="driver-info"><strong>{v.driver}</strong><small>{v.name}</small></div><div className="driver-progress"><span style={{width:v.score+"%"}} /></div><strong className={v.score<75?"danger-text":""}>{v.score}/100</strong></div>)}</div></section>}
        {(view==="overview"||view==="alerts")&&<section className="panel alerts-panel"><div className="panel-header"><div><h2>Últimas ocorrências</h2><p>Eventos operacionais simulados</p></div>{view==="overview"&&<button className="outline-button" onClick={()=>setView("alerts")}>Ver alertas →</button>}</div><div className="event-list">{events.map((ev,i)=><div className="event-row" key={i}><span className={"event-icon "+(ev.level==="Crítico"?"red":ev.level==="Atenção"?"amber":"neutral")}>{ev.level==="Informativo"?"i":"!"}</span><div className="event-desc"><strong>{ev.type}</strong><span>{ev.vehicle} · {ev.time}</span></div><span className={"severity "+(ev.level==="Crítico"?"sev-red":ev.level==="Atenção"?"sev-amber":"sev-gray")}>{ev.level}</span></div>)}</div></section>}
        <footer className="footer"><span>© 2026 SafeCar Fleet · Projeto acadêmico</span><span>Versão demonstrativa · Sem dados em tempo real</span></footer>
      </div>
    </main>
  </div>;
}
