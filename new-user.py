#!python

import argparse
import base64
import passlib.hash
import random
import sha
import string

parser = argparse.ArgumentParser()
parser.add_argument('--user')
parser.add_argument('--password')
args = parser.parse_args()

password = args.password

if not password:
    password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(16))

print('user=' + args.user + ' password=' + password + '\n')

print(
        '- { user: "' + args.user + '", ' +
        'sha512: "' + passlib.hash.sha512_crypt.using(rounds=5000).hash(password) + '", ' +
        'sha1: "' + base64.b64encode(sha.new(password).digest()) + '" }\n'
)
