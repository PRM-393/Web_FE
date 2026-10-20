const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');

function clientHarness() {
  let resolveRefresh, rejectRefresh, handler, refreshCalls = 0, cleared = 0;
  const requestUrls = [];
  const refresh = new Promise((resolve, reject) => { resolveRefresh = resolve; rejectRefresh = reject; });
  const state = {
    accessToken: 'old-access', refreshToken: 'old-refresh', user: { id: '1', role: 'ADMIN' },
    setSession(user, tokens) { Object.assign(state, { user, ...tokens }); },
    clearSession() { cleared++; Object.assign(state, { user: null, accessToken: null, refreshToken: null }); },
  };
  const client = config => Promise.resolve({ retried: config.url });
  client.interceptors = { request: { use() {} }, response: { use(_success, failure) { handler = failure; } } };
  const axios = {
    create: config => { requestUrls.push(config.baseURL); return client; },
    post: url => { refreshCalls++; requestUrls.push(url); return refresh; },
  };
  const exports = {};
  const source = fs.readFileSync(path.join(__dirname, '../src/lib/api-client.ts'), 'utf8')
    .replaceAll('import.meta.env.VITE_API_BASE_URL', 'undefined');
  const compiled = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, esModuleInterop: true, target: ts.ScriptTarget.ES2022 } }).outputText;
  vm.runInNewContext(compiled, {
    exports, require(name) {
      if (name === 'axios') return { __esModule: true, default: axios };
      if (name === '@/store/auth.store') return { useAuthStore: { getState: () => state } };
      throw new Error('Unexpected import: ' + name);
    },
  });
  const fail = url => handler({ response: { status: 401 }, config: { url } });
  return { state, fail, requestUrls, resolveRefresh, rejectRefresh,
    refreshCalls: () => refreshCalls, cleared: () => cleared };
}
const session = { data: { user: { id: '1', role: 'ADMIN' }, accessToken: 'new-access', refreshToken: 'new-refresh' } };

test('uses the same fallback URL for regular requests and refresh', async () => {
  const h = clientHarness(); const result = h.fail('/admin/dashboard');
  h.resolveRefresh(session); await result;
  assert.deepEqual(h.requestUrls, ['http://localhost:3000/api', 'http://localhost:3000/api/auth/refresh']);
});
test('concurrent 401 responses share one refresh and all retry', async () => {
  const h = clientHarness();
  const results = [h.fail('/one'), h.fail('/two'), h.fail('/three')];
  assert.equal(h.refreshCalls(), 1);
  h.resolveRefresh(session);
  const values = await Promise.all(results);
  assert.deepEqual(values.map(v => v.retried), ['/one', '/two', '/three']);
  assert.equal(h.state.accessToken, 'new-access');
});
test('failed refresh rejects every waiting request and clears the session', async () => {
  const h = clientHarness();
  const results = Promise.allSettled([h.fail('/one'), h.fail('/two')]);
  h.rejectRefresh(new Error('Refresh denied'));
  const values = await results;
  assert.ok(values.every(v => v.status === 'rejected'));
  assert.equal(h.state.user, null);
});
test('late refresh cannot restore a logged-out session', async () => {
  const h = clientHarness();
  const result = h.fail('/admin/dashboard');
  h.state.clearSession();
  h.resolveRefresh(session);
  await assert.rejects(result);
  assert.equal(h.state.user, null);
});
test('login errors are never retried with a persisted session', async () => {
  const h = clientHarness();
  await assert.rejects(h.fail('/auth/login'));
  assert.equal(h.refreshCalls(), 0);
});
test('logout can refresh an expired access token before revoking its session', async () => {
  const h = clientHarness(); const result = h.fail('/auth/logout');
  h.resolveRefresh(session); await result;
  assert.equal(h.refreshCalls(), 1);
});
