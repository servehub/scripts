#!python

import argparse
import random
import string
import subprocess

from passlib.hash import bcrypt, sha512_crypt
from passlib.totp import TOTP

parser = argparse.ArgumentParser()
parser.add_argument('--user')
parser.add_argument('--password')
args = parser.parse_args()

password = args.password

if not password:
    password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(18))

otpSecret = subprocess.check_output(['ansible-vault', 'encrypt_string', '--vault-id', '.secrets/vault-password', TOTP.new().base32_key, '--name', 'otpSecret'])

print('user=' + args.user + ' password=' + password + '\n')

print(
    '- user: "' + args.user + '"\n' +
    '  sha512: "' + sha512_crypt.using(rounds=5000).hash(password) + '"\n' +
    '  bcrypt: "' + bcrypt.hash(password) + '"\n' +
    '  ' + otpSecret.replace('          ', '    ') + '\n'
)


