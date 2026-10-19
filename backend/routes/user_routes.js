const express = require('express');
const UserController = require('../controllers/user_controller');

const router = express.Router();

router.get('/', UserController.getUsers);
router.post('/', UserController.createOrLogin);

module.exports = router;
