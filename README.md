# OpenVPN Server for Ubuntu

This script automates the setup of OpeVPN on Ubuntu 16, it's been tested on DigitalOcean $5 boxes. It's pretty much this tutorial turned into a script:

https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04

## Installing

You can install it directly on your server like so:

    $ curl -s -L https://raw.githubusercontent.com/jasonagnew/ubuntu-openvpn/master/setup.sh | bash -s [server-ip] [key-country] [key-province] [key-city] [key-org] [key-email] [key-ou]

Please complete the variables in the brackets, examples below. The install may take around 5 minutes.

### Example

	$ curl -s -L https://raw.githubusercontent.com/jasonagnew/ubuntu-openvpn/master/setup.sh | bash -s 133.66.111.222 US NY NewYorkCity DigitalOcean admin@example.com Community