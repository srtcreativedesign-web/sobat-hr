const fs = require('fs');
const path = './src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// 1. fetchPayrolls
const fetchPayrollsOld = `      let endpoint = '';
      if (selectedDivision === 'office') endpoint = '/payrolls/ho';
      if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';
      if (selectedDivision === 'maximum') endpoint = '/payrolls/maximum';
    if (selectedDivision === 'tungtau') endpoint = '/payrolls/tungtau';
      if (selectedDivision === 'minimarket') endpoint = '/payrolls/mm';
      if (selectedDivision === 'reflexiology') endpoint = '/payrolls/ref';
      if (selectedDivision === 'wrapping') endpoint = '/payrolls/wrapping';
      if (selectedDivision === 'hans') endpoint = '/payrolls/hans';
      if (selectedDivision === 'cellular') endpoint = '/payroll-cellullers'; // New Endpoint
      if (selectedDivision === 'money_changer') endpoint = '/payrolls/money-changer';

      const response = await apiClient.get(endpoint, {
        params: {
          page: currentPage,
          ...(selectedMonth !== 0 && { month: selectedMonth }),
          ...(selectedYear !== 0 && { year: selectedYear }),
          ...(debouncedSearch && { search: debouncedSearch })
        }
      });`;

const fetchPayrollsNew = `      let endpoint = '';
      let additionalParams = {};
      if (selectedDivision === 'office') endpoint = '/payrolls/ho';
      if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';
      if (selectedDivision === 'maximum') endpoint = '/payrolls/maximum';
      if (selectedDivision === 'tungtau') endpoint = '/payrolls/tungtau';
      
      if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        endpoint = '/payrolls/retail';
        additionalParams = { division_type: selectedDivision };
      }

      const response = await apiClient.get(endpoint, {
        params: {
          page: currentPage,
          ...(selectedMonth !== 0 && { month: selectedMonth }),
          ...(selectedYear !== 0 && { year: selectedYear }),
          ...(debouncedSearch && { search: debouncedSearch }),
          ...additionalParams
        }
      });`;

content = content.replace(fetchPayrollsOld, fetchPayrollsNew);

// 2. handleConfirmApproval
const confirmApprovalOld = `        let endpoint = \`/payrolls/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'fnb') endpoint = \`/payrolls/fnb/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'maximum') endpoint = \`/payrolls/maximum/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'tungtau') endpoint = \`/payrolls/tungtau/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'minimarket') endpoint = \`/payrolls/mm/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'reflexiology') endpoint = \`/payrolls/ref/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'wrapping') endpoint = \`/payrolls/wrapping/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'hans') endpoint = \`/payrolls/hans/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'office') endpoint = \`/payrolls/ho/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'cellular') endpoint = \`/payroll-cellullers/\${pendingApprovalId}/status\`; // New Endpoint
        if (selectedDivision === 'money_changer') endpoint = \`/payrolls/wrapping/\${pendingApprovalId}/status\`;

        // Note: FNB uses updateStatus which takes 'status' and 'approval_signature'
        // Generic Controller might need update. Assuming Generic uses PATCH /payrolls/{id}/status

        // console.log('Approving with Endpoint:', endpoint, 'ID:', pendingApprovalId); // DEBUG

        await apiClient.patch(endpoint, {
          status: 'approved',
          approval_signature: signatureData,
          signer_name: signerName,
          notes: approvalNotes
        });`;

const confirmApprovalNew = `        let endpoint = \`/payrolls/\${pendingApprovalId}/status\`;
        let additionalPayload = {};
        if (selectedDivision === 'fnb') endpoint = \`/payrolls/fnb/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'maximum') endpoint = \`/payrolls/maximum/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'tungtau') endpoint = \`/payrolls/tungtau/\${pendingApprovalId}/status\`;
        if (selectedDivision === 'office') endpoint = \`/payrolls/ho/\${pendingApprovalId}/status\`;
        
        if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
          endpoint = \`/payrolls/retail/\${pendingApprovalId}/status\`;
          additionalPayload = { division_type: selectedDivision };
        }

        await apiClient.patch(endpoint, {
          status: 'approved',
          approval_signature: signatureData,
          signer_name: signerName,
          notes: approvalNotes,
          ...additionalPayload
        });`;

