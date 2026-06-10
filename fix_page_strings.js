const fs = require('fs');
const file = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(/alert\('Gagal menyimpan data:[\r\n]+' \+ data\.errors\.join\('[\r\n]+'\)\);/g, 'alert(`Gagal menyimpan data:\\n` + data.errors.join(`\\n`));');
content = content.replace(/data\.errors\.join\('[\r\n]+'\)/g, 'data.errors.join(`\\n`)');
content = content.replace(/message \+= '[\r\n]+Baris yang gagal:';/g, 'message += `\\n\\nBaris yang gagal:`;');

fs.writeFileSync(file, content);
console.log('Fixed broken strings in page.tsx');
