# SafeCar Fleet — Evolução multiempresa e telemetria

## Situação observada (branch feature/safecar-fleet-obd)
- Autenticação via Firebase Auth.
- Veículos e viagens armazenados abaixo de `users/{uid}`.
- O serviço `TripFirestoreService` grava viagens em `users/{uid}/trips`.
- O GPS do ESP32 é consultado via HTTP na rede local; não existe ingestão remota contínua validada.
- Parte dos indicadores atuais é calculada a partir de simulação. Não rotular como medição real.

## Diretrizes do PR #2
O esquema novo **não migra nem apaga** a estrutura legada. Organizações, membros e
registros compartilhados serão provisionados por backend confiável usando Firebase
Admin SDK (que ignora Firestore Security Rules). Nas regras, os membros autenticados
podem **ler**, mas nenhum cliente pode criar, atualizar ou apagar os novos registros
até existir API segura, validações e testes de autorização.

### Modelo de dados proposto
```text
organizations/{organizationId}
  name, createdAt, status
  members/{uid}
    role: owner | admin | manager | viewer
    active: true
    joinedAt
  vehicles/{vehicleId}
    plate, nickname, status, deviceId
  drivers/{driverId}
    name, active
  trips/{tripId}
    vehicleId, driverId, startedAt, endedAt
    distanceKm, averageSpeedKmh, maxSpeedKmh, driverScore
    source: simulated | gps | obd | tracker
  alerts/{alertId}
    vehicleId, tripId, type, severity, createdAt, acknowledgedAt
  devices/{deviceId}
    provider, model, imeiHash, protocol, lastSeenAt, lastValidPositionAt
```

## Segurança e papéis
- Membership por `organizations/{organizationId}/members/{uid}`.
- O backend deve validar `active == true`, `role`, `organizationId`, origem da
  requisição e permissões por operação antes de cada escrita.
- Não permitir que o cliente edite seu próprio papel ou aceite convites sem verificação.
- Identificadores IMEI não devem ser publicados em texto claro; segredos e tokens ficam
  exclusivamente no backend/Secret Manager.
- As regras deste PR só verificam existência do documento de membro para leitura.
  **Antes de liberar a organizações reais**, adicionar teste para membro inativo e
  controle de acesso por papel, e endurecer o predicado `isMember`.
- Tratar os dados dos condutores e localização como dados pessoais: retenção,
  finalidade, acesso e exclusão precisam de política adequada.

## Evolução do hardware (não depende de um fornecedor)
Criar no backend uma camada de ingestão normalizada:
```json
{
  "organizationId": "org_1",
  "vehicleId": "vehicle_1",
  "deviceId": "device_1",
  "source": "esp32_gps | elm327 | teltonika | other",
  "timestamp": "2026-11-09T20:00:00Z",
  "location": {"lat": -22.7371, "lon": -47.3331},
  "speedKmh": 45.5,
  "rpm": null,
  "engineTempC": null,
  "ignition": null,
  "quality": "observed | simulated"
}
```

- `ESP32 + NEO-6M`: fluxo HTTP local atual; futuro gateway de upload requer
  conectividade celular ou integração via telefone.
- `ELM327`: leitura de parâmetros suportados pelo carro; não fornece conexão
  remota por conta própria.
- `Teltonika/Queclink`: usar protocolo padronizado ou servidor Traccar como
  adaptador; processar pacotes em serviço de backend antes de publicar agregados
  no Firestore.
- Evitar gravar um documento Firestore por segundo por veículo sem política de
  custos/retenção; agregar posições e eventos conforme a necessidade.

## Plano de implementação
1. Adicionar testes no Firebase Emulator: não membro, membro ativo, membro
   inativo, roles, tentativas de escalonamento, leitura entre empresas.
2. Implementar provisionamento via Admin SDK, convites e autenticação do backend.
3. Implementar leitura de indicadores agregados para dashboard da organização.
4. Migrar gradualmente os usuários existentes, mantendo compatibilidade e rollback.
5. Criar receptor de telemetria seguro, validado e independente do fornecedor.
6. Construir dashboard administrativo com filtros, KPIs, mapa e alertas.

## Checklist de implantação
- [ ] Testes de segurança passando
- [ ] Regras revistas para papéis e membros inativos
- [ ] Rotinas server-side implementadas e protegidas
- [ ] Migração e rollback documentados
- [ ] Simulação claramente rotulada
- [ ] Orçamento de ingestão e armazenamento estimado
- [ ] Permissão explícita para habilitar o novo módulo em produção
