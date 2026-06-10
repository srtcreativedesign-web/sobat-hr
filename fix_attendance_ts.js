const fs = require('fs');
const path = './sobat-web/src/app/attendance/operasional/page.tsx';
let content = fs.readFileSync(path, 'utf8');

content = content.replace(
  `{selectedAttendance.location_address || '-'}`,
  `{(selectedAttendance as any).location_address || '-'}`
);

fs.writeFileSync(path, content);
console.log('Fixed attendance TS error');
