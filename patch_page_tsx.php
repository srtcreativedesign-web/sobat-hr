<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// 1. Remove EWA from calculateTotalDeductions
$deductSearch = <<<EOT
    // Add EWA if applicable
    if (['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping'].includes(selectedDivision) && payroll.ewa_amount) {
      baseDeduction += parseFloat(payroll.ewa_amount) || 0;
    }
EOT;
$content = str_replace($deductSearch, "", $content);

// 2. Remove EWA display block from Potongan column
$ewaDisplaySearch = <<<EOT
                      {/* EWA Display (for FnB/MM/Ref/Wrapping only, Hans excluded) */}
                      {(selectedDivision === 'tungtau' || selectedDivision === 'maximum' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') && parseFloat(selectedPayroll.ewa_amount) > 0 && (
                        <div className="bg-red-50 p-2 rounded-lg mt-2">
                          <div className="text-xs font-semibold text-red-700 mb-1">EWA (Kasbon)</div>
                          <div className="flex justify-between text-sm">
                            <span className="text-gray-600">Total EWA</span>
                            <span className="font-medium text-red-600">
                              -{formatCurrency(typeof selectedPayroll.ewa_amount === 'string' ? parseFloat(selectedPayroll.ewa_amount) : selectedPayroll.ewa_amount)}
                            </span>
                          </div>
                        </div>
                      )}
EOT;
$content = str_replace($ewaDisplaySearch, "", $content);

// 3. Replace the Net Salary Summary footer
$footerSearch = <<<EOT
                  <div className="flex items-center justify-between border-b border-white/20 pb-4">
                    <div>
                      <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">Grand Total</p>
                      <p className="text-2xl font-bold">{formatCurrency(selectedPayroll.net_salary)}</p>
                    </div>
                    {selectedDivision === 'cellular' && parseFloat(selectedPayroll.ewa_amount) > 0 && (
                      <div className="text-right">
                        <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">EWA (Kasbon)</p>
                        <p className="text-xl font-semibold opacity-90">-{formatCurrency(typeof selectedPayroll.ewa_amount === 'string' ? parseFloat(selectedPayroll.ewa_amount) : selectedPayroll.ewa_amount)}</p>
                      </div>
                    )}
                  </div>
EOT;

$footerReplace = <<<EOT
                  {selectedDivision !== 'office' && selectedDivision !== 'all' && selectedPayroll.thp !== undefined ? (
                    <>
                      <div className="flex items-center justify-between border-b border-white/20 pb-4">
                        <div>
                          <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">Total Pendapatan (THP)</p>
                          <p className="text-2xl font-bold">{formatCurrency(selectedPayroll.thp)}</p>
                        </div>
                      </div>
                      {parseFloat(selectedPayroll.ewa_amount) > 0 && (
                        <div className="flex items-center justify-between border-b border-white/20 pb-4 text-red-200">
                          <div>
                            <p className="text-xs font-medium uppercase tracking-wider">Potongan Stafbook (EWA)</p>
                            <p className="text-2xl font-bold">-{formatCurrency(typeof selectedPayroll.ewa_amount === 'string' ? parseFloat(selectedPayroll.ewa_amount) : selectedPayroll.ewa_amount)}</p>
                          </div>
                        </div>
                      )}
                    </>
                  ) : (
                    <div className="flex items-center justify-between border-b border-white/20 pb-4">
                      <div>
                        <p className="text-indigo-100 text-xs font-medium uppercase tracking-wider">Grand Total</p>
                        <p className="text-2xl font-bold">{formatCurrency(selectedPayroll.net_salary)}</p>
                      </div>
                    </div>
                  )}
EOT;
$content = str_replace($footerSearch, $footerReplace, $content);

file_put_contents($file, $content);
echo "page.tsx patched.\n";
