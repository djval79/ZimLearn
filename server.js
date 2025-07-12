const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3001;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'ZimLearn')));

// ... (existing chat logic)

// Dummy data
const allSubjects = [ 'English', 'Mathematics', 'Science', 'History', 'Geography', 'Shona', 'Ndebele', 'Commerce', 'Agriculture', 'Economics' ];
let users = [
    { name: 'Test Student', email: 'student@example.com', password: 'Password1', role: 'student', enrolledSubjects: ['English', 'Mathematics'], submissions: [], studyGroups: [], teacherRecommendations: [] },
    { name: 'Test Teacher', email: 'teacher@example.com', password: 'Password1', role: 'teacher', children: [] }
];
let studyGroups = [
    { id: 1, subject: 'English', name: 'English Literature O-Level', members: [] },
    { id: 2, subject: 'Mathematics', name: 'Advanced Mathematics A-Level', members: [] }
];

// ... (existing user and auth endpoints)
app.post('/signup', (req, res) => {
    const { name, email, password, role } = req.body;
    if (users.find(user => user.email === email)) {
        return res.status(400).json({ message: 'User already exists' });
    }
    const newUser = { name, email, password, role, enrolledSubjects: [], children: [], submissions: [], studyGroups: [], teacherRecommendations: [] };
    users.push(newUser);
    res.status(201).json({ message: 'User created successfully' });
});

app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const user = users.find(user => user.email === email && user.password === password);
    if (user) {
        const userToSend = { 
            name: user.name, 
            email: user.email, 
            role: user.role, 
            enrolledSubjects: user.enrolledSubjects, 
            children: user.children,
            studyGroups: user.studyGroups,
            teacherRecommendations: user.teacherRecommendations
        };
        res.json({ message: 'Login successful', user: userToSend });
    } else {
        res.status(401).json({ message: 'Invalid credentials' });
    }
});

app.get('/subjects-list', (req, res) => {
    res.json(allSubjects);
});

app.post('/recommend-subject', (req, res) => {
    const { teacherEmail, studentEmail, subject } = req.body;
    const teacher = users.find(user => user.email === teacherEmail);
    const student = users.find(user => user.email === studentEmail);

    if (!teacher || teacher.role !== 'teacher') {
        return res.status(403).json({ message: 'Only teachers can recommend subjects.' });
    }
    if (!student || student.role !== 'student') {
        return res.status(404).json({ message: 'Student not found.' });
    }

    if (!student.teacherRecommendations) {
        student.teacherRecommendations = [];
    }

    if (!student.teacherRecommendations.find(rec => rec.subject === subject)) {
        student.teacherRecommendations.push({ subject, from: teacher.name });
    }
    
    res.json({ message: `Successfully recommended ${subject} to ${student.name}.` });
});


// ... (the rest of the existing endpoints for study groups, child data, students, and submissions)
// Get all study groups
app.get('/study-groups', (req, res) => {
    res.json(studyGroups);
});

// Join a study group
app.post('/join-group', (req, res) => {
    const { studentEmail, groupId } = req.body;
    const student = users.find(user => user.email === studentEmail);
    const group = studyGroups.find(g => g.id === groupId);

    if (!student || !group) {
        return res.status(404).json({ message: 'Student or group not found' });
    }
    
    if (!student.studyGroups.includes(groupId)) {
        student.studyGroups.push(groupId);
        group.members.push(studentEmail);
        res.json({ message: `Successfully joined ${group.name}.`, user: student });
    } else {
        res.status(400).json({ message: 'You are already a member of this group.' });
    }
});


// Get data for a specific child
app.get('/child-data/:email', (req, res) => {
    const childEmail = req.params.email;
    const child = users.find(user => user.email === childEmail);

    if (child && child.role === 'student') {
        const childData = {
            name: child.name,
            progress: `${child.enrolledSubjects.length * 10}%`,
            enrolledSubjects: child.enrolledSubjects,
            submissions: child.submissions
        };
        res.json(childData);
    } else {
        res.status(404).json({ message: 'Student not found' });
    }
});


// Get all students
app.get('/students', (req, res) => {
    const students = users.filter(user => user.role === 'student');
    const studentData = students.map(student => ({ 
        name: student.name, 
        email: student.email,
        progress: `${student.enrolledSubjects.length * 10}%`,
        submissions: student.submissions,
        enrolledSubjects: student.enrolledSubjects
    }));
    res.json(studentData);
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

app.listen(port, () => {
    console.log(`ZimLearn is running on http://localhost:${port}`);
});
