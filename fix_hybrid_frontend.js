const fs = require('fs');
const path = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// 1. In handleUpload, change the endpoint
const oldUploadEndpoint = `      if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        importEndpoint = '/payrolls/retail/import';
        formData.append('division_type', selectedDivision);
      }`;

const newUploadEndpoint = `      if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        // ALWAYS use parse-headers first to give the mapping UI!
        importEndpoint = '/payrolls/retail/import/parse-headers';
        formData.append('division_type', selectedDivision);
      }`;

content = content.replace(oldUploadEndpoint, newUploadEndpoint);

// 2. In handleUpload response
const oldResponseHandling = `      const data = response.data;
      if ((selectedDivision === 'wrapping' || selectedDivision === 'money_changer') && data.headers) {`;

const newResponseHandling = `      const data = response.data;
      if (data.requiresMapping && data.headers) {`;

content = content.replace(oldResponseHandling, newResponseHandling);

// 3. In handleSimulate, update the endpoint
const oldSimulateEndpoint = `const response = await apiClient.post('/payrolls/wrapping/import/simulate', formData, {`;

const newSimulateEndpoint = `
      // Inject division type
      if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        formData.append('division_type', selectedDivision);
      }
      
      const simulateEndpoint = ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)
        ? '/payrolls/retail/import/simulate'
        : '/payrolls/wrapping/import/simulate';

      const response = await apiClient.post(simulateEndpoint, formData, {`;

content = content.replace(oldSimulateEndpoint, newSimulateEndpoint);

fs.writeFileSync(path, content);
console.log('Frontend mapping endpoints updated!');
