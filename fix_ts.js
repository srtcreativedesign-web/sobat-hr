const fs = require('fs');
const path = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// Fix 1: Change onClick={() => setShowUploadModal(true)} to setActiveTab('import_export')
content = content.replace(
  `onClick={() => setShowUploadModal(true)}`,
  `onClick={() => setActiveTab('import_export')}`
);

// Fix 2: Remove setShowUploadModal(false); from the X button
content = content.replace(
  /setShowUploadModal\(false\);/g,
  `setActiveTab('data');`
);

fs.writeFileSync(path, content);
console.log('Fixed TS errors');
