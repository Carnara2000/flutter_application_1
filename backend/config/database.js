const { MongoClient } = require('mongodb');

let client;
let database;
let connecting;

async function connectDatabase() {
  // Ya conectada: reutilizar
  if (database) return database;
  // Conexión en curso: esperar la misma promesa
  if (connecting) return connecting;

  const uri = process.env.MONGO_URI;
  if (!uri) {
    throw new Error('Falta configurar MONGO_URI (en .env o en las variables de Vercel)');
  }

  connecting = (async () => {
    try {
      console.log('Conectando a MongoDB...');
      client = new MongoClient(uri, {
        maxPoolSize: 10,
        serverSelectionTimeoutMS: 8000,
      });
      await client.connect();
      database = client.db('appLogin');
      console.log('Conexión establecida: appLogin');
      return database;
    } catch (error) {
      console.error('Error al conectar:', error.message);
      client = undefined;
      database = undefined;
      throw error;
    } finally {
      connecting = undefined;
    }
  })();

  return connecting;
}

function getDatabase() {
  if (!database) {
    throw new Error('La conexión a MongoDB todavía no está inicializada.');
  }
  return database;
}

async function closeDatabase() {
  if (!client) return;
  await client.close();
  client = undefined;
  database = undefined;
}

module.exports = { connectDatabase, getDatabase, closeDatabase };
