const { MongoClient } = require('mongodb');

let client;
let database;

async function connectDatabase(){
  const uri = process.env.MONGO_URI;
  if(!uri){
    throw new Error('Falta configurar MONGO_URI en el archivo .env');
  }

  try {
    // Crear nuevo cliente si no existe
    if (!client) {
      console.log('🔌 Creando cliente MongoDB...');
      client = new MongoClient(uri, {
        maxPoolSize: 10,
        minPoolSize: 2,
        maxIdleTimeMS: 60000,
        serverSelectionTimeoutMS: 5000,
      });
    }

    // Conectar si no está conectado
    if (!client.topology || !client.topology.isConnected()) {
      console.log('🔌 Conectando a MongoDB...');
      await client.connect();
      console.log('✅ Conexión establecida');
    }

    // Obtener la base de datos
    database = client.db('appLogin');
    console.log('📦 Base de datos: appLogin');
    
    return database;
  } catch (error) {
    console.error('❌ Error al conectar:', error.message);
    console.error('Código:', error.code);
    console.error('Nombre:', error.name);
    throw error;
  }
}

function getDatabase(){
  if(!database){
    throw new Error('La conexión a MongoDB todavía no está inicializada.');
  }
  return database;
}

async function closeDatabase(){
  if(!client) return;
  await client.close();
  client = undefined;
  database = undefined;
}

module.exports = { connectDatabase, getDatabase, closeDatabase };
