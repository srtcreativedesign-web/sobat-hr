const fs = require('fs');
const lines = fs.readFileSync('transcript_matches.txt', 'utf8').split('\n');

let extracted = '';
for (const line of lines) {
    if (!line.trim() || !line.startsWith('{')) continue;
    try {
        const obj = JSON.parse(line);
        if (obj.content && obj.content.includes("handleFileUpload")) {
            extracted += "--- STEP " + obj.step_index + " ---\n";
            extracted += obj.content + "\n\n";
        }
        if (obj.content && obj.content.includes("parsedRows")) {
            extracted += "--- STEP " + obj.step_index + " ---\n";
            extracted += obj.content + "\n\n";
        }
    } catch (e) {}
}
fs.writeFileSync('extracted_page_2.txt', extracted);
console.log('Extracted to extracted_page_2.txt');
