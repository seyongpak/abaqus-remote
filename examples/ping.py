import abaqus, sys
print('python', sys.version.split()[0])
print('models:', list(mdb.models.keys()))
for n, m in mdb.models.items():
    print(n, 'parts:', list(m.parts.keys()), 'materials:', list(m.materials.keys()))
print('pathName:', mdb.pathName)
