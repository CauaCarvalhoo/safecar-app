// SafeCar Fleet — banco de demonstração LOCAL (Firebase Firestore Emulator).
// Executa apenas quando FIRESTORE_EMULATOR_HOST está configurado.
// NÃO utiliza produção; os dados são fictícios e identificados como demonstração.
import { readFileSync } from "node:fs";
import { initializeTestEnvironment } from "@firebase/rules-unit-testing";

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulator) {
  throw new Error("Execução bloqueada: inicie o Firestore Emulator antes de popular dados.");
}
const [host, portString] = emulator.split(":");
if (!host || !portString) throw new Error("FIRESTORE_EMULATOR_HOST inválido.");
const projectId = "demo-safecar-ux";
const env = await initializeTestEnvironment({
  projectId,
  firestore: { host, port: Number(portString), rules: readFileSync("firestore.rules", "utf-8") },
});
try {
  const now = Date.now();
  const minutesAgo = (n) => new Date(now - n * 60000);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const set = (path, data) => db.doc(path).set({...data, demo: true});
    const orgs = [
      { id: "empresa-alfa-demo", name: "Transportes Alfa — DEMO", owner: "gestor-alfa-demo" },
      { id: "empresa-beta-demo", name: "Logística Beta — DEMO", owner: "gestor-beta-demo" },
    ];
    for (const org of orgs) {
      await set(`organizations/${org.id}`, {name: org.name, demoOnly: true});
      await set(`organizations/${org.id}/members/${org.owner}`, {role:"owner",active:true});
    }
    await set("organizations/empresa-alfa-demo/vehicles/carro-01", {nickname:"Fiorino — demonstração",plate:"DEMO-001",brand:"Fiat",model:"Fiorino"});
    await set("organizations/empresa-alfa-demo/vehicles/carro-02", {nickname:"Strada — demonstração",plate:"DEMO-002",brand:"Fiat",model:"Strada"});
    await set("organizations/empresa-beta-demo/vehicles/carro-03", {nickname:"Sprinter — demonstração",plate:"DEMO-003",brand:"Mercedes-Benz",model:"Sprinter"});
    await set("organizations/empresa-alfa-demo/trips/viagem-01", {vehicleId:"carro-01",vehicleName:"Fiorino — demonstração",startedAt:minutesAgo(90),distanceKm:18.6,driverScore:92,overspeedEvents:0,harshEvents:1});
    await set("organizations/empresa-alfa-demo/trips/viagem-02", {vehicleId:"carro-02",vehicleName:"Strada — demonstração",startedAt:minutesAgo(150),distanceKm:31.2,driverScore:87,overspeedEvents:1,harshEvents:0});
    await set("organizations/empresa-beta-demo/trips/viagem-03", {vehicleId:"carro-03",vehicleName:"Sprinter — demonstração",startedAt:minutesAgo(210),distanceKm:44.1,driverScore:90,overspeedEvents:0,harshEvents:0});
    await set("organizations/empresa-alfa-demo/alerts/alerta-01", {title:"Frenagem brusca — exemplo",vehicleName:"Fiorino — demonstração",createdAt:minutesAgo(60),type:"harsh_braking"});
    await set("organizations/empresa-alfa-demo/alerts/alerta-02", {title:"Excesso de velocidade — exemplo",vehicleName:"Strada — demonstração",createdAt:minutesAgo(140),type:"overspeed"});
  });
  console.log("Dados fictícios gravados apenas no Firestore Emulator:", projectId);
  console.log("Empresas: Transportes Alfa — DEMO; Logística Beta — DEMO");
} finally {
  await env.cleanup();
}
