const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const uri = process.env.MONGO_URI;
let client;
let db;

async function getDB() {
  if (!db) {
    console.log('🔌 Conectando a MongoDB...');
    client = new MongoClient(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
    });
    await client.connect();
    db = client.db('appLogin');
    console.log('✅ MongoDB conectado');
  }
  return db;
}

// Ruta de health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Ruta de productos
app.get('/api/productos', async (req, res) => {
  try {
    const database = await getDB();
    const productos = await database.collection('Productos').find({}).toArray();
    console.log(`✅ ${productos.length} productos encontrados`);
    res.json(productos);
  } catch (error) {
    console.error('Error en /api/productos:', error);
    res.status(500).json({ 
      error: 'Error al obtener los productos',
      detalle: error.message
    });
  }
});

// Ruta de usuarios
app.get('/api/usuarios', async (req, res) => {
  try {
    const database = await getDB();
    const usuarios = await database.collection('Usuarios').find({}, { projection: { password: 0 } }).toArray();
    console.log(`✅ ${usuarios.length} usuarios encontrados`);
    res.json(usuarios);
  } catch (error) {
    console.error('Error en /api/usuarios:', error);
    res.status(500).json({ 
      error: 'Error al obtener los usuarios',
      detalle: error.message
    });
  }
});

// Exportar para Vercel
module.exports = app;
