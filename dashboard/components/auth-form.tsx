"use client";

import { FormEvent, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { createUserWithEmailAndPassword, sendPasswordResetEmail, signInWithEmailAndPassword, updateProfile } from "firebase/auth";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { auth, db } from "../lib/firebase";

type Mode = "login" | "register" | "reset";
const messages: Record<string,string> = {
  "auth/email-already-in-use": "Este e-mail já está cadastrado.",
  "auth/invalid-email": "Informe um e-mail válido.",
  "auth/invalid-credential": "E-mail ou senha incorretos.",
  "auth/weak-password": "Escolha uma senha mais forte.",
  "auth/too-many-requests": "Muitas tentativas. Tente novamente mais tarde.",
  "auth/network-request-failed": "Falha de conexão. Verifique sua internet.",
  "auth/unauthorized-domain": "Domínio não autorizado no Firebase. Adicione o domínio da Vercel em Authentication > Settings > Authorized domains.",
};

export function AuthForm() {
  const [mode,setMode] = useState<Mode>("login");
  const [name,setName] = useState("");
  const [email,setEmail] = useState("");
  const [password,setPassword] = useState("");
  const [confirm,setConfirm] = useState("");
  const [busy,setBusy] = useState(false);
  const [message,setMessage] = useState("");
  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault(); setMessage("");
    if (mode === "register" && password !== confirm) {setMessage("As senhas não coincidem.");return;}
    if (mode === "register" && name.trim().length < 2) {setMessage("Informe seu nome.");return;}
    setBusy(true);
    try {
      if(mode==="reset"){ await sendPasswordResetEmail(auth,email.trim());setMessage("Enviamos instruções de recuperação para seu e-mail, caso exista uma conta cadastrada."); }
      else if(mode==="login"){await signInWithEmailAndPassword(auth,email.trim(),password);}
      else {
        const credential = await createUserWithEmailAndPassword(auth,email.trim(),password);
        await updateProfile(credential.user,{displayName:name.trim()});
        try {
          await setDoc(doc(db,"users",credential.user.uid),{uid:credential.user.uid,name:name.trim(),email:email.trim(),profileType:"usuario",createdAt:serverTimestamp()});
        } catch { setMessage("Conta criada, mas o perfil não foi salvo. Entre em contato com o suporte."); }
      }
    } catch (error) { const code=typeof error === "object" && error && "code" in error ? String(error.code):"";setMessage(messages[code] || "Não foi possível concluir a operação. Tente novamente."); }
    finally {setBusy(false);}
  };
  return <div className="auth-shell"><div className="auth-aside"><div className="auth-brand"><Image className="auth-logo" src="/icon.svg" width={47} height={47} alt="Carro e escudo SafeCar" /><strong>SafeCar <span>Fleet</span></strong></div><div><span className="eyebrow">CENTRAL DE OPERAÇÕES</span><h1>Sua frota sob controle.<br/><em>Em um só lugar.</em></h1><p>Entre com a mesma conta do aplicativo SafeCar para acompanhar seus veículos, viagens e alertas.</p><div className="auth-feature">◈ &nbsp; Acesso autenticado com Firebase</div><div className="auth-feature">◎ &nbsp; Dados vinculados à sua conta</div><div className="auth-feature">⌁ &nbsp; Identidade visual integrada ao aplicativo</div></div><span className="auth-aside-foot">SafeCar Fleet · Engenharia de Computação</span></div><div className="auth-content"><div className="auth-card"><div className="auth-mobile-brand">SafeCar Fleet</div><span className="eyebrow">BEM-VINDO AO SAFECAR</span><h2>{mode==="login"?"Acesse sua conta":mode==="register"?"Criar sua conta":"Recuperar acesso"}</h2><p className="auth-subtitle">{mode==="login"?"Acesse seus dados com segurança.":mode==="register"?"Use esta conta também no aplicativo Flutter.":"Enviaremos as instruções para seu e-mail."}</p><form onSubmit={submit}>{mode==="register"&&<label>Nome completo<input autoComplete="name" value={name} onChange={e=>setName(e.target.value)} required minLength={2} maxLength={100} placeholder="Seu nome"/></label>}<label>E-mail<input type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} required placeholder="voce@exemplo.com"/></label>{mode!=="reset"&&<label>Senha<input type="password" autoComplete={mode==="login"?"current-password":"new-password"} value={password} onChange={e=>setPassword(e.target.value)} required minLength={6} placeholder="Sua senha"/></label>}{mode==="register"&&<label>Confirmar senha<input type="password" autoComplete="new-password" value={confirm} onChange={e=>setConfirm(e.target.value)} required minLength={6} placeholder="Repita a senha"/></label>}{message&&<p role="alert" className="form-message">{message}</p>}<button type="submit" className="primary-action" disabled={busy}>{busy?"Aguarde...":mode==="login"?"Entrar no painel":mode==="register"?"Criar conta":"Enviar instruções"} →</button></form><div className="auth-links">{mode==="login"?<><button onClick={()=>{setMode("register");setMessage("");}}>Criar nova conta</button><button onClick={()=>{setMode("reset");setMessage("");}}>Esqueci minha senha</button></>:<button onClick={()=>{setMode("login");setMessage("");}}>← Voltar ao login</button>}</div><Link href="/sobre-nos" className="about-login-link">ⓘ &nbsp; Sobre nós · Conheça o projeto e a defesa UX/UI ↗</Link><p className="auth-note">Se você já usa o aplicativo SafeCar, entre com o mesmo e-mail e senha. O cadastro Web não concede acesso administrativo a outras empresas.</p></div></div></div>;
}
