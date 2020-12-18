#  tests for pytz-2020.4-pyhd3eb1b0_0 (this is a generated file);
print('===== testing package: pytz-2020.4-pyhd3eb1b0_0 =====');
print('running run_test.py');
#  --- run_test.py (begin) ---
import os
from os.path import dirname, isfile, join

import pytz


pytz_dir = dirname(pytz.__file__)
print('pytz_dir: %r' % pytz_dir)
assert isfile(join(pytz_dir, 'zoneinfo', 'zone.tab'))
assert len(os.listdir(join(pytz_dir, 'zoneinfo'))) > 10
#  --- run_test.py (end) ---

print('===== pytz-2020.4-pyhd3eb1b0_0 OK =====');
print("import: 'pytz'")
import pytz

