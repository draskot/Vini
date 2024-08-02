#! /usr/bin/python3.9
import logging
import sys

logging.basicConfig(stream=sys.stderr)
sys.path.insert(0, '/var/www/ViniApp/')

from ViniApp import app as application
application.secret_key = 'Vini secret'
