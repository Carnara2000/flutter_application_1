const test = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../app');

test('health endpoint reports that the API is running', async (context) => {
  const server = app.listen(0);
  await once(server, 'listening');
  context.after(() => new Promise((resolve) => server.close(resolve)));

  const response = await fetch(
    `http://127.0.0.1:${server.address().port}/api/health`,
  );
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('product creation rejects invalid data without requiring MongoDB', async (context) => {
  const server = app.listen(0);
  await once(server, 'listening');
  context.after(() => new Promise((resolve) => server.close(resolve)));

  const response = await fetch(
    `http://127.0.0.1:${server.address().port}/api/productos`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Producto incompleto' }),
    },
  );
  assert.equal(response.status, 400);
  assert.match((await response.json()).error, /Se requieren title/);
});
