#!python

import argparse
import hashlib
import random
import string

parser = argparse.ArgumentParser()
parser.add_argument('--name')
parser.add_argument('--password')
args = parser.parse_args()

password = args.password

if not password:
    password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(24))

print(args.name + ' ' + password + '\n')

print(
        '- { db: ' + args.name + ', ' +
        'user: ' + args.name + ', ' +
        'pass: "md5' + hashlib.md5(password + args.name).hexdigest() + '" }\n'
)
