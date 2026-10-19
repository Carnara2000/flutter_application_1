const { MongoClient } = require('mongodb');

let client;
let database;

async function connectDatabase() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    throw new Error('Falta configurar MONGO_URI en el archivo .env');
  }

  client = new MongoClient(uri);
  await client.connect();
  database = client.db('appLogin');
  console.log('Conectado exitosamente a MongoDB.');
  return database;
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
