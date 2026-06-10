const fs = require('fs');
const importPath = './sobat-web/src/app/payroll/import/page.tsx';

let importContent = fs.readFileSync(importPath, 'utf8');
importContent = importContent.replace(/\{\/\* Main Content \*\/\}\s*<div className="p-8">/g, '');

fs.writeFileSync(importPath, importContent);
console.log('Fixed missing closing div');
