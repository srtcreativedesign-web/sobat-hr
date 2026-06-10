const fs = require('fs');

const sourcePath = './sobat-web/src/app/payroll/page.tsx';
const importPath = './sobat-web/src/app/payroll/import/page.tsx';

let content = fs.readFileSync(sourcePath, 'utf8');

// 1. Create the Link Tabs replacing activeTab buttons
const linkTabs = `          {/* Tabs */}
          <div className="mt-6 flex border-b border-gray-200">
            <Link
              href="/payroll"
              className={\`px-6 py-3 font-semibold text-sm border-b-2 transition-colors \${activeTab === 'data' ? 'border-[#1C3ECA] text-[#1C3ECA]' : 'border-transparent text-gray-500 hover:text-gray-700'}\`}
            >
              Data Payroll
            </Link>
            <Link
              href="/payroll/import"
              className={\`px-6 py-3 font-semibold text-sm border-b-2 transition-colors \${activeTab === 'import_export' ? 'border-[#1C3ECA] text-[#1C3ECA]' : 'border-transparent text-gray-500 hover:text-gray-700'}\`}
            >
              Import / Export
            </Link>
          </div>`;

// Actually we don't need activeTab anymore! We can hardcode the styling since they are separate pages!
const pageLinkTabs = `          {/* Tabs */}
          <div className="mt-6 flex border-b border-gray-200">
            <Link
              href="/payroll"
              className="px-6 py-3 font-semibold text-sm border-b-2 transition-colors border-[#1C3ECA] text-[#1C3ECA]"
            >
              Data Payroll
            </Link>
            <Link
              href="/payroll/import"
              className="px-6 py-3 font-semibold text-sm border-b-2 transition-colors border-transparent text-gray-500 hover:text-gray-700"
            >
              Import / Export
            </Link>
          </div>`;

const importLinkTabs = `          {/* Tabs */}
          <div className="mt-6 flex border-b border-gray-200">
            <Link
              href="/payroll"
              className="px-6 py-3 font-semibold text-sm border-b-2 transition-colors border-transparent text-gray-500 hover:text-gray-700"
            >
              Data Payroll
            </Link>
            <Link
              href="/payroll/import"
              className="px-6 py-3 font-semibold text-sm border-b-2 transition-colors border-[#1C3ECA] text-[#1C3ECA]"
            >
              Import / Export
            </Link>
          </div>`;

// Let's create page.tsx first
let pageContent = content;
pageContent = pageContent.replace(/const \[activeTab, setActiveTab\] = useState<'data' \| 'import_export'>\('data'\);\n/g, '');
pageContent = pageContent.replace(/const \[showMappingUI, setShowMappingUI\] = useState\(false\);\n/g, '');
pageContent = pageContent.replace(/const \[columnMapping, setColumnMapping\] = useState<Record<string, string>>\(\{\}\);\n/g, '');
pageContent = pageContent.replace(/const \[excelHeaders, setExcelHeaders\] = useState<Record<string, string>>\(\{\}\);\n/g, '');
pageContent = pageContent.replace(/const \[parsedRows, setParsedRows\] = useState<any\[\]>\(\[\]\);\n/g, '');
pageContent = pageContent.replace(/const \[selectedFile, setSelectedFile\] = useState<File \| null>\(null\);\n/g, '');
pageContent = pageContent.replace(/const \[uploadProgress, setUploadProgress\] = useState\(0\);\n/g, '');

// Ensure import Link from 'next/link'
if (!pageContent.includes("import Link from 'next/link';")) {
   pageContent = pageContent.replace("import { useRouter } from 'next/navigation';", "import { useRouter } from 'next/navigation';\nimport Link from 'next/link';");
}

// Remove Import UI block entirely
const importTabRegex = /\{\/\* Import\/Export Tab \*\/\}\s*\{\s*activeTab === 'import_export' && \([\s\S]*?\)\s*\}/;
pageContent = pageContent.replace(importTabRegex, '');

// Replace activeTab === 'data' wrapper
pageContent = pageContent.replace(/\{activeTab === 'data' && \(/g, '');
// And remove the closing ) } at the very bottom
pageContent = pageContent.replace(/<\/div>\s*\)\s*\}\s*<\/DashboardLayout\s*>/, '</div>\n    </DashboardLayout>');

// Replace Tabs
const tabsRegex = /\{\/\* Tabs \*\/\}\s*<div className="mt-6 flex border-b border-gray-200">[\s\S]*?<\/div>/;
pageContent = pageContent.replace(tabsRegex, pageLinkTabs);

// Remove handleFileChange, handleUpload, handleSaveImport
// Because it's hard to regex, we can just leave them in page.tsx as dead code, but it's better to remove them.
// Let's use string manipulation to find start and end of these functions if possible.
// Actually, it's safer to leave dead code than accidentally break the file. V8 will just tree-shake it, but ESLint might complain.
// So let's delete them cleanly.
pageContent = pageContent.replace(/const handleFileChange = \(e: React\.ChangeEvent<HTMLInputElement>\) => \{[\s\S]*?^\s*};\n/m, '');
// ... actually regex for functions with brackets is hard. I'll leave them, or just rely on tsc.

fs.writeFileSync(sourcePath, pageContent);

// Let's create import/page.tsx
let importContent = content;
importContent = importContent.replace(/export default function PayrollPage\(\) \{/g, 'export default function ImportPayrollPage() {');
importContent = importContent.replace(/\{activeTab === 'data' && \([\s\S]*?\{\/\* Import\/Export Tab \*\/\}/, '{/* Import/Export Tab */}');
importContent = importContent.replace(/\{\s*activeTab === 'import_export' && \(/, '');
// And remove the closing ) } at the very bottom
importContent = importContent.replace(/<\/div>\s*\)\s*\}\s*<\/DashboardLayout\s*>/, '</div>\n    </DashboardLayout>');
importContent = importContent.replace(tabsRegex, importLinkTabs);

// Ensure import Link from 'next/link'
if (!importContent.includes("import Link from 'next/link';")) {
   importContent = importContent.replace("import { useRouter } from 'next/navigation';", "import { useRouter } from 'next/navigation';\nimport Link from 'next/link';");
}

fs.writeFileSync(importPath, importContent);

console.log('Pages split successfully');

