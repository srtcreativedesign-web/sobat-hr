const fs = require('fs');
let content = fs.readFileSync('sobat-api/app/Http/Controllers/Api/PayrollRetailController.php', 'utf8');

// 1. saveImport missing division_type validation and hardcoded PayrollHans
content = content.replace(
    `    public function saveImport(Request $request)\n    {\n        $request->validate([\n            'rows' => 'required|array',\n            'rows.*.employee_name' => 'required|string',\n        ]);`,
    `    public function saveImport(Request $request)\n    {\n        $request->validate([\n            'division_type' => 'required|string',\n            'rows' => 'required|array',\n            'rows.*.employee_name' => 'required|string',\n        ]);`
);

content = content.replace(/PayrollHans::where/g, '$this->getModel($request->division_type)->where');
content = content.replace(/PayrollHans::create/g, '$this->getModel($request->division_type)->create');

// 2. updateStatus missing division_type
content = content.replace(
    `    public function updateStatus(Request $request, $id)\n    {\n         $request->validate([\n            'status' => 'required|in:draft,approved,paid',\n            'approval_signature' => 'nullable|string',\n            'notes' => 'nullable|string',\n        ]);`,
    `    public function updateStatus(Request $request, $id)\n    {\n         $request->validate([\n            'division_type' => 'required|string',\n            'status' => 'required|in:draft,approved,paid',\n            'approval_signature' => 'nullable|string',\n            'notes' => 'nullable|string',\n        ]);`
);
content = content.replace(/PayrollHans::findOrFail/g, '$this->getModel($request->division_type)->findOrFail');

fs.writeFileSync('sobat-api/app/Http/Controllers/Api/PayrollRetailController.php', content);
console.log('Fixed PayrollHans references!');
