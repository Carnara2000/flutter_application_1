const { MongoClient } = require('mongodb');

const uri = process.env.MONGO_URI;

let client = null;
let db = null;

async function getDB() {
  if (!uri) {
    throw new Error('Falta la variable de entorno MONGO_URI');
  }
  if (!db) {
    client = new MongoClient(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 10000,
    });
    await client.connect();
    db = client.db('appLogin');
  }
  return db;
}

module.exports = async (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  // Quita query string y la barra final
  const path = (req.url || '/').split('?')[0].replace(/\/+$/, '') || '/';
  console.log('Request:', req.method, path);

  try {
    if (path === '/' || path === '/api' || path === '/api/health') {
      return res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
      });
    }

    if (path === '/api/productos') {
      const database = await getDB();
      const productos = await database.collection('Productos').find({}).toArray();
      return res.status(200).json(productos);
    }

    if (path === '/api/usuarios') {
      const database = await getDB();
      const usuarios = await database
        .collection('Usuarios')
        .find({}, { projection: { password: 0 } })
        .toArray();
      return res.status(200).json(usuarios);
    }

    return res.status(404).json({ error: 'Ruta no encontrada', path });
  } catch (error) {
    console.error('Error:', error.message);
    return res.status(500).json({
      error: 'Error interno',
      detalle: error.message,
    });
  }
};
