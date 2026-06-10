const fs = require('fs');
const path = './src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// 1. Change {showUploadModal && ( to {activeTab === 'import_export' && (
content = content.replace(
  `{/* Upload Modal */}
      {
        showUploadModal && (`,
  `{/* Import/Export Tab */}
      {
        activeTab === 'import_export' && (`
);

// 2. Remove the modal overlay wrappers
content = content.replace(
  `<div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 text-black">
            <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-4xl w-full mx-4 max-h-[90vh] overflow-hidden flex flex-col">`,
  `<div className="p-8">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 max-w-5xl mx-auto flex flex-col">`
);

// 3. Close the activeTab === 'data' wrapper BEFORE {/* Import/Export Tab */}
content = content.replace(
  `{/* Import/Export Tab */}`,
  `  </>
      )}

      {/* Import/Export Tab */}`
);

// 4. Change the header inside the modal to include the export ZIP button
content = content.replace(
  `<div className="flex items-center justify-between mb-6 flex-shrink-0">
                <h3 className="text-2xl font-bold text-gray-900">Import Excel</h3>
                <button
                  onClick={() => {
                    setShowUploadModal(false);
                    setSelectedFile(null);
                    setUploadProgress(0);
                  }}
                  className="text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>`,
  `<div className="flex items-center justify-between mb-6 flex-shrink-0 border-b pb-4">
                <h3 className="text-2xl font-bold text-gray-900">Import / Export Payroll</h3>
                <div className="flex gap-3">
                  <button
                    onClick={async () => {
                      try {
                        const response = await apiClient.get('/payrolls/template/download', {
                          responseType: 'blob',
                        });
                        const url = window.URL.createObjectURL(new Blob([response.data]));
                        const link = document.createElement('a');
                        link.href = url;
                        link.setAttribute('download', \`Template_Import_Payroll_\${new Date().toISOString().split('T')[0]}.xlsx\`);
                        document.body.appendChild(link);
                        link.click();
                        link.remove();
                      } catch (error) {
                        alert('Gagal download template');
                      }
                    }}
                    className="flex items-center gap-2 px-4 py-2 border-2 border-[#60A5FA] text-[#1C3ECA] rounded-lg font-semibold hover:bg-[#60A5FA] hover:text-[#1C3ECA] transition-all"
                  >
                    Download Template
                  </button>
                  <button
                    onClick={handleBulkDownload}
                    className="flex items-center gap-2 px-4 py-2 bg-[#1C3ECA] text-white rounded-lg font-semibold hover:bg-[#2d1e24] transition-colors"
                  >
                    Export ZIP Slip Gaji
                  </button>
                </div>
              </div>
              
              <div className="flex items-center gap-4 mb-6 p-4 bg-gray-50 rounded-xl border">
                <div className="flex-1">
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Divisi Target</label>
                  <select
                    value={selectedDivision}
                    onChange={(e) => setSelectedDivision(e.target.value as any)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#1C3ECA] text-sm"
                  >
                    <option value="office">Office (Pusat)</option>
                    <option value="fnb">FnB</option>
                    <option value="tungtau">FnB Tungtau</option>
                    <option value="maximum">FnB Maximum 600</option>
                    <option value="minimarket">Minimarket</option>
                    <option value="reflexiology">Reflexiology</option>
                    <option value="wrapping">Wrapping</option>
                    <option value="hans">Hans</option>
                    <option value="cellular">Cellular</option>
                    <option value="money_changer">Money Changer</option>
                  </select>
                </div>
                <div className="flex-1">
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Bulan</label>
                  <select
                    value={selectedMonth}
                    onChange={(e) => setSelectedMonth(Number(e.target.value))}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#1C3ECA] text-sm"
                  >
                    <option value={0}>Pilih Bulan...</option>
                    <option value="1">Januari</option><option value="2">Februari</option><option value="3">Maret</option><option value="4">April</option><option value="5">Mei</option><option value="6">Juni</option><option value="7">Juli</option><option value="8">Agustus</option><option value="9">September</option><option value="10">Oktober</option><option value="11">November</option><option value="12">Desember</option>
                  </select>
                </div>
                <div className="flex-1">
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Tahun</label>
                  <select
                    value={selectedYear}
                    onChange={(e) => setSelectedYear(Number(e.target.value))}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-[#1C3ECA] text-sm"
                  >
                    <option value={0}>Pilih Tahun...</option>
                    <option value="2024">2024</option><option value="2025">2025</option><option value="2026">2026</option><option value="2027">2027</option>
                  </select>
                </div>
              </div>`
);

// 5. Modify Cancel button behavior in Import tab
content = content.replace(
  `onClick={() => {
                      setShowUploadModal(false);
                      setSelectedFile(null);
                      setUploadProgress(0);
                    }}
                    className="flex-1 px-4 py-3 border-2 border-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-50 transition-colors"
                  >
                    Cancel`,
  `onClick={() => {
                      setSelectedFile(null);
                      setUploadProgress(0);
                    }}
                    className="flex-1 px-4 py-3 border-2 border-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-50 transition-colors"
                  >
                    Clear File`
);

// Modify after successful saving
content = content.replace(
  `setShowUploadModal(false);
                              setParsedRows([]);
                              setSelectedFile(null);
                              setUploadProgress(0);
                              fetchPayrolls();`,
  `                           setParsedRows([]);
                              setSelectedFile(null);
                              setUploadProgress(0);
                              fetchPayrolls();
                              setActiveTab('data'); // Go back to data view on success`
);

content = content.replace(
  `setShowUploadModal(false);
        setSelectedFile(null);`,
  `setSelectedFile(null);`
);

fs.writeFileSync(path, content);
console.log('Script done');
