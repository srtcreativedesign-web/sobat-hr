const fs = require('fs');
const files = ['./sobat-web/src/app/payroll/page.tsx', './sobat-web/src/app/payroll/import/page.tsx'];

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/\\n/g, '\n');
  fs.writeFileSync(file, content);
}
console.log('Fixed literal newlines');
