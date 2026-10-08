// src/utils/email.js
// Updated to support HTML emails.
// Usage: await sendEmail(to, subject, htmlBody, textFallback)
// @ts-nocheck
const path       = require('path');
const nodemailer = require('nodemailer');

require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD,
    },
});

transporter.verify((error) => {
    if (error) {
        console.error('[email] SMTP connection error:', error.message);
    } else {
        console.log('[email] SMTP server ready');
    }
});

/**
 * Send an email.
 * @param {string} to        - Recipient email address
 * @param {string} subject   - Email subject
 * @param {string} html      - HTML body (shown in modern email clients)
 * @param {string} [text]    - Plain-text fallback (shown in old clients / preview)
 */
async function sendEmail(to, subject, html, text) {
    try {
        const info = await transporter.sendMail({
            from:    `"Sporta" <${process.env.SMTP_USERNAME}>`,
            to,
            subject,
            html,
            // If no plain-text fallback provided, strip tags as a basic fallback
            text: text || html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim(),
        });
        console.log(`[email] Sent to ${to}: ${info.messageId}`);
    } catch (error) {
        console.error('[email] Send error:', error.message);
        throw error;
    }
}

module.exports = { sendEmail };







/*// @ts-nocheck
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env'),
    debug: true //yaffichi les erreurs
 }); 


const nodemailer = require('nodemailer');

 
console.log('SMTP_USERNAME :', process.env.SMTP_USERNAME);
console.log('SMTP_PASSWORD :', process.env.SMTP_PASSWORD);

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD 
    }
});

transporter.verify((error, success) => {
    if (error) {
        console.log("SMTP Error:", error);
    } else {
        console.log("SMTP Server is ready to take our messages");
    } });

async function sendEmail(to, subject, text) {
    try {
        const info = await transporter.sendMail({
            from: process.env.SMTP_USERNAME,
            to, 
            subject,
            text
        });   
        console.log('Email sent: ' , info.messageId);
    } catch (error) {
        console.log('Error sending email:', error);
        throw error;
    }
}


module.exports = {
    sendEmail
};
*/