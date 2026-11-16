import { collection, doc, getDoc, onSnapshot, type DocumentData, type Unsubscribe } from "firebase/firestore";
import { db } from "./firebase";

export type FleetVehicle = { id: string; nickname: string; plate: string; brand: string; model: string };
export type FleetTrip = { id: string; vehicleId: string; vehicleName: string; startedAt: Date | null; distanceKm: number; driverScore: number | null; overspeedEvents: number; harshEvents: number };
export type FleetAlert = { id: string; title: string; vehicleName: string; createdAt: Date | null; type: string };
export type FleetData = { vehicles: FleetVehicle[]; trips: FleetTrip[]; alerts: FleetAlert[] };
export type FleetScope = { kind: "personal"; uid: string; label: string } | { kind: "organization"; id: string; label: string };

const str = (v: unknown) => typeof v === "string" ? v : "";
const num = (v: unknown) => typeof v === "number" && Number.isFinite(v) ? v : 0;
const date = (v: unknown): Date | null => v && typeof v === "object" && "toDate" in v && typeof v.toDate === "function" ? v.toDate() : null;

export async function verifyAdminMembership(uid: string, orgId: string): Promise<boolean> {
  if (!orgId.trim() || orgId.includes("/")) return false;
  const snapshot = await getDoc(doc(db, "organizations", orgId, "members", uid));
  const data = snapshot.data();
  return snapshot.exists() && data?.active === true && ["owner", "admin"].includes(data.role);
}

export function watchFleet(scope: FleetScope, onData: (value: FleetData) => void, onError: (reason: string) => void): Unsubscribe {
  const root = scope.kind === "personal" ? ["users", scope.uid] : ["organizations", scope.id];
  const state: FleetData = {vehicles: [], trips: [], alerts: []};
  const received = new Set<string>();
  const errors = (error: Error) => onError(error.message || "Erro ao consultar o Firestore");
  const emit = () => { if (received.size === 3) onData({...state}); };
  const listen = <T>(name: keyof FleetData, convert: (id: string, value: DocumentData) => T) =>
    onSnapshot(collection(db, ...root, name), snapshot => {
      // Views are read-only. Never show generated or placeholder telemetry.
      (state as Record<string, unknown>)[name] = snapshot.docs.map(d => convert(d.id, d.data()));
      received.add(name);
      emit();
    }, errors);
  const unsub = [
    listen("vehicles", (id,v): FleetVehicle => ({id,nickname:str(v.nickname)||str(v.name)||"Veículo sem nome",plate:str(v.plate),brand:str(v.brand),model:str(v.model)})),
    listen("trips", (id,v): FleetTrip => ({id,vehicleId:str(v.vehicleId),vehicleName:str(v.vehicleName),startedAt:date(v.startedAt),distanceKm:num(v.distanceKm),driverScore:typeof v.driverScore === "number" ? v.driverScore : null,overspeedEvents:num(v.overspeedEvents),harshEvents:num(v.harshEvents)})),
    listen("alerts", (id,v): FleetAlert => ({id,title:str(v.title)||str(v.message)||str(v.type)||"Alerta",vehicleName:str(v.vehicleName),createdAt:date(v.createdAt),type:str(v.type)})),
  ];
  return () => unsub.forEach(stop => stop());
}
