const express = require('express');
const { Client } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());

// Database Connection Config
const client = new Client({
  host: process.env.DB_HOST,      // Provided by AWS/Terraform
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  port: 5432,
  ssl: { rejectUnauthorized: false } // Required for AWS RDS connections
});

// Attempt to connect to DB
client.connect()
  .then(() => console.log('✅ Connected to AWS RDS Database'))
  .catch(err => console.error('❌ Connection error', err.stack));

// Basic API Route
app.get('/', (req, res) => {
  res.send('🚀 Hello from Hybrid Dep System Backend! DB Connection is active.');
});

app.listen(5000, () => {
  console.log('Server running on port 5000');
});
