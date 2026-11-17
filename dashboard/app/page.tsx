"use client";

import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import { onAuthStateChanged, signOut, type User } from "firebase/auth";
import { auth } from "../lib/firebase";
import { watchFleet, verifyAdminMembership, type FleetData, type FleetScope } from "../lib/firestore-data";
import { AuthForm } from "../components/auth-form";

type View = "dashboard" | "overview" | "vehicles" | "trips" | "alerts";
const navigation: {key:View;icon:string;label:string}[]=[
  {key:"dashboard",icon:"▦",label:"Dashboard"},
  {key:"overview",icon:"◫",label:"Visão geral"},
  {key:"vehicles",icon:"▤",label:"Veículos"},
  {key:"trips",icon:"⌁",label:"Viagens"},
  {key:"alerts",icon:"◇",label:"Alertas"},
];
const empty: FleetData={vehicles:[],trips:[],alerts:[]};
const formatNum=(value:number)=>value.toLocaleString("pt-BR",{maximumFractionDigits:1});
const formatDate=(value:Date|null)=>value?value.toLocaleString("pt-BR",{dateStyle:"short",timeStyle:"short"}):"Data não informada";

export default function Home() {
  const [user,setUser]=useState<User|null>(null);
  const [authReady,setAuthReady]=useState(false);
  const [view,setView]=useState<View>("dashboard");
  const [period,setPeriod]=useState("30");
  const [search,setSearch]=useState("");
  const [scope,setScope]=useState<FleetScope|null>(null);
  const [organizationId,setOrganizationId]=useState("");
  const [organizationError,setOrganizationError]=useState("");
  const [switching,setSwitching]=useState(false);
  const [fleet,setFleet]=useState<FleetData>(empty);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState("");
  const [mobileMenu,setMobileMenu]=useState(false);

  useEffect(()=>onAuthStateChanged(auth,u=>{
    setUser(u);setAuthReady(true);setScope(u?{kind:"personal",uid:u.uid,label:"Minha frota"}:null);setFleet(empty);setLoading(true);setError("");setOrganizationId("");
  }),[]);
  useEffect(()=>{
    if(!scope)return;
    setFleet(empty);setLoading(true);setError("");
    return watchFleet(scope,value=>{setFleet(value);setLoading(false);},reason=>{setError("Não foi possível consultar os dados: "+reason);setLoading(false);});
  },[scope]);

  const selectOrganization=async()=>{
    if(!user||!organizationId.trim())return;
    setSwitching(true);setOrganizationError("");
    try {
      const ok=await verifyAdminMembership(user.uid,organizationId.trim());
      if(!ok){setOrganizationError("Acesso negado. É necessário ser administrador ou proprietário ativo dessa organização.");return;}
      setScope({kind:"organization",id:organizationId.trim(),label:"Organização: "+organizationId.trim()});
    } catch {setOrganizationError("Não foi possível validar o acesso à empresa. Confira o identificador e suas permissões.");}
    finally{setSwitching(false);}
  };

  const filteredTrips=useMemo(()=>{
    const since=Date.now()-Number(period)*86400000;
    return fleet.trips.filter(t=>t.startedAt&&t.startedAt.getTime()>=since);
  },[fleet.trips,period]);
  const distance=filteredTrips.reduce((sum,t)=>sum+t.distanceKm,0);
  const scores=filteredTrips.map(t=>t.driverScore).filter((s):s is number=>s!==null);
  const averageScore=scores.length?Math.round(scores.reduce((a,b)=>a+b,0)/scores.length):null;
  const tripAlerts=filteredTrips.reduce((a,t)=>a+t.overspeedEvents+t.harshEvents,0);
  const vehicleRows=fleet.vehicles.filter(v=>[v.nickname,v.plate,v.brand,v.model].join(" ").toLowerCase().includes(search.toLowerCase())).sort((a,b)=>a.nickname.localeCompare(b.nickname));
  const tripRows=[...filteredTrips].sort((a,b)=>(b.startedAt?.getTime()||0)-(a.startedAt?.getTime()||0));
  const grouped=useMemo(()=>{
    const count=7, span=Number(period)/count;
    return Array.from({length:count},(_,i)=>{
      const to=Date.now()-(count-i-1)*span*86400000;
      const from=to-span*86400000;
      return {label:new Date(to).toLocaleDateString("pt-BR",{day:"2-digit",month:"2-digit"}),distance:filteredTrips.filter(t=>t.startedAt&&t.startedAt.getTime()>=from&&t.startedAt.getTime()<to).reduce((sum,t)=>sum+t.distanceKm,0)};
    });
  },[filteredTrips,period]);
  const peak=Math.max(1,...grouped.map(g=>g.distance));

  if(!authReady)return <div className="loading-screen"><span className="auth-logo">S</span><p>Carregando SafeCar Fleet...</p></div>;
  if(!user)return <AuthForm/>;

  return <div className="app-shell">
    <aside className={"sidebar "+(mobileMenu?"show":"")}>
      <div className="brand"><Image className="brand-icon" src="/icon.svg" width={40} height={40} alt="SafeCar Fleet: carro com escudo" /><div><strong>SafeCar<span> Fleet</span></strong><small>CENTRAL DE OPERAÇÕES</small></div></div>
      <div className="workspace-label">AMBIENTE</div>
      <div className="workspace"><Image className="workspace-icon" src="/icon.svg" width={35} height={35} alt="" /><div><strong>{scope?.label||"Minha frota"}</strong><small>Firebase Firestore</small></div></div>
      <div className="menu-label">PRINCIPAL</div>
      <nav aria-label="Navegação">{navigation.map(item=><button key={item.key} className={"nav-link "+(view===item.key?"selected":"")} onClick={()=>{setView(item.key);setMobileMenu(false);}}><span className="nav-icon">{item.icon}</span>{item.label}</button>)}</nav>
      <div className="sidebar-bottom"><a href="/sobre-nos" className="nav-link sidebar-about"><span className="nav-icon">ⓘ</span>Sobre nós · Defesa UX/UI</a><div className="sidebar-help"><strong>Integração com o aplicativo</strong><p>Os veículos e as viagens exibidos aqui vêm do mesmo Firebase utilizado no SafeCar Flutter. Sem telemetria simulada.</p></div><div className="sidebar-footer"><span className="avatar">{(user.displayName||user.email||"S").slice(0,2).toUpperCase()}</span><span><strong>{user.displayName||"Conta SafeCar"}</strong><small>{user.email}</small></span></div><button className="logout" onClick={()=>signOut(auth)}>Sair da conta →</button></div>
    </aside>
    {mobileMenu&&<button className="scrim" aria-label="Fechar menu" onClick={()=>setMobileMenu(false)}/>}
    <main className="main">
      <header className="topbar"><div className="top-left"><button className="mobile-toggle" aria-label="Abrir menu" onClick={()=>setMobileMenu(true)}>☰</button>SafeCar Fleet <span className="crumb">/</span><strong>{navigation.find(x=>x.key===view)?.label}</strong></div><div className="top-right"><span className="demo-dot"/><span>Conectado ao Firebase</span><Image className="top-avatar" src="/icon.svg" width={35} height={35} alt="SafeCar Fleet" /></div></header>
      <div className="content">
        <div className="page-head"><div><span className="eyebrow">SAFECAR INTELLIGENCE</span><h1>{navigation.find(x=>x.key===view)?.label}</h1><p>Acompanhamento da sua frota com os dados armazenados no Firestore.</p></div><div className="head-actions"><span className="live-tag"><span/> Dados reais · sem localização ao vivo</span><select aria-label="Período" value={period} onChange={e=>setPeriod(e.target.value)}><option value="7">Últimos 7 dias</option><option value="30">Últimos 30 dias</option><option value="90">Últimos 90 dias</option></select></div></div>
        <section className="scope-panel"><div><h2>Fonte de dados: {scope?.label}</h2><p>{scope?.kind==="personal"?"Somente os veículos e viagens associados à sua conta.":"Você está lendo dados da organização com permissão administrativa."}</p></div><div className="scope-controls"><input aria-label="Identificador da organização" placeholder="ID da organização (opcional)" value={organizationId} onChange={e=>setOrganizationId(e.target.value)} /><button onClick={selectOrganization} disabled={switching||!organizationId.trim()}>{switching?"Validando...":"Acessar organização"}</button>{scope?.kind==="organization"&&<button className="outline-button" onClick={()=>{setScope({kind:"personal",uid:user.uid,label:"Minha frota"});setOrganizationError("");}}>Minha frota</button>}</div>{organizationError&&<p role="alert" className="scope-error">{organizationError}</p>}</section>
        {error&&<div className="notice error-notice" role="alert">{error}</div>}
        {loading?<div className="panel center-state">Carregando dados autorizados...</div>:<>
          {(view==="dashboard"||view==="overview")&&<>
            <section className="metrics" aria-label="Indicadores"><div className="metric-card"><div className="metric-top">Veículos cadastrados <span className="metric-symbol green">▰</span></div><div className="metric-value">{fleet.vehicles.length}</div><div className="metric-foot">Cadastro no Firestore</div></div><div className="metric-card"><div className="metric-top">Viagens no período <span className="metric-symbol green">⌁</span></div><div className="metric-value">{filteredTrips.length}</div><div className="metric-foot">Viagens registradas</div></div><div className="metric-card"><div className="metric-top">Distância registrada <span className="metric-symbol green">↗</span></div><div className="metric-value">{formatNum(distance)} <span className="unit">km</span></div><div className="metric-foot">Soma dos registros no período</div></div><div className="metric-card"><div className="metric-top">Score médio <span className="metric-symbol green">✦</span></div><div className="metric-value">{averageScore??"—"} <span className="unit">{averageScore===null?"Sem dados":"/100"}</span></div><div className="metric-foot">Pontuação registrada nas viagens</div></div></section>
            <section className="charts"><div className="panel chart-panel"><div className="panel-header"><div><h2>Distância das viagens</h2><p>Distribuição de registros no período selecionado</p></div></div>{filteredTrips.length?<div className="bar-chart"><div className="chart-grid"><span>{formatNum(peak)}</span><span>{formatNum(peak/2)}</span><span>0</span></div><div className="bars">{grouped.map((g,i)=><div className="bar-col" key={i}><div className="bar-bg"><div className="bar" style={{height:g.distance?Math.max(3,g.distance/peak*100)+"%":"0%"}} title={formatNum(g.distance)+" km"}/></div><span>{g.label}</span></div>)}</div></div>:<div className="center-state">Nenhuma viagem registrada nesse período.</div>}</div><div className="panel status-panel"><div className="panel-header"><div><h2>Indicadores registrados</h2><p>Eventos das viagens, não telemetria ao vivo</p></div></div><div className="summary-stat"><strong>{tripAlerts}</strong><span>Eventos de direção nas viagens</span></div><div className="legend"><div><span>Veículos cadastrados</span><strong>{fleet.vehicles.length}</strong></div><div><span>Viagens registradas</span><strong>{filteredTrips.length}</strong></div><div><span>Alertas armazenados</span><strong>{fleet.alerts.length}</strong></div></div><p className="muted-note">O app ainda utiliza dados simulados em partes da telemetria; esses scores não representam medição certificada.</p></div></section>
          </>}
          {(view==="dashboard"||view==="overview"||view==="vehicles")&&<section className="panel fleet-panel"><div className="panel-header"><div><h2>Veículos cadastrados</h2><p>Dados disponíveis na coleção de veículos</p></div>{(view==="dashboard"||view==="overview")&&<button className="outline-button" onClick={()=>setView("vehicles")}>Ver todos →</button>}</div><div className="panel-tools"><label className="search">⌕ <input aria-label="Buscar veículo" placeholder="Pesquisar placa, veículo ou marca" value={search} onChange={e=>setSearch(e.target.value)}/></label><span className="count">{vehicleRows.length} veículos</span></div><div className="table-wrap"><table><thead><tr><th>Veículo</th><th>Marca / modelo</th><th>Placa</th><th>Monitoramento</th></tr></thead><tbody>{vehicleRows.map(v=><tr key={v.id}><td><strong>{v.nickname}</strong></td><td>{[v.brand,v.model].filter(Boolean).join(" ")||"Não informado"}</td><td>{v.plate||"Não informada"}</td><td><span className="status offline">Não disponível ao vivo</span></td></tr>)}</tbody></table>{!vehicleRows.length&&<p className="empty">Nenhum veículo cadastrado para esta conta ou organização.</p>}</div></section>}
          {(view==="dashboard"||view==="overview"||view==="trips")&&<section className="panel fleet-panel"><div className="panel-header"><div><h2>Histórico de viagens</h2><p>Registros reais do Firestore · últimos {period} dias</p></div>{view==="overview"&&<button className="outline-button" onClick={()=>setView("trips")}>Ver viagens →</button>}</div><div className="table-wrap"><table><thead><tr><th>Veículo</th><th>Início</th><th>Distância</th><th>Score registrado</th></tr></thead><tbody>{tripRows.slice(0,(view==="dashboard"||view==="overview")?5:100).map(t=><tr key={t.id}><td>{t.vehicleName||fleet.vehicles.find(v=>v.id===t.vehicleId)?.nickname||"Veículo não identificado"}</td><td>{formatDate(t.startedAt)}</td><td>{formatNum(t.distanceKm)} km</td><td>{t.driverScore??"Não informado"}</td></tr>)}</tbody></table>{!tripRows.length&&<p className="empty">Nenhuma viagem registrada no período selecionado.</p>}</div></section>}
          {(view==="dashboard"||view==="overview"||view==="alerts")&&<section className="panel alerts-panel"><div className="panel-header"><div><h2>Alertas registrados</h2><p>Ocorrências salvas no Firestore</p></div>{view==="overview"&&<button className="outline-button" onClick={()=>setView("alerts")}>Ver alertas →</button>}</div><div className="event-list">{fleet.alerts.map(a=><div className="event-row" key={a.id}><span className="event-icon neutral">!</span><div className="event-desc"><strong>{a.title}</strong><span>{[a.vehicleName,formatDate(a.createdAt)].filter(Boolean).join(" · ")}</span></div></div>)}{fleet.alerts.length===0&&<p className="empty">Nenhum alerta armazenado.</p>}</div></section>}
        </>}
        <footer className="footer"><span>© 2026 SafeCar Fleet · Projeto acadêmico</span><span>Autenticação Firebase · Consultas sujeitas às regras do Firestore</span></footer>
      </div>
    </main>
  </div>;
}
