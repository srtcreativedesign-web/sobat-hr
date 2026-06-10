const fs = require('fs');
const path = './sobat-web/src/app/payroll/page.tsx';
let content = fs.readFileSync(path, 'utf8');

// The issue on line 1327:
content = content.replace(
  `}

        </>
      )}

      {/* Import/Export Tab */}`,
  `}
      {/* Import/Export Tab */}`
);

// We need to properly wrap the data table in activeTab === 'data'.
// Where does the data table start?
// We see:
// return (
//   <DashboardLayout>
//     {/* Header */}
// ...
//           {/* Tabs */}
//           <div className="mt-6 flex border-b border-gray-200">
// ...
//           </div>
// 
//           {/* Period Filter */}
// 
// It should be that the Data UI is shown when activeTab === 'data'.
// Let's just remove ALL activeTab === 'data' wrappers except for the conditional render!
// Wait, right now it is not wrapped at all! The activeTab is only used for {activeTab === 'import_export' && ( ... )} at the bottom!
// Let's check where the bottom bracket mismatch is.

fs.writeFileSync(path, content);
