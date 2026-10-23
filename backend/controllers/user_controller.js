const jwt = require('jsonwebtoken');
const User = require('../models/user_model');

async function getUsers(_req, res) {
  try {
    return res.json(await User.findAll());
    } catch (error) {
    console.error('Error al obtener los usuarios:', error);
    return res.status(500).json({ 
      error: 'Error al obtener los usuarios', 
      detalle: error.message,
      mongo_uri_configurada: process.env.MONGO_URI ? 'Sí, está configurada' : 'No, falta la variable'
    });
  }
}

async function createOrLogin(req, res) {
  const body = req.body ?? {};
  if (!Object.prototype.hasOwnProperty.call(body, 'email')) {
    return login(body, res);
  }
  return register(body, res);
}

async function login(body, res) {
  const { username, password } = body;
  if (
    typeof username !== 'string' || !username.trim() ||
    typeof password !== 'string' || !password
  ) {
    return res.status(400).json({ error: 'Se requieren username y password.' });
  }

  try {
    const user = await User.findByUsername(username);
    if (!user || password !== user.password) {
      return res.status(401).json({ error: 'Usuario o contraseña inválidos' });
    }
    if (!Number.isInteger(user.id)) {
      console.error('El usuario autenticado no tiene un id numérico válido.');
      return res.status(500).json({ error: 'Error al iniciar sesión.' });
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('Falta configurar JWT_SECRET en el archivo .env');
    }
    const token = jwt.sign({ sub: String(user.id) }, secret);
    return res.status(200).json({ token });
  } catch (error) {
    console.error('Error al iniciar sesión:', error);
    return res.status(500).json({ error: 'Error al iniciar sesión.' });
  }
}

async function register(body, res) {
  const { email, username, password } = body;
  const missingFields = [];
  if (typeof email !== 'string' || !email.trim()) missingFields.push('email');
  if (typeof username !== 'string' || !username.trim()) {
    missingFields.push('username');
  }
  if (typeof password !== 'string' || !password.trim()) {
    missingFields.push('password');
  }
  if (missingFields.length > 0) {
    return res.status(400).json({
      error: `Faltan campos obligatorios: ${missingFields.join(', ')}.`,
    });
  }

  const normalizedEmail = email.trim();
  const normalizedUsername = username.trim();
  try {
    if (await User.findByUsername(normalizedUsername)) {
      return res.status(409).json({ error: 'El username ya está en uso.' });
    }
    if (await User.findByEmail(normalizedEmail)) {
      return res.status(409).json({ error: 'El email ya está en uso.' });
    }

    const user = {
      email: normalizedEmail,
      username: normalizedUsername,
      password,
      id: await User.nextNumericId(),
    };
    return res.status(201).json(await User.create(user));
  } catch (error) {
    console.error('Error al registrar el usuario:', error);
    return res.status(500).json({ error: 'Error al registrar el usuario.' });
  }
}

module.exports = { getUsers, createOrLogin };

