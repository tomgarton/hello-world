"""Writes SchemaModel.swift: Puggle's data model on its own, for the PuggleCheckDev target.

Taken from Puggle/Data/Model.swift, with the app's classes swapped for plain managed objects. Run from this folder.
"""
import re
source = open('../../Puggle/Data/Model.swift').read()
body = re.sub(r'NSStringFromClass\(\w+\.self\)', '"NSManagedObject"', source[source.index('enum PuggleModel'):])
open('SchemaModel.swift', 'w').write('// Written by make_schema_model.py from Puggle/Data/Model.swift. Do not edit.\nimport CoreData\n\n' + body)
