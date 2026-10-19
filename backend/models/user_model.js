const { getDatabase } = require('../config/database');

function usersCollection() {
  return getDatabase().collection('Usuarios');
}

async function findAll() {
  return usersCollection().find({}, { projection: { password: 0 } }).toArray();
}

async function findByUsername(username) {
  return usersCollection().findOne({ username });
}

async function findByEmail(email) {
  return usersCollection().findOne({ email });
}

async function create(user) {
  const result = await usersCollection().insertOne(user);
  return {
    _id: result.insertedId,
    email: user.email,
    username: user.username,
    id: user.id,
  };
}

async function nextNumericId() {
  const highestIdUser = await usersCollection()
    .find({ id: { $type: 'number' } }, { projection: { id: 1 } })
    .sort({ id: -1 })
    .limit(1)
    .next();
  return highestIdUser ? highestIdUser.id + 1 : 1;
}

module.exports = {
  findAll,
  findByUsername,
  findByEmail,
  create,
  nextNumericId,
};
