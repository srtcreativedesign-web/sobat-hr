const fs = require('fs');
const pagePath = './sobat-web/src/app/payroll/page.tsx';
const importPath = './sobat-web/src/app/payroll/import/page.tsx';

const pageContent = fs.readFileSync(pagePath, 'utf8');
let importContent = fs.readFileSync(importPath, 'utf8');

// Extract the Filter Section from page.tsx
const filterStartStr = '{/* Filter Section */}';
const filterStart = pageContent.indexOf(filterStartStr);
const filterEndStr = '{/* Payroll Table */}';
const filterEnd = pageContent.indexOf(filterEndStr);

if (filterStart !== -1 && filterEnd !== -1) {
    let filterSection = pageContent.substring(filterStart, filterEnd);
    
    // Let's remove the Search bar from the Import page filter, since search is irrelevant for import.
    // The search bar is: <div className="flex items-center gap-2 flex-grow max-w-sm px-4"> ... </div>
    const searchStartStr = '<div className="flex items-center gap-2 flex-grow max-w-sm px-4">';
    const searchStart = filterSection.indexOf(searchStartStr);
    if (searchStart !== -1) {
        const nextFilterStr = '{/* Period Filter */}';
        const searchEnd = filterSection.indexOf(nextFilterStr);
        if (searchEnd !== -1) {
            filterSection = filterSection.substring(0, searchStart) + filterSection.substring(searchEnd);
        }
    }

    // Insert into import/page.tsx just before {/* Upload Modal */}
    const modalStartStr = '{/* Upload Modal */}';
    if (!importContent.includes(filterStartStr)) {
        importContent = importContent.replace(modalStartStr, filterSection + '\n      ' + modalStartStr);
        fs.writeFileSync(importPath, importContent);
        console.log('Filter section injected into import/page.tsx');
    } else {
        console.log('Filter section already exists in import/page.tsx');
    }
} else {
    console.log('Could not find Filter Section in page.tsx');
}
