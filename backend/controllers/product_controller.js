const Product = require('../models/product_model');

async function getProducts(_req, res) {
  try {
    return res.json(await Product.findAll());
  } catch (error) {
    console.error('Error al obtener los productos:', error);
    return res.status(500).json({ 
      error: 'Error al obtener los productos', 
      detalle: error.message,
      mongo_uri_configurada: process.env.MONGO_URI ? 'Sí, está configurada' : 'No, falta la variable'
    });
  }
}

async function createProduct(req, res) {
  const product = Product.parseProduct(req.body);
  if (!product) {
    return res.status(400).json({
      error: 'Se requieren title, price, description, category e image válidos.',
    });
  }

  try {
    return res.status(201).json(await Product.create(product));
  } catch (error) {
    console.error('Error al crear el producto:', error);
    return res.status(500).json({ 
      error: 'Error al crear el producto',
      detalle: error.message 
    });
  }
}

async function updateProduct(req, res) {
  const id = Product.parseObjectId(req.params.id);
  if (!id) {
    return res.status(400).json({ error: 'El ID debe ser un ObjectId válido.' });
  }

  const product = Product.parseProduct(req.body);
  if (!product) {
    return res.status(400).json({
      error: 'Se requieren title, price, description, category e image válidos.',
    });
  }

  try {
    const updated = await Product.update(id, product);
    if (!updated) {
      return res.status(404).json({ error: 'Producto no encontrado.' });
    }
    return res.json(updated);
  } catch (error) {
    console.error('Error al actualizar el producto:', error);
    return res.status(500).json({ error: 'Error al actualizar el producto', detalle: error.message });
  }
}

async function deleteProduct(req, res) {
  const id = Product.parseObjectId(req.params.id);
  if (!id) {
    return res.status(400).json({ error: 'El ID debe ser un ObjectId válido.' });
  }

  try {
    const deleted = await Product.remove(id);
    if (!deleted) {
      return res.status(404).json({ error: 'Producto no encontrado.' });
    }
    return res.json({
      message: 'Producto eliminado correctamente.',
      producto: deleted,
    });
  } catch (error) {
    console.error('Error al eliminar el producto:', error);
    return res.status(500).json({ error: 'Error al eliminar el producto', detalle: error.message });
  }
}

module.exports = { getProducts, createProduct, updateProduct, deleteProduct };
