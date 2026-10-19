const { ObjectId } = require('mongodb');
const { getDatabase } = require('../config/database');

function parseProduct(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;

  const { title, price, description, category, image } = body;
  if (
    typeof title !== 'string' || !title.trim() ||
    typeof price !== 'number' || !Number.isFinite(price) ||
    typeof description !== 'string' || !description.trim() ||
    typeof category !== 'string' || !category.trim() ||
    typeof image !== 'string' || !image.trim()
  ) {
    return null;
  }

  return {
    title: title.trim(),
    price,
    description: description.trim(),
    category: category.trim(),
    image: image.trim(),
  };
}

function parseObjectId(id) {
  return typeof id === 'string' && /^[a-fA-F0-9]{24}$/.test(id)
    ? new ObjectId(id)
    : null;
}

function productsCollection() {
  return getDatabase().collection('Productos');
}

async function findAll() {
  return productsCollection().find({}).toArray();
}

async function create(product) {
  const result = await productsCollection().insertOne(product);
  return { _id: result.insertedId, ...product };
}

async function update(id, product) {
  const collection = productsCollection();
  const result = await collection.updateOne({ _id: id }, { $set: product });
  if (result.matchedCount === 0) return null;
  return collection.findOne({ _id: id });
}

async function remove(id) {
  return productsCollection().findOneAndDelete({ _id: id });
}

module.exports = { parseProduct, parseObjectId, findAll, create, update, remove };
