const Parser = require('tree-sitter');
const language = require('./bindings/node');

const parser = new Parser();
parser.setLanguage(language);

const fs = require('fs');
const input = fs.readFileSync('debug_test.txt', 'utf8');

console.log('Input:', JSON.stringify(input));
const tree = parser.parse(input);
console.log('Tree:', tree.rootNode.toString());
console.log('Has error:', tree.rootNode.hasError);