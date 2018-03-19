#!python

import argparse
import boto.ec2

# Set up argument parser
parser = argparse.ArgumentParser(
    description='Request AWS EC2 spot instance and tag instance and volumes.',
    formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument(
    '--region',
    help='EC2 region to connect to (e.g. us-west-2).')

args = parser.parse_args()

# Open EC2 connection
ec2 = boto.ec2.connect_to_region(args.region)

# Request spot instance
spot_reqs = ec2.get_all_spot_instance_requests(filters={"state": "active"})

for sp in spot_reqs:
    print(sp.instance_id, sp.tags)

    reservations = ec2.get_all_instances(instance_ids=sp.instance_id)
    instance = reservations[0].instances[0]

    for k, v in sp.tags.iteritems():
        if instance.tags.get(k, "") != v:
            print("---->", k, "=", v, instance)
            instance.add_tag(k, v)

    print("")
