const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// In-memory user store (for demonstration purposes)
const users = [];

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files from the 'public' directory
app.use(express.static(__dirname));


// Registration endpoint
app.post('/signup', (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: 'Please fill in all fields.' });
    }

    if (users.find(user => user.email === email)) {
        return res.status(400).json({ message: 'User with this email already exists.' });
    }

    const newUser = { name, email, password };
    users.push(newUser);

    console.log('User registered:', newUser);
    res.status(201).json({ message: 'Registration successful! You can now log in.'});
});

// Login endpoint
app.post('/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Please provide email and password.' });
    }

    const user = users.find(user => user.email === email);

    if (!user || user.password !== password) {
        return res.status(401).json({ message: 'Invalid credentials.' });
    }
    
    console.log('User logged in:', user);
    res.status(200).json({ message: 'Login successful!', user: { name: user.name, email: user.email }});
});


app.listen(port, () => {
    console.log(`ZimLearn server listening at http://localhost:${port}`);
});
