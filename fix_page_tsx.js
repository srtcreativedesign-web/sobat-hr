const fs = require('fs');
const path = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// 1. Download slip from All tab
content = content.replace(
    /let endpoint = `\/payrolls\/\$\{selectedPayroll\.id\}\/slip`;\s+if \(selectedDivision === 'fnb'\)/,
    `let endpoint = \`/payrolls/\${selectedPayroll.id}/slip\`;
        let targetDiv = selectedDivision;
        if (targetDiv === 'all') {
            const divType = (selectedPayroll.details?.division_type || '').toLowerCase();
            const divName = (selectedPayroll.division?.name || selectedPayroll.employee?.division?.name || divType || '').toLowerCase();
            targetDiv = divName.includes('money') ? 'money_changer' :
                        divName.includes('fnb') || divName.includes('food') ? 'fnb' :
                        divName.includes('maximum') ? 'maximum' :
                        divName.includes('tungtau') ? 'tungtau' :
                        divName.includes('mini') ? 'minimarket' :
                        divName.includes('reflex') ? 'reflexiology' :
                        divName.includes('wrap') ? 'wrapping' :
                        divName.includes('hans') || divName.includes('security') ? 'hans' :
                        divName.includes('cell') ? 'cellular' : 'office';
        }
        if (targetDiv === 'fnb')`
);
content = content.replace(
    /if \(\['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'\]\.includes\(selectedDivision\)\)/g,
    `if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(typeof targetDiv !== 'undefined' ? targetDiv : selectedDivision))`
);

// 2. Approve from All tab
content = content.replace(
    /let endpoint = `\/payrolls\/\$\{pendingApprovalId\}\/status`;\s+let additionalPayload = \{\};\s+if \(selectedDivision === 'fnb'\)/,
    `let endpoint = \`/payrolls/\${pendingApprovalId}/status\`;
        let additionalPayload = {};
        
        let targetDiv = selectedDivision;
        if (targetDiv === 'all') {
            const payroll = payrolls.find(p => p.id === pendingApprovalId);
            if (payroll) {
              const divType = (payroll.details?.division_type || '').toLowerCase();
              const divName = (payroll.division?.name || payroll.employee?.division?.name || divType || '').toLowerCase();
              
              targetDiv = divName.includes('money') ? 'money_changer' :
                          divName.includes('fnb') || divName.includes('food') ? 'fnb' :
                          divName.includes('maximum') ? 'maximum' :
                          divName.includes('tungtau') ? 'tungtau' :
                          divName.includes('mini') ? 'minimarket' :
                          divName.includes('reflex') ? 'reflexiology' :
                          divName.includes('wrap') ? 'wrapping' :
                          divName.includes('hans') || divName.includes('security') ? 'hans' :
                          divName.includes('cell') ? 'cellular' : 'office';
            }
        }

        if (targetDiv === 'fnb')`
);

// 3. Import Alert
content = content.replace(
    /if \(data\.failed && data\.failed\.length > 0\) \{[\s\S]*?\/\/ console\.log\('All failed rows:', data\.failed\);\s+\}/,
    `// Show errors if any
                            const errorList = data.failed || data.errors;
                            if (errorList && errorList.length > 0) {
                              message += '\\n\\nBaris yang gagal:';
                              errorList.slice(0, 5).forEach((fail: any) => {
                                if (typeof fail === 'string') {
                                  message += \`\\n- \${fail}\`;
                                } else {
                                  message += \`\\n- Row \${fail.row || '?'}: \${fail.employee_name || 'Unknown'} - \${fail.reason || 'Unknown error'}\`;
                                }
                              });
                              if (errorList.length > 5) {
                                message += \`\\n... dan \${errorList.length - 5} lainnya (lihat console)\`;
                              }
                            }`
);
content = content.replace(
    /if \(data\.summary && data\.summary\.saved > 0\) \{\s+setParsedRows\(\[\]\);/,
    `if ((data.summary && data.summary.saved > 0) || (data.saved !== undefined && data.saved > 0)) {
                              setParsedRows([]);`
);

// 4. Prevent Bulk Approve from All Tab
content = content.replace(
    /\{activeTab === 'data' && selectedIds\.length > 0 && \(\s*<button\s*onClick=\{\(\) => \{\s*setIsBulkApproval\(true\);/,
    `{activeTab === 'data' && selectedIds.length > 0 && (
                      <button
                        onClick={() => {
                          if (selectedDivision === 'all') {
                            alert('Silakan pilih divisi spesifik terlebih dahulu untuk melakukan Bulk Approve.');
                            return;
                          }
                          setIsBulkApproval(true);`
);

fs.writeFileSync(path, content);
console.log('Fixed page.tsx');
