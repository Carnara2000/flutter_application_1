const test = require('node:test');
const assert = require('node:assert/strict');
const { parseObjectId, parseProduct } = require('../models/product_model');

test('parseProduct accepts complete product data and trims text', () => {
  assert.deepEqual(
    parseProduct({
      title: ' Jabón ',
      price: 25,
      description: ' Para limpiar ',
      category: ' Hogar ',
      image: ' https://example.com/jabon.png ',
    }),
    {
      title: 'Jabón',
      price: 25,
      description: 'Para limpiar',
      category: 'Hogar',
      image: 'https://example.com/jabon.png',
    },
  );
});

test('parseProduct rejects invalid or incomplete values', () => {
  assert.equal(parseProduct(null), null);
  assert.equal(parseProduct({ title: 'Jabón', price: Infinity }), null);
});

test('parseObjectId accepts only 24 hexadecimal characters', () => {
  assert.equal(
    parseObjectId('6ac9e0d74e0adda992e0f2b7').toHexString(),
    '6ac9e0d74e0adda992e0f2b7',
  );
  assert.equal(parseObjectId('invalid'), null);
  assert.equal(parseObjectId(null), null);
});
