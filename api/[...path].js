const app = require('../backend/app');
const { connectDatabase } = require('../backend/config/database');

let dbConnected = false;

// Función para asegurar la conexión
async function ensureDatabase() {
  if (!dbConnected) {
    try {
      await connectDatabase();
      dbConnected = true;
      console.log('✅ MongoDB conectado');
    } catch (error) {
      console.error('❌ Error al conectar MongoDB:', error);
      throw error;
    }
  }
}

// Handler principal de Vercel
module.exports = async (req, res) => {
  try {
    // Asegurar conexión antes de cada request
    await ensureDatabase();
    
    // Pasar la request a Express
    return app(req, res);
  } catch (error) {
    console.error('Error en API:', error);
    return res.status(500).json({ 
      error: 'Error interno del servidor',
      detalle: error.message 
    });
  }
};
