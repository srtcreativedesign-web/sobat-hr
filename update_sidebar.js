const fs = require('fs');
const path = './sobat-web/src/components/Sidebar.tsx';
let content = fs.readFileSync(path, 'utf8');

// The user has subItems for Payroll List
// {
//   name: 'Payroll List',
//   href: '/payroll',
//   icon: null
// },
// {
//   name: 'Overtime',
//   href: '/payroll/overtime',
//   icon: null
// }

const newSubItem = `        {
          name: 'Overtime',
          href: '/payroll/overtime',
          icon: null
        },
        {
          name: 'Import / Export',
          href: '/payroll/import',
          icon: null
        }`;

content = content.replace(
  `        {
          name: 'Overtime',
          href: '/payroll/overtime',
          icon: null
        }`,
  newSubItem
);

fs.writeFileSync(path, content);
console.log('Sidebar updated');
