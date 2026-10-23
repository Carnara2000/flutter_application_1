const app = require('../backend/app');
const { connectDatabase } = require('../backend/config/database');

let dbConnected = false;

async function ensureDatabase() {
  if (!dbConnected) {
    try {
      console.log('🔌 Intentando conectar a MongoDB...');
      console.log('MONGO_URI configurado:', process.env.MONGO_URI ? 'Sí' : 'No');
      
      await connectDatabase();
      dbConnected = true;
      console.log('✅ MongoDB conectado exitosamente');
    } catch (error) {
      console.error('❌ Error detallado al conectar MongoDB:');
      console.error('Mensaje:', error.message);
      console.error('Código:', error.code);
      console.error('Nombre:', error.name);
      console.error('Stack completo:', error.stack);
      throw error;
    }
  }
}

module.exports = async (req, res) => {
  try {
    await ensureDatabase();
    return app(req, res);
  } catch (error) {
    console.error('Error en API:', error);
    return res.status(500).json({ 
      error: 'Error interno del servidor',
      detalle: error.message,
      codigo: error.code,
      nombre: error.name
    });
  }
};
