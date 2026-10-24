const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');
const { setupSwagger } = require('./swagger/swaggerDoc');
const { testConnection } = require('./config/db');

const app = express();

// Middlewares
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Swagger API Documentation
setupSwagger(app);

// Root & Healthcheck
app.get('/', (req, res) => {
  res.json({
    name: 'Raw Material Inventory & Transaction API',
    version: '1.0.0',
    status: 'ONLINE',
    docs: '/api-docs',
    endpoints: '/api'
  });
});

app.get('/health', async (req, res) => {
  const dbStatus = await testConnection();
  res.json({
    status: dbStatus ? 'HEALTHY' : 'DEGRADED',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: dbStatus ? 'CONNECTED' : 'DISCONNECTED'
  });
});

// Mount API routes
app.use('/api', routes);

// 404 Route handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Rute '${req.method} ${req.originalUrl}' tidak ditemukan`
  });
});

// Centralized Error Handler
app.use(errorHandler);

module.exports = app;
