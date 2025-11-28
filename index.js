const express = require('express');
const app = express();

const ENVIRONMENT = process.env.DEPLOY_ENV || 'blue';
const PORT = ENVIRONMENT === 'green' ? 3002 : 3001;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({ 
    message: `Hola! ya funciono correctamente ${ENVIRONMENT.toUpperCase()} VERSION`,
    version: '5.0.0',
    environment: ENVIRONMENT,
    port: PORT
  });
});

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    environment: ENVIRONMENT,
    port: PORT
  });
});

app.get('/api/users', (req, res) => {
  const users = [
    { id: 1, name: 'Juan', email: 'juan@example.com' },
    { id: 2, name: 'María', email: 'maria@example.com' },
    { id: 3, name: 'Pedro', email: 'pedro@example.com' }
  ];
  res.json(users);
});

app.post('/api/users', (req, res) => {
  const newUser = req.body;
  res.status(201).json({
    message: 'Usuario creado',
    user: newUser,
    environment: ENVIRONMENT
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor ${ENVIRONMENT.toUpperCase()} corriendo en puerto ${PORT}`);
});