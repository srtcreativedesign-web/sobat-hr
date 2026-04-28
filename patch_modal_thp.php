<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// Replace the modal footer section
$footerSearch = <<<EOT
                    {/* Grand Total */}
                    <div className="bg-blue-600 text-white p-6 rounded-xl mt-6 shadow-lg shadow-blue-600/20">
                      <p className="text-blue-100 text-xs font-medium uppercase tracking-wider mb-1">Grand Total</p>
                      <p className="text-2xl font-bold">{formatCurrency(selectedPayroll.net_salary)}</p>
                    </div>
                    {selectedDivision === 'cellular' && parseFloat(selectedPayroll.ewa_amount) > 0 && (
                      <div className="text-right">
                        <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">EWA (Kasbon)</p>
                        <p className="text-xl font-semibold opacity-90">-{formatCurrency(typeof selectedPayroll.ewa_amount === 'string' ? parseFloat(selectedPayroll.ewa_amount) : selectedPayroll.ewa_amount)}</p>
                      </div>
                    )}
EOT;
// Wait, the footer might have more stuff like EWA conditional block?
