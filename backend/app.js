const express = require('express');
const cors = require('cors');
const productRoutes = require('./routes/product_routes');
const userRoutes = require('./routes/user_routes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok' });
});
app.use('/api/productos', productRoutes);
app.use('/api/usuarios', userRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada.' });
});

app.use((error, _req, res, _next) => {
  console.error('Error procesando la solicitud:', error);
  if (error.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'El cuerpo JSON no es válido.' });
  }
  if (error.type === 'entity.too.large') {
    return res.status(413).json({ error: 'El cuerpo de la solicitud es demasiado grande.' });
  }
  return res.status(500).json({ error: 'Error interno del servidor.' });
});

module.exports = app;
