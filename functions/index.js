const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.getTeacherData = functions.https.onCall((data, context) => {
    // This is where we would fetch data for the teacher portal
    // For now, we'll just return some dummy data
    return {
        students: [
            { name: 'John Doe', progress: '75%' },
            { name: 'Jane Doe', progress: '85%' }
        ]
    };
});

exports.getParentData = functions.https.onCall((data, context) => {
    // This is where we would fetch data for the parent portal
    // For now, we'll just return some dummy data
    return {
        child: {
            name: 'John Doe',
            progress: '75%',
            enrolledSubjects: ['English', 'Mathematics', 'Science']
        }
    };
});
