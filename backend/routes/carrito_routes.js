const express = require('express');
const { getDatabase } = require('../config/database');

const router = express.Router();

const carritos = () => getDatabase().collection('Carritos');

function parseUserId(value) {
  const id = Number(value);
  return Number.isInteger(id) && id > 0 ? id : null;
}

function parseItems(items) {
  if (!Array.isArray(items)) return null;
  const limpios = [];
  for (const item of items) {
    const quantity = Number(item?.quantity ?? 1);
    const price = Number(item?.price);
    if (
      typeof item?.productId !== 'string' ||
      !item.productId.trim() ||
      !Number.isInteger(quantity) ||
      quantity < 1 ||
      !Number.isFinite(price)
    ) {
      return null;
    }
    limpios.push({
      productId: item.productId.trim(),
      title: String(item.title ?? '').trim(),
      price,
      quantity,
    });
  }
  return limpios;
}

// GET /api/carritos -> todos los carritos
router.get('/', async (_req, res) => {
  res.json(await carritos().find({}).toArray());
});

// GET /api/carritos/:userId -> carrito de un usuario (vacío si no tiene)
router.get('/:userId', async (req, res) => {
  const userId = parseUserId(req.params.userId);
  if (!userId) return res.status(400).json({ error: 'userId inválido.' });

  const carrito = await carritos().findOne({ userId });
  res.json(carrito ?? { userId, items: [] });
});

// PUT /api/carritos/:userId -> guarda/reemplaza los artículos del carrito
// body: { "items": [ { "productId": "...", "title": "...", "price": 10.5, "quantity": 2 } ] }
router.put('/:userId', async (req, res) => {
  const userId = parseUserId(req.params.userId);
  if (!userId) return res.status(400).json({ error: 'userId inválido.' });

  const items = parseItems(req.body?.items);
  if (!items) {
    return res.status(400).json({
      error: 'items debe ser una lista con productId, price y quantity válidos.',
    });
  }

  await carritos().updateOne(
    { userId },
    { $set: { items, updatedAt: new Date() } },
    { upsert: true },
  );
  res.json(await carritos().findOne({ userId }));
});

// DELETE /api/carritos/:userId -> vacía el carrito
router.delete('/:userId', async (req, res) => {
  const userId = parseUserId(req.params.userId);
  if (!userId) return res.status(400).json({ error: 'userId inválido.' });

  await carritos().deleteOne({ userId });
  res.json({ message: 'Carrito vaciado.' });
});

module.exports = router;
