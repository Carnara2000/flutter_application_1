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
    const usuarios = await db.collection('Usuarios').find({}, { projection: { password: 0 } }).toArray();
    
    res.json(usuarios);
  } catch (error) {
    console.error('Error en /api/usuarios:', error);
    res.status(500).json({ 
      error: 'Error al obtener los usuarios',
      detalle: error.message,
      stack: error.stack
    });
  }
};
