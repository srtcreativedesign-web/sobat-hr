const fs = require('fs');

function fixFile(file) {
    let content = fs.readFileSync(file, 'utf8');

    // Fix fetchPayrolls endpoints
    content = content.replace(
        /if \(selectedDivision === 'minimarket'\) endpoint = '\/payrolls\/mm';\s*if \(selectedDivision === 'reflexiology'\) endpoint = '\/payrolls\/ref';\s*if \(selectedDivision === 'wrapping'\) endpoint = '\/payrolls\/wrapping';\s*if \(selectedDivision === 'hans'\) endpoint = '\/payrolls\/hans';\s*if \(selectedDivision === 'cellular'\) endpoint = '\/payroll-cellullers'; \/\/ New Endpoint\s*if \(selectedDivision === 'money_changer'\) endpoint = '\/payrolls\/money-changer';/g,
        "if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) endpoint = '/payrolls/retail';"
    );

    // Fix fetchPayrolls params
    content = content.replace(
        /\.\.\.\(debouncedSearch && \{ search: debouncedSearch \}\)/g,
        "...(debouncedSearch && { search: debouncedSearch }),\n          ...(['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision) && { division_type: selectedDivision })"
    );

    // Fix saveEndpoint
    content = content.replace(
        /if \(selectedDivision === 'minimarket'\) saveEndpoint = '\/payrolls\/mm\/import\/save';\s*if \(selectedDivision === 'reflexiology'\) saveEndpoint = '\/payrolls\/ref\/import\/save';\s*if \(selectedDivision === 'wrapping'\) saveEndpoint = '\/payrolls\/wrapping\/import\/save';\s*if \(selectedDivision === 'hans'\) saveEndpoint = '\/payrolls\/hans\/import\/save';\s*if \(selectedDivision === 'cellular'\) saveEndpoint = '\/payroll-cellullers\/import\/save';\s*if \(selectedDivision === 'money_changer'\) saveEndpoint = '\/payrolls\/money-changer\/import\/save';/g,
        "if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) { saveEndpoint = '/payrolls/retail/import/save'; }"
    );
    
    // Fix importEndpoint
    content = content.replace(
        /if \(selectedDivision === 'minimarket'\) importEndpoint = '\/payrolls\/mm\/import';\s*if \(selectedDivision === 'reflexiology'\) importEndpoint = '\/payrolls\/ref\/import';\s*if \(selectedDivision === 'wrapping'\) importEndpoint = '\/payrolls\/wrapping\/import';\s*if \(selectedDivision === 'hans'\) importEndpoint = '\/payrolls\/hans\/import';\s*if \(\['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'\]\.includes\(selectedDivision\)\) \{\s*importEndpoint = '\/payrolls\/retail\/import\/parse-headers';\s*formData\.append\('division_type', selectedDivision\);\s*\}\s*if \(selectedDivision === 'cellular'\) importEndpoint = '\/payroll-cellullers\/import'; \/\/ New Endpoint\s*if \(selectedDivision === 'money_changer'\) importEndpoint = '\/payrolls\/money-changer\/import';/g,
        "if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {\n        importEndpoint = '/payrolls/retail/import/parse-headers';\n        formData.append('division_type', selectedDivision);\n      }"
    );

    fs.writeFileSync(file, content);
}

fixFile('./sobat-web/src/app/payroll/import/page.tsx');
fixFile('./sobat-web/src/app/payroll/page.tsx');
console.log('Fixed endpoints!');
