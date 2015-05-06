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

### 0. Create prerequisites ###
#### S3 VPN secrets bucket ####
Upon spinning up, some code runs on the VPN server that sets up a certificate authority (using EasyRSA) and generates certificates and keys for the VPN server and a single client. The client materials are encrypted with a randomly generated symmetric key. This key is then encrypted with the ssh public key installed on the instance (the key pair used is an argument to the CloudFormation template). The encrypted materials and encrypted symmetric key are wrapped up in a tar ball which is stored in S3 in the bucket or prefix provided as an argument to the template.

Alternatively, you can provide the location of the necessary certificates and keys for an OpenVPN server in S3. This is a legacy option that requires that you have these things set up already (not awesome) and that requires that your VPN secrets be stored in S3 unencrypted (also not awesome). Not recommended, but available.

#### S3 media bucket ####
The yggdrasil CloudFormation template expects an S3 path to whatever media you want on the server. I think creating an S3 bucket is free; you are only charged for what you store. Even if you have no media in S3 yet, I recommend that you set up a location in S3 into which your media will go. This can be a bucket or a prefix in a separate bucket.

#### Route53 hosted zone (optional) ####
DNS makes things better. The name of a Route 53 hosted zone in your account is an optional parameter to the yggdrasil CloudFormation template. If you provide a hosted zone, the yggdrasil instances will be assigned the following DNS names:
* NAT server: nat.internal.{stack name}.{hosted zone} (this is assigned to the internal IP of the NAT instance; there is no DNS entry for the elastic IP attached to the instance)
* VPN server (elastic IP): vpn.{stack name}.{hosted zone}
* VPN server (private IP): vpn.internal.{stack name}.{hosted zone}
* Media server: media.internal.{stack name}.{hosted zone}
* Torrent server: download.internal.{stage name}.{hosted zone}

All of the resource.internal... DNS names map to the private IPs of the corresponding instances; these addresses are published publicly but are in the reserved range used by yggdrasil (172.16.0.0/16) and are only accessible by someone connected to the VPN.

### 1. Spin up the CloudFormation template ###
I may add script to kick this off from the command line, but for now I have no special tooling for this task. You can launch the CloudFormation template from the AWS console, from Python with boto, with the AWS CLI -- the list goes on.

### 2. Confirm your VPN client is working ###
Once the code that sets up the VPN server completes (it should complete before the stack changes to state CREATE_COMPLETE), you are ready to connect.  

#### Setup client machine ####
You need OpenVPN installed on your machine. On Ubuntu/Debian:

<pre>
sudo apt-get install openvpn
</pre>

I have not used any other platforms (multiplatform client support is a low priority work in progress), but there is no reason a Windows or Mac OpenVPN client would not work. Once OpenVPN is installed, you need to download the client materials generated by the VPN server and setup your OpenVPN client configuration file. On Linux, you can use the included script:

<pre>
./yggdrasil/scripts/bash/vpn_download_certs.sh {S3 path of tarball} {destination location of VPN secrets} {EC2 private key}
</pre>

This will download the client materials, decrypt them, and place them on the disk. You can place them wherever you want (their location just needs to match the contents of the config file). I normally use /etc/openvpn/easy-rsa. An example usage:

<pre>
sudo ./yggdrasil/scripts/bash/vpn_download_certs.sh dalton_vpn/yggdrasil/client_materials.tgz /etc/openvpn/easy-rsa yggdrasil_key.pem
</pre>

Once the client materials are placed, set up the client configuration file. There is a template in yggdrasil/templates/client.conf. All you need to do is set the locations of the keys. There is a placeholder value of KEYS_DIR in the template. With the example values used in the previous example:

<pre>
sudo cp ./yggdrasil/templates/client.conf /etc/openvpn
sudo sed -i 's/KEYS_DIR/\/etc\/openvpn\/easy-rsa/g' /etc/openvpn/client.conf
</pre>

Now, all you should need to do is start openvpn:

<pre>
sudo service openvpn start
</pre>

#### Connect to cloud servers ####
You should now be connected to the VPN. The terminal in which you ran the command to start the OpenVPN service will contain its output. It should be fairly obvious if it is not working. Now, you should be able to talk to the instances that make up yggdrasil. The IP addresses and DNS names (if a hosted zone was provided to the template) of the yggdrasil hosts are available in the outputs of the CloudFormation template.

### 3. Configure Plex server ###
Plex has a lot of nice features. A well-supported, flexible, sane command line interface is not one of them. Luckily, a decent web interface is. You will need to setup libraries on the the Plex server if you actually want to watch anything. I'm not going to reproduce Plex's docs here, but I will give a brief description of how to setup libraries on the Plex server.

First, you'll want to connect to the web interface of the Plex server, located at:

<pre>
https://{media server DNS name or IP}:32400/web/index.html
</pre>

To create a library, click the <b>+</b> in the <b>Libraries</b> pane. A wizard will guide you through the process. The structure of the media S3 bucket/prefix you provided to the template is reproduced at <b>/media</b> on the instance, so if your bucket looks like this:

<pre>
dalton_media
  |-movies
    |-this_is_spinal_tap.avi
  |-music
    |-Darkthrone
      |-Transilvanian Hunger
        |-As Flittermice as Satan's Spies.flac
    |-Katy Perry
      |-Teenage Dream (The Complete Confection)
        |-California Girls.flac
  |-tv
    |-Better Call Saul
      |-Season 1
        |-Nacho.mkv
</pre>

You can create a movies library with directory <b>/media/movies</b>, a music library with <b>/media/music</b>, and a TV library with <b>/media/tv</b>. If you have a lot of media, it will take a little time to sync initially (though not too much time as the connection from EC2 to S3 is wicked fast). After the initial sync, a cron job keeps <b>/media</b> in sync with your S3 bucket via the <b>aws s3 sync</b> command, which only copies over files that have changed. In practice, files put to the S3 bucket show up on the media server within about a minute.

### 4. Profit ###
This is where I shall put useful extensions outside of the core functionality of yggdrasil.

#### Build Bifrost ####
[Bifrost](http://en.wikipedia.org/wiki/Bifrost) connected Asgard, world of the Aesir, to Midgard, our world. Bifrost is the name that I give to a VPN gateway connecting your home network to the cloud resources of yggdrasil. On the machine you wish to use, follow the <b>Setup client machine</b> instructions above. Next, run

<pre>
./yggdrasil/scripts/bash/nat.sh
</pre>

This script is primarily used by the NAT instance in the yggdrasil VPC, but it works here as well.

Now that Bifrost is setup, you need to log into your router and specify that all traffic destined for <b>172.16.0.0/16</b> be sent to Bifrost's IP address. This should be easy to do but will vary from router to router, so I cannot provide more explicit instructions. I highly recommend setting this up; it allows any device on your home network to talk to your yggdrasil resources, so you can have your Rokus, Fire TVs, game consoles, toasters, etc. stream content from your media server.

## Details ##
The best documentation is, as always, the source. I'll provide a brief breakdown of some of the major components here (as I have time and motivation), but for a full explanation, read the source.

### VPC architecture ###

### NAT server ###

### OpenVPN server ###

### Plex server ###

### Transmission server ###

### Client setup scripts ###
