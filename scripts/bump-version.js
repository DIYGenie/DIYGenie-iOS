const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
const [maj,min,pat] = (pkg.version || '1.0.0').split('.').map(n=>parseInt(n||'0',10));
const next = `${maj}.${min}.${(pat||0)+1}`;
pkg.version = next;
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log(next);
