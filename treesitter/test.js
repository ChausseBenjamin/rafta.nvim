const Parser = require('tree-sitter');
const language = require('./bindings/node');

console.log('Language loaded');

const parser = new Parser();
parser.setLanguage(language);

console.log('Parser set');

const fs = require('fs');
const lines = fs.readFileSync('valid.txt', 'utf8').split('\n');

console.log('Lines:', lines.length);

let line = lines[0];
console.log(`Testing: '${line}'`);
console.log('About to parse');
const tree = parser.parse(line);
console.log('Parsed');
console.log('Tree:', tree.rootNode.toString());
console.log('Has error:', tree.rootNode.hasError);