require('dotenv').config();

const app = require('./app');
const { connectDatabase, closeDatabase } = require('./config/database');

async function startServer() {
  const port = Number(process.env.PORT || 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT debe ser un puerto válido entre 1 y 65535.');
  }
  if (!process.env.JWT_SECRET) {
    throw new Error('Falta configurar JWT_SECRET en el archivo .env');
  }

  await connectDatabase();
  const server = app.listen(port, '0.0.0.0', () => {
    console.log(`Servidor corriendo en http://0.0.0.0:${port}`);
  });

  const shutdown = (signal) => {
    console.log(`Señal ${signal} recibida; cerrando el servidor.`);
    server.close(async (error) => {
      try {
        await closeDatabase();
        if (error) {
          console.error('Error al cerrar el servidor:', error);
          process.exitCode = 1;
        }
      } catch (closeError) {
        console.error('Error al cerrar MongoDB:', closeError);
        process.exitCode = 1;
      }
    });
  };

  process.once('SIGINT', () => shutdown('SIGINT'));
  process.once('SIGTERM', () => shutdown('SIGTERM'));
  return server;
}

if (require.main === module) {
  startServer().catch(async (error) => {
    console.error('No se pudo iniciar el backend:', error);
    try {
      await closeDatabase();
    } catch (closeError) {
      console.error('Error al cerrar MongoDB:', closeError);
    }
    process.exitCode = 1;
  });
}

module.exports = { startServer };
