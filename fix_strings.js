const fs = require('fs');
const file = './sobat-web/src/app/payroll/import/page.tsx';
let content = fs.readFileSync(file, 'utf8');

// Fix 1: join('\n')
content = content.replace(/data\.errors\.join\('[\r\n]+'\)/g, 'data.errors.join(`\\n`)');

// Fix 2: message += '\n\nBaris yang gagal:'
content = content.replace(/message \+= '[\r\n]+Baris yang gagal:';/g, 'message += `\\n\\nBaris yang gagal:`;');

fs.writeFileSync(file, content);
console.log('Fixed broken strings');
