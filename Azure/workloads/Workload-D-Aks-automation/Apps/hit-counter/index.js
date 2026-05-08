const express = require('express');
const mongoose = require('mongoose');
const WebSocket = require('ws');

const app = express();

const connectionString = process.env.CONNECTION_STRING;
const dbName = process.env.DB_NAME || 'hit-counter';

// Connect to MongoDB database
mongoose.connect(connectionString, { useNewUrlParser: true, useUnifiedTopology: true, dbName })
    .then(() => {
        console.log('Connected to MongoDB');
    })
    .catch((error) => {
        console.error('Error connecting to MongoDB:', error);
    });

// // Connect to MongoDB database by connstring
// mongoose.connect('mongodb://localhost:27017/hit-counter', { useNewUrlParser: true, useUnifiedTopology: true })
//     .then(() => {
//         console.log('Connected to MongoDB');
//     })
//     .catch((error) => {
//         console.error('Error connecting to MongoDB:', error);
//     });

// Define hit counter schema and model
const hitSchema = new mongoose.Schema({
    hits: { type: Number, default: 0 }
});

const Hit = mongoose.model('Hit', hitSchema);

// Create WebSocket server
const server = app.listen(3000, () => {
    console.log('Hit counter listening on port 3000');
});

const wss = new WebSocket.Server({ server });

// Serve static files from the public directory
app.use(express.static('public'));

// ============================================================
// HEALTH CHECK ENDPOINTS (Industry Standard for Kubernetes)
// ============================================================

// Liveness Probe — /health
// K8s calls this to check if the process is alive and not stuck.
// If this fails, K8s will RESTART the container.
// Should be lightweight — just confirms the server is responding.
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', uptime: process.uptime() });
});

// Readiness Probe — /ready
// K8s calls this to check if the app is READY to receive traffic.
// If this fails, K8s will STOP sending traffic to this pod
// (but won't restart it). Useful during startup when MongoDB
// isn't connected yet.
app.get('/ready', (req, res) => {
    // mongoose.connection.readyState: 0=disconnected, 1=connected, 2=connecting, 3=disconnecting
    if (mongoose.connection.readyState === 1) {
        res.status(200).json({ status: 'ready', db: 'connected' });
    } else {
        res.status(503).json({ status: 'not ready', db: 'disconnected' });
    }
});

// Define hits endpoint to return hit count as JSON
app.get('/hits', (req, res) => {
    Hit.findOne()
        .then((hit) => {
            res.json({ hits: hit.hits });
        })
        .catch((error) => {
            console.error('Error getting hit count:', error);
            res.status(500).send('Error getting hit count');
        });
});


// Define hits endpoint to increment hit count and return updated count as JSON
app.post('/hits', (req, res) => {
    Hit.findOneAndUpdate({}, { $inc: { hits: 1 } }, { upsert: true, new: true })
        .then((hit) => {
            res.json({ hits: hit.hits });
            // Broadcast updated hit count to all open WebSocket connections
            wss.clients.forEach((client) => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(hit.hits);
                }
            });
        })
        .catch((error) => {
            console.error('Error incrementing hit count:', error);
            res.status(500).send('Error incrementing hit count');
        });
});


// Define stage endpoint to return value of STAGE environment variable as JSON
app.get('/stage', (req, res) => {
    const stage = process.env.STAGE;
    if (stage) {
        res.json({ stage: stage });
    } else {
        res.status(500).send('STAGE environment variable not set');
    }
});


// Handle WebSocket connections
wss.on('connection', (ws) => {
    console.log('WebSocket client connected');

    // Send initial hit count to new WebSocket connection
    Hit.findOne()
        .then((hit) => {
            ws.send(hit.hits);
        })
        .catch((error) => {
            console.error('Error getting hit count:', error);
        });
});
