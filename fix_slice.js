const fs = require('fs');
const path = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// Find the start of {/* Import/Export Tab */}
const importStartIndex = content.indexOf('{/* Import/Export Tab */}');
if (importStartIndex !== -1) {
    // Find the end: </DashboardLayout>
    const endLayoutIndex = content.lastIndexOf('</DashboardLayout>');
    if (endLayoutIndex !== -1) {
        content = content.substring(0, importStartIndex) + '    </DashboardLayout>\n  );\n}\n';
    }
}

fs.writeFileSync(path, content);
console.log('Sliced out Import UI from page.tsx');
