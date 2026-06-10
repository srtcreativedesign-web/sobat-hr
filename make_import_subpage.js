const fs = require('fs');
const path = require('path');

const pagePath = './sobat-web/src/app/payroll/page.tsx';
const importPath = './sobat-web/src/app/payroll/import/page.tsx';

let content = fs.readFileSync(pagePath, 'utf8');

// The original file uses `showUploadModal`.
// 1. Create import/page.tsx from this content

// In import/page.tsx:
// - Replace 'export default function PayrollPage' with 'export default function ImportPayrollPage'
// - Delete the Data Table UI wrapper: everything before {/* Upload Modal */}
//   Wait, we must keep <DashboardLayout>, {/* Header */}, etc.
//   The Header has the "Import Excel" button.
//   We need the Sub Navigation Tabs.

const tabsUI = `
          {/* Sub Navigation Tabs */}
          <div className="flex px-8 border-b border-gray-200">
            <Link
              href="/payroll"
              className="px-6 py-4 text-sm font-semibold border-b-2 border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 transition-colors"
            >
              Data Payroll
            </Link>
            <Link
              href="/payroll/import"
              className="px-6 py-4 text-sm font-semibold border-b-2 border-[#1C3ECA] text-[#1C3ECA] transition-colors"
            >
              Import / Export
            </Link>
          </div>
`;

const pageTabsUI = `
          {/* Sub Navigation Tabs */}
          <div className="flex px-8 border-b border-gray-200">
            <Link
              href="/payroll"
              className="px-6 py-4 text-sm font-semibold border-b-2 border-[#1C3ECA] text-[#1C3ECA] transition-colors"
            >
              Data Payroll
            </Link>
            <Link
              href="/payroll/import"
              className="px-6 py-4 text-sm font-semibold border-b-2 border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 transition-colors"
            >
              Import / Export
            </Link>
          </div>
`;

// Build Import Page
let importContent = content.replace('export default function PayrollPage()', 'export default function ImportPayrollPage()');
if (!importContent.includes("import Link from 'next/link';")) {
    importContent = importContent.replace("import { useRouter } from 'next/navigation';", "import { useRouter } from 'next/navigation';\nimport Link from 'next/link';");
}

// In import page, remove the Data Table UI.
// Find the end of the header
const headerEnd = importContent.indexOf('</div>\n          </div>\n        </div>\n      </div>');
if (headerEnd !== -1) {
    const splitIndex = headerEnd + '</div>\n          </div>\n        </div>\n      </div>'.length;
    let beforeHeaderEnd = importContent.substring(0, splitIndex);
    let afterHeaderEnd = importContent.substring(splitIndex);

    // Insert Tabs
    beforeHeaderEnd += '\n' + tabsUI + '\n';

    // Now, we want to KEEP the Import UI and REMOVE everything else in the body.
    // The Import UI starts at {/* Upload Modal */}
    const modalStart = afterHeaderEnd.indexOf('{/* Upload Modal */}');
    const importUIBlock = afterHeaderEnd.substring(modalStart);

    // Remove the `showUploadModal && (` wrapper from Import UI
    let cleanImportUI = importUIBlock.replace(/\{\s*showUploadModal && \(\s*/, '');
    cleanImportUI = cleanImportUI.replace(/<div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 text-black">\s*<div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4">/, '<div className="p-8 max-w-5xl mx-auto"><div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8">');
    
    // Remove the trailing ) } before </DashboardLayout>
    cleanImportUI = cleanImportUI.replace(/\)\s*\}\s*<\/DashboardLayout\s*>/, '</DashboardLayout>');

    importContent = beforeHeaderEnd + '\n' + cleanImportUI;
}

// Fix endpoints in importContent
importContent = importContent.replace(
  `importEndpoint = '/payrolls/wrapping/import';
      if (selectedDivision === 'hans') importEndpoint = '/payrolls/hans/import';`,
  `importEndpoint = '/payrolls/wrapping/import';
      if (selectedDivision === 'hans') importEndpoint = '/payrolls/hans/import';
      
      if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        importEndpoint = '/payrolls/retail/import/parse-headers';
        formData.append('division_type', selectedDivision);
      }`
);

// We must also add the Download Template button to the Import page header, instead of "Import Excel" button
importContent = importContent.replace(
  `<button
                onClick={() => setShowUploadModal(true)}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-[#60A5FA] to-[#93C5FD] text-[#1C3ECA] rounded-xl font-semibold hover:shadow-lg transition-all transform hover:scale-[1.02]"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                </svg>
                Import Excel
              </button>`,
  ``
);

fs.writeFileSync(importPath, importContent);

// Build Data Page
let pageContent = content;
if (!pageContent.includes("import Link from 'next/link';")) {
    pageContent = pageContent.replace("import { useRouter } from 'next/navigation';", "import { useRouter } from 'next/navigation';\nimport Link from 'next/link';");
}

const pHeaderEnd = pageContent.indexOf('</div>\n          </div>\n        </div>\n      </div>');
if (pHeaderEnd !== -1) {
    const splitIndex = pHeaderEnd + '</div>\n          </div>\n        </div>\n      </div>'.length;
    let beforeHeaderEnd = pageContent.substring(0, splitIndex);
    let afterHeaderEnd = pageContent.substring(splitIndex);

    // Insert Tabs
    beforeHeaderEnd += '\n' + pageTabsUI + '\n';

    // Remove Import UI from page.tsx
    const modalStart = afterHeaderEnd.indexOf('{/* Upload Modal */}');
    if (modalStart !== -1) {
        afterHeaderEnd = afterHeaderEnd.substring(0, modalStart) + '    </DashboardLayout>\n  );\n}\n';
    }

    pageContent = beforeHeaderEnd + afterHeaderEnd;
}

// Change "Import Excel" button to act as Link or router.push
pageContent = pageContent.replace(
  `onClick={() => setShowUploadModal(true)}`,
  `onClick={() => router.push('/payroll/import')}`
);

fs.writeFileSync(pagePath, pageContent);

console.log('Successfully created Sub Page Tabs');
