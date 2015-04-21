# yggdrasil #
Scripts and templates to set up NAT, VPN, media server, and more on AWS VPC.
---------------------------------------------------------
###### Disclaimer: yggdrasil is largely customized to my personal preferences. It also consumes a non-trivial amount of AWS resources. As a whole, it's probably more of a curiosity than useful product for most users. However, it does a fair amount of cool stuff and may provide useful examples for people looking to automate setting up NAT, OpenVPN, Plex, or Transmission, or people looking for example code using the AWS CLI or Boto with Python 3.4. ######
---------------------------------------------------------
## What's in the box?! ##
The core of yggdrasil is a [CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) template (CloudFormation is an AWS service that allows you to manage AWS resources by templating them with JSON). The CloudFormation template specifies the following:

* Creation of a [Virtual Private Cloud (VPC)](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html)
* Configuration of AWS resources to enable networking in the VPC,
* Creation of [EC2 instances](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html) (currently NAT, VPN, media, and torrent servers)
* Optional creation of DNS records in [Route 53](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)

yggdrasil also contains several scripts (currently all bash and Python) that make the whole thing work together. The salient scripted features include:

* Automated setup of a certificate authority (CA), configuration of an OpenVPN server, and generation of VPN credentials
* Automated setup of a [Plex Media Server](https://plex.tv/) with a primary volume that scales up in size as it fills (using [LVM](http://en.wikipedia.org/wiki/Logical_Volume_Manager_%28Linux%29) and [Elastic Block Store (EBS)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html))
* Automated setup of a [Transmission](http://www.transmissionbt.com/) server (nearing completion)
* Automated configuration of an OpenVPN client (rough bash script available, better Python version in progress)

## Usage ##
I tinker with yggdrasil in my spare time. The core features (NAT, VPN, media) are fairly solid, the torrent server is a work in progress and the client setup script, while functional, is not awesome yet. If ye seek to scale yggdrasil, consider yerself warn'd.

### 0. Create prerequisites (optional, but highly recommended) ###
#### S3 media bucket (you should probably do this) ####

#### Route53 hosted zone ####

### 1. Spin up the CloudFormation template ###

### 2. Confirm your VPN client is working ###
#### Setup client machine ####

#### Connect to cloud servers ####

### 3. Configure Plex server ###

#### Create libraries ####

### 4. Profit ###

#### Build Bifrost ####

## Details ##
The best documentation is, as always, the source. I'll provide a brief breakdown of what each component is doing here for the academically minded. This will focus on my scripts; the AWS-centric stuff set up by the CloudFormation template is covered by AWS's documentation.
### NAT server ###

### OpenVPN server ###

### Plex server ###

### Transmission server ###

### Client setup scripts ###
