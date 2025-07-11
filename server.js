const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3001;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'ZimLearn')));

// ... (keep the existing response and chat logic)

// Dummy user data
let users = [
    { name: 'Test Student', email: 'student@example.com', password: 'Password1', role: 'student', enrolledSubjects: ['English', 'Mathematics'], submissions: [] }
];

// Signup
app.post('/signup', (req, res) => {
    const { name, email, password, role } = req.body;
    if (users.find(user => user.email === email)) {
        return res.status(400).json({ message: 'User already exists' });
    }
    const newUser = { name, email, password, role, enrolledSubjects: [], children: [], submissions: [] };
    users.push(newUser);
    res.status(201).json({ message: 'User created successfully' });
});

// Login
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const user = users.find(user => user.email === email && user.password === password);
    if (user) {
        const userToSend = { name: user.name, email: user.email, role: user.role, enrolledSubjects: user.enrolledSubjects, children: user.children };
        res.json({ message: 'Login successful', user: userToSend });
    } else {
        res.status(401).json({ message: 'Invalid credentials' });
    }
});

// Link child account
app.post('/link-child', (req, res) => {
    const { parentEmail, childEmail } = req.body;
    const parent = users.find(user => user.email === parentEmail);
    const child = users.find(user => user.email === childEmail);

    if (!parent || !child) {
        return res.status(404).json({ message: 'Parent or child not found' });
    }
    if (child.role !== 'student') {
        return res.status(400).json({ message: 'The linked account must be a student account.' });
    }

    if (!parent.children.includes(childEmail)) {
        parent.children.push(childEmail);
    }
    
    const childData = { name: child.name, progress: `${child.enrolledSubjects.length * 10}%`, enrolledSubjects: child.enrolledSubjects };
    
    res.json({ message: `Successfully linked with ${child.name}.`, parent: parent, childData: childData });
});

// Submit an answer
app.post('/submit-answer', (req, res) => {
    const { studentEmail, subject, paper, question, answer } = req.body;
    const student = users.find(user => user.email === studentEmail);

    if (!student) {
        return res.status(404).json({ message: 'Student not found.' });
    }

    const newSubmission = {
        subject,
        paper,
        question,
        answer,
        submittedAt: new Date().toISOString()
    };
    student.submissions.push(newSubmission);
    res.json({ message: 'Your work has been submitted successfully.' });
});


// Get all students and their submissions
app.get('/students', (req, res) => {
    const students = users.filter(user => user.role === 'student');
    const studentData = students.map(student => ({ 
        name: student.name, 
        progress: `${student.enrolledSubjects.length * 10}%`,
        submissions: student.submissions
    }));
    res.json(studentData);
});


app.listen(port, () => {
    console.log(`ZimLearn is running on http://localhost:${port}`);
});
