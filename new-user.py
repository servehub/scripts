#!python

import argparse
import base64
import passlib.hash
import random
import sha
import string

parser = argparse.ArgumentParser()
parser.add_argument('--user')
args = parser.parse_args()

password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(16))

print('user=' + args.user + ' password=' + password + '\n')

print(
        '  - {"user": "' + args.user + '", ' +
        '"sha512": "' + passlib.hash.sha512_crypt.using(rounds=5000).hash(password) + '", ' +
        '"sha1": "' + base64.b64encode(sha.new(password).digest()) + '"}\n'
)