content = content.replace(confirmApprovalOld, confirmApprovalNew);

// 3. Generate Slip in Table Line 815
const generateSlipOld1 = `                                        : selectedDivision === 'wrapping'
                                        ? \`/payrolls/wrapping/\${payroll.id}/slip\`
                                        : selectedDivision === 'hans'
                                          ? \`/payrolls/hans/\${payroll.id}/slip\`
                                          : selectedDivision === 'cellular'
                                            ? \`/payroll-cellullers/\${payroll.id}/slip\`
                                            : selectedDivision === 'money_changer'
                                              ? \`/payrolls/money-changer/\${payroll.id}/slip\`
                                            : selectedDivision === 'office'
                                              ? \`/payrolls/ho/\${payroll.id}/slip\`
                                              : \`/payrolls/\${payroll.id}/slip\`;

                                const response = await apiClient.get(endpoint, {
                                  responseType: 'blob',
                                });`;

const generateSlipNew1 = `                                        : ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)
                                          ? \`/payrolls/retail/\${payroll.id}/slip\`
                                          : selectedDivision === 'office'
                                            ? \`/payrolls/ho/\${payroll.id}/slip\`
                                            : \`/payrolls/\${payroll.id}/slip\`;

                                const response = await apiClient.get(endpoint, {
                                  responseType: 'blob',
                                  params: ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision) ? { division_type: selectedDivision } : {}
                                });`;

content = content.replace(generateSlipOld1, generateSlipNew1);

// 4. Generate Slip in Modal Line 1213
const generateSlipOld2 = `                        const endpoint = selectedDivision === 'maximum'
                          ? \`/payrolls/maximum/\${selectedPayroll.id}/slip\`
                          : selectedDivision === 'tungtau'
                          ? \`/payrolls/tungtau/\${selectedPayroll.id}/slip\`
                          : selectedDivision === 'fnb'
                          ? \`/payrolls/fnb/\${selectedPayroll.id}/slip\`
                          : selectedDivision === 'minimarket'
                            ? \`/payrolls/mm/\${selectedPayroll.id}/slip\`
                            : selectedDivision === 'reflexiology'
                              ? \`/payrolls/ref/\${selectedPayroll.id}/slip\`
                              : selectedDivision === 'wrapping'
                                ? \`/payrolls/wrapping/\${selectedPayroll.id}/slip\`
                                : selectedDivision === 'hans'
                                  ? \`/payrolls/hans/\${selectedPayroll.id}/slip\`
                                  : selectedDivision === 'office'
                                    ? \`/payrolls/ho/\${selectedPayroll.id}/slip\`
                                    : selectedDivision === 'cellular'
                                      ? \`/payroll-cellullers/\${selectedPayroll.id}/slip\`
                                      : \`/payrolls/\${selectedPayroll.id}/slip\`;

                        const response = await apiClient.get(endpoint, {
                          responseType: 'blob',
                        });`;

const generateSlipNew2 = `                        const endpoint = selectedDivision === 'maximum'
                          ? \`/payrolls/maximum/\${selectedPayroll.id}/slip\`
                          : selectedDivision === 'tungtau'
                          ? \`/payrolls/tungtau/\${selectedPayroll.id}/slip\`
                          : selectedDivision === 'fnb'
                          ? \`/payrolls/fnb/\${selectedPayroll.id}/slip\`
                          : ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)
                            ? \`/payrolls/retail/\${selectedPayroll.id}/slip\`
                            : selectedDivision === 'office'
                              ? \`/payrolls/ho/\${selectedPayroll.id}/slip\`
                              : \`/payrolls/\${selectedPayroll.id}/slip\`;

                        const response = await apiClient.get(endpoint, {
                          responseType: 'blob',
                          params: ['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision) ? { division_type: selectedDivision } : {}
                        });`;

content = content.replace(generateSlipOld2, generateSlipNew2);

fs.writeFileSync(path, content);
console.log('Script done');
