const app = require('../backend/app');
const { connectDatabase } = require('../backend/config/database');

// Conectar a MongoDB al cargar la función
connectDatabase().catch((error) => {
  console.error('Error al conectar a MongoDB:', error);
});

// Exportar la aplicación para que Vercel la use
module.exports = app;
