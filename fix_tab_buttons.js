const fs = require('fs');
const path = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

content = content.replace(
  `const [showUploadModal, setShowUploadModal] = useState(false);`,
  `const [activeTab, setActiveTab] = useState<'data' | 'import_export'>('data');\n  const [showMappingUI, setShowMappingUI] = useState(false);\n  const [columnMapping, setColumnMapping] = useState<Record<string, string>>({});\n  const [excelHeaders, setExcelHeaders] = useState<Record<string, string>>({});`
);

content = content.replace(
  `{/* Period Filter */}`,
  `{/* Tabs */}
          <div className="mt-6 flex border-b border-gray-200">
            <button
              onClick={() => setActiveTab('data')}
              className={\`px-6 py-3 font-semibold text-sm border-b-2 transition-colors \${activeTab === 'data' ? 'border-[#1C3ECA] text-[#1C3ECA]' : 'border-transparent text-gray-500 hover:text-gray-700'}\`}
            >
              Data Payroll
            </button>
            <button
              onClick={() => setActiveTab('import_export')}
              className={\`px-6 py-3 font-semibold text-sm border-b-2 transition-colors \${activeTab === 'import_export' ? 'border-[#1C3ECA] text-[#1C3ECA]' : 'border-transparent text-gray-500 hover:text-gray-700'}\`}
            >
              Import / Export
            </button>
          </div>
          
          {/* Period Filter */}`
);

fs.writeFileSync(path, content);
console.log('Tabs added');
