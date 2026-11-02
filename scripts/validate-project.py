#!/usr/bin/env python3
"""Offline project/resource integrity checks. Does not replace compilation or XCTest."""
from pathlib import Path
import json, re, xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
app = root / 'DefencePensionCalculator'
pbx = (app / 'DefencePensionCalculator.xcodeproj/project.pbxproj').read_text()
refs = re.findall(r'path = "([^"]+\.(?:swift|json))";', pbx)
actual = {p.relative_to(app).as_posix() for p in app.rglob('*') if p.suffix in {'.swift', '.json'} and '.xcassets' not in p.as_posix()}
assert set(refs) == actual, f'Project file references differ: {set(refs) ^ actual}'
assert len(refs) == len(set(refs)), 'Duplicate file references'
objects = set(re.findall(r'^([A-F0-9]{24}) = ', pbx, re.M))
assert set(re.findall(r'\b[A-F0-9]{24}\b', pbx)) == objects, 'Dangling project object'
assert pbx.count('IPHONEOS_DEPLOYMENT_TARGET = "16.0"') == 6
ET.parse(app / 'DefencePensionCalculator.xcodeproj/xcshareddata/xcschemes/DefencePensionCalculator.xcscheme')
for name in ['CommutationFactors', 'OROPReferenceTables', 'PayMatrix7CPC']:
    data = json.loads((app / f'Data/Resources/{name}.json').read_text())
    assert data['dataVersion'] and data['verified'] is False and data['entries'] == []
ranks = json.loads((app / 'Data/Resources/RankMapping.json').read_text())
assert len({r['id'] for r in ranks}) == len(ranks)
assert {r['branch'] for r in ranks} == {'Army', 'Navy', 'Air Force'}
metadata = json.loads((app / 'Data/Resources/PensionRulesMetadata.json').read_text())
assert metadata and all(not r['verified'] for r in metadata)
assert all('TODO' not in p.read_text() for p in app.rglob('*.swift'))
print(f'PASS: {len(refs)} source/resource references; 5 JSON files; scheme XML; iOS 16 target settings; incomplete-data safeguards.')
