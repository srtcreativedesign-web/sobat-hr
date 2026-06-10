const fs = require('fs');
const path = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

const oldPreviewTableStart = `                    <div className="max-h-64 overflow-auto border rounded-lg">
                      <table className="w-full text-sm">
                        <thead className="bg-gray-50">
                          <tr>
                            {Object.keys(parsedRows[0]).map((col) => (
                              <th key={col} className="text-left p-2 font-medium text-gray-600 whitespace-nowrap">{col}</th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {parsedRows.map((row: any, idx: number) => (
                            <tr key={idx} className="even:bg-white odd:bg-gray-50">
                              {Object.keys(parsedRows[0]).map((col) => {
                                const isNominal = ['basic_salary', 'training_salary', 'meal_rate', 'meal_amount', 'transport_rate', 'transport_amount', 'attendance_allowance', 'health_allowance', 'position_allowance', 'overtime_rate', 'overtime_amount', 'mandatory_overtime_rate', 'mandatory_overtime_amount', 'bonus', 'holiday_allowance', 'target_koli', 'fee_aksesoris', 'total_salary_gross', 'adj_bpjs', 'deduction_absent', 'deduction_late', 'deduction_alpha', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk', 'deduction_total', 'net_salary', 'thp', 'ewa_amount'].includes(col);
                                
                                return (
                                <td key={col} className="p-2 whitespace-nowrap">
                                  {typeof row[col] === 'object' && row[col] !== null ? (
                                    <div className="text-xs max-h-20 overflow-y-auto">
                                      {Object.entries(row[col]).map(([k, v]) => {
                                        // Skip empty/zero values in preview to save space
                                        if (v === 0 || v === '0' || v === null) return null;
                                        return (
                                          <div key={k} className="whitespace-nowrap">
                                            <span className="font-semibold">{k}:</span> {String(v)}
                                          </div>
                                        );
                                      })}
                                      {Object.values(row[col]).every(v => v === 0 || v === '0' || v === null) && <span className="text-gray-400">-</span>}
                                    </div>
                                  ) : (
                                    isNominal && row[col] ? new Intl.NumberFormat('id-ID').format(Number(row[col])) : row[col]
                                  )}
                                </td>
                              )})}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>`;

const newPreviewTable = `                    <div className="max-h-64 overflow-auto border rounded-lg">
                      <table className="w-full text-sm">
                        <thead className="bg-gray-50 sticky top-0 z-10">
                          <tr className="border-b border-gray-200">
                            <th className="text-left py-4 px-6 font-semibold text-gray-600 whitespace-nowrap">Employee</th>
                            <th className="text-left py-4 px-6 font-semibold text-gray-600 whitespace-nowrap">Period</th>
                            <th className="text-right py-4 px-6 font-semibold text-gray-600 whitespace-nowrap">Basic Salary</th>
                            <th className="text-right py-4 px-6 font-semibold text-gray-600 whitespace-nowrap">Total Allowances</th>
                            <th className="text-right py-4 px-6 font-semibold text-gray-600 whitespace-nowrap">Overtime</th>
                            <th className="text-right py-4 px-6 font-bold text-gray-700 bg-gray-100 whitespace-nowrap">Gross Salary</th>
                            <th className="text-right py-4 px-6 font-bold text-red-600 bg-red-50 whitespace-nowrap">Total Deductions</th>
                            <th className="text-right py-4 px-6 font-bold text-[#1C3ECA] whitespace-nowrap">Net Salary</th>
                          </tr>
                        </thead>
                        <tbody>
                          {parsedRows.map((row: any, idx: number) => {
                            const basic = Number(row.basic_salary) || 0;
                            const overtime = Number(row.overtime_amount) || 0;
                            const gross = Number(row.total_salary_2) || Number(row.gross_salary) || Number(row.total_salary_1) || 0;
                            const deductions = Number(row.total_deductions) || 0;
                            const net = Number(row.net_salary) || Number(row.payroll) || 0;
                            const allowances = gross - basic - overtime;

                            return (
                              <tr key={idx} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                                <td className="py-4 px-6">
                                  <p className="text-sm font-semibold text-gray-900">{row.employee_name || '-'}</p>
                                </td>
                                <td className="py-4 px-6 text-sm text-gray-900">
                                  {row.period ? new Date(row.period + '-01').toLocaleDateString('id-ID', { month: 'short', year: 'numeric' }) : '-'}
                                </td>
                                <td className="py-4 px-6 text-right text-sm text-gray-900">{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(basic)}</td>
                                <td className="py-4 px-6 text-right text-sm text-gray-900">{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(allowances > 0 ? allowances : 0)}</td>
                                <td className="py-4 px-6 text-right text-sm text-green-600">{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(overtime)}</td>
                                <td className="py-4 px-6 text-right text-sm font-bold text-gray-800 bg-gray-50">{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(gross)}</td>
                                <td className="py-4 px-6 text-right text-sm font-bold text-red-600 bg-red-50">-{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(deductions)}</td>
                                <td className="py-4 px-6 text-right text-sm font-bold text-[#1C3ECA]">{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(net)}</td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>`;

if (content.includes('max-h-64 overflow-auto border rounded-lg')) {
    const startIndex = content.indexOf('<div className="max-h-64 overflow-auto border rounded-lg">', content.indexOf('{parsedRows.length > 0 && ('));
    const endIndex = content.indexOf('</div>', content.indexOf('</table>', startIndex)) + 6;
    
    const before = content.substring(0, startIndex);
    const after = content.substring(endIndex);
    
    fs.writeFileSync(path, before + newPreviewTable + after);
    console.log('Preview table updated successfully');
} else {
    console.log('Could not find preview table start string.');
}
