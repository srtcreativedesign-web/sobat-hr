const fs = require('fs');
const file = './sobat-web/src/app/payroll/import/page.tsx';
let content = fs.readFileSync(file, 'utf8');

const replacement = `      let data = response.data;
      
      // Auto-simulate for retail hybrid imports
      if (data && data.requiresMapping) {
        try {
          const simFormData = new FormData();
          simFormData.append('file', selectedFile);
          simFormData.append('mapping', JSON.stringify(data.default_mapping));
          simFormData.append('headerRowIndex', data.headerRowIndex);
          
          const simulateResponse = await apiClient.post('/payrolls/retail/import/simulate', simFormData, {
            headers: { 'Content-Type': 'multipart/form-data' }
          });
          data = simulateResponse.data;
        } catch (simError: any) {
          alert(simError.response?.data?.message || 'Gagal simulasi data');
          setUploadProgress(0);
          return;
        }
      }

      if (data && Array.isArray(data.rows)) {`;

content = content.replace(/const data = response\.data;\s*if \(data && Array\.isArray\(data\.rows\)\) \{/, replacement);
fs.writeFileSync(file, content);
console.log('Fixed auto-simulate logic!');
