/**
 * SafeCar Fleet - Firestore multi-tenant security regression tests.
 *
 * Prerequisites:
 *   npm install
 *   firebase emulators:exec --only firestore "npm test"
 *
 * Firebase Admin SDK bypasses security rules; these tests exercise client
 * reads/writes only and use the test rules-unit-testing SDK for fixtures.
 */
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'safecar-rules-test';

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc('organizations/orgA').set({ name: 'Empresa A' });
    await db.doc('organizations/orgB').set({ name: 'Empresa B' });
    await db.doc('organizations/orgA/members/ownerA').set({ active: true, role: 'owner' });
    await db.doc('organizations/orgA/members/adminA').set({ active: true, role: 'admin' });
    await db.doc('organizations/orgA/members/viewerA').set({ active: true, role: 'viewer' });
    await db.doc('organizations/orgA/members/inactiveA').set({ active: false, role: 'viewer' });
    await db.doc('organizations/orgB/members/viewerB').set({ active: true, role: 'viewer' });
    await db.doc('organizations/orgA/vehicles/v1').set({ nickname: 'Fiorino' });
    await db.doc('organizations/orgB/vehicles/v2').set({ nickname: 'Strada' });
  });
});

afterAll(async () => {
  if (env) await env.cleanup();
});

const client = (uid) => env.authenticatedContext(uid).firestore();

test('active member can read their organization vehicle', async () => {
  await assertSucceeds(client('viewerA').doc('organizations/orgA/vehicles/v1').get());
});

test('member cannot access another organization', async () => {
  await assertFails(client('viewerA').doc('organizations/orgB/vehicles/v2').get());
});

test('inactive member cannot read their organization', async () => {
  await assertFails(client('inactiveA').doc('organizations/orgA/vehicles/v1').get());
});

test('unauthenticated user cannot access vehicles', async () => {
  await assertFails(env.unauthenticatedContext().firestore().doc('organizations/orgA/vehicles/v1').get());
});

test('viewer may read only their own membership', async () => {
  await assertSucceeds(client('viewerA').doc('organizations/orgA/members/viewerA').get());
  await assertFails(client('viewerA').doc('organizations/orgA/members/adminA').get());
});

test('admins may read memberships within their organization', async () => {
  await assertSucceeds(client('adminA').doc('organizations/orgA/members/viewerA').get());
  await assertSucceeds(client('ownerA').doc('organizations/orgA/members/adminA').get());
});

test('all client writes to organizations remain forbidden', async () => {
  await assertFails(client('ownerA').doc('organizations/orgA/vehicles/v1').update({ nickname: 'Teste' }));
  await assertFails(client('adminA').doc('organizations/orgA/members/viewerA').update({ role: 'admin' }));
  await assertFails(client('viewerA').doc('organizations/orgA/trips/trip1').set({ distanceKm: 12 }));
});
