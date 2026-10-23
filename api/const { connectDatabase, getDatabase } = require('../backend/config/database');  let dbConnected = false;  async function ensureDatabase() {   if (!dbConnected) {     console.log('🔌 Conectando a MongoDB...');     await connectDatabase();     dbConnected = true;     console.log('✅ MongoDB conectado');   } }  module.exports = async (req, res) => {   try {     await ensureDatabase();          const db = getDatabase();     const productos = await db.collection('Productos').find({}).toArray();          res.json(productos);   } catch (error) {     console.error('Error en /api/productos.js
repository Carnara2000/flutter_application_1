const { connectDatabase, getDatabase } = require('../backend/config/database');

let dbConnected = false;

async function ensureDatabase() {
  if (!dbConnected) {
    console.log('🔌 Conectando a MongoDB...');
    await connectDatabase();
    dbConnected = true;
    console.log('✅ MongoDB conectado');
  }
}

module.exports = async (req, res) => {
  try {
    await ensureDatabase();
    
    const db = getDatabase();
    const productos = await db.collection('Productos').find({}).toArray();
    
    res.json(productos);
  } catch (error) {
    console.error('Error en /api/productos:', error);
    res.status(500).json({ 
      error: 'Error al obtener los productos',
      detalle: error.message,
      stack: error.stack
    });
  }
};
