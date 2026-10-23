const { MongoClient } = require('mongodb');

const uri = process.env.MONGO_URI;
console.log('🔌 MONGO_URI presente:', uri ? 'SÍ' : 'NO');
console.log('🔌 MONGO_URI valor:', uri ? uri.substring(0, 30) + '...' : 'undefined');

let client = null;
let db = null;

async function getDB() {
  if (!db) {
    console.log('🔌 Iniciando conexión a MongoDB...');
    client = new MongoClient(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 10000,
    });
    await client.connect();
    db = client.db('appLogin');
    console.log('✅ MongoDB conectado a appLogin');
  }
  return db;
}

module.exports = async (req, res) => {
  const url = req.url;
  console.log('📨 Request recibido:', url);

  try {
    if (url === '/api/health' || url === '/') {
      return res.json({ status: 'ok', timestamp: new Date().toISOString() });
    }

    if (url === '/api/productos') {
      const database = await getDB();
      const productos = await database.collection('Productos').find({}).toArray();
      console.log(`✅ ${productos.length} productos encontrados`);
      return res.json(productos);
    }

    if (url === '/api/usuarios') {
      const database = await getDB();
      const usuarios = await database.collection('Usuarios').find({}, { projection: { password: 0 } }).toArray();
      console.log(`✅ ${usuarios.length} usuarios encontrados`);
      return res.json(usuarios);
    }

    res.status(404).json({ error: 'Ruta no encontrada' });
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('❌ Código:', error.code);
    console.error('❌ Nombre:', error.name);
    res.status(500).json({ 
      error: 'Error interno',
      detalle: error.message,
      codigo: error.code
    });
  }
};
