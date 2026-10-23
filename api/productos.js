const { MongoClient } = require('mongodb');

const uri = process.env.MONGO_URI;
let client;
let db;

async function getDB() {
  if (!db) {
    console.log('🔌 Conectando a MongoDB...');
    console.log('URI configurada:', uri ? 'Sí' : 'No');
    
    client = new MongoClient(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
    });
    
    await client.connect();
    console.log('✅ Cliente conectado');
    
    db = client.db('appLogin');
    console.log('📦 Base de datos: appLogin');
  }
  return db;
}

module.exports = async (req, res) => {
  try {
    const database = await getDB();
    const productos = await database.collection('Productos').find({}).toArray();
    
    console.log(`✅ ${productos.length} productos encontrados`);
    res.json(productos);
  } catch (error) {
    console.error(' Error detallado:', error);
    res.status(500).json({ 
      error: 'Error al obtener los productos',
      detalle: error.message,
      codigo: error.code,
      nombre: error.name
    });
  }
};
