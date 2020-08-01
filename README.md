# Experimental

Experimental and opinionated Terraform module to deploy Tinkerbell on Packet

Not safe for production or development.

## Provision

This project is a deviation away from https://tinkerbell.org/setup/, but the instructions given on that site are best once tinkerbell is running.  Notably, `setup.sh`, while based on the one in the `tinkerbell/tink` repo, has been tailored here for this project.

Terraform provisioner resources are used, with the SSH Agent option.  To ensure that the provisioner succeeds, your local SSH keys should be registered with Packet: <https://www.packet.com/developers/docs/servers/key-features/ssh-keys/>.

This SSH key should also be registered with your SSH Agent, using `ssh-add`.  In many environments SSH keys can be associated with your login or key-chain.  For example, `ssh-add -K` will register all SSH keys stored in your OSX Keychain with the SSH agent, making them available for use in SSH authentication.

```sh
terraform init --upgrade
terraform apply # this may take 20m
```

<!--
## Copy files

If terraform fails to provision deploy/ into the tink-provision node, you can rsync it there:

```sh
rsync assets/deploy root@$(terraform output provisioner_dns_name):/root/deploy
rsync assets/setup.sh root@$(terraform output provisioner_dns_name)/root/
```

The `tink-provisioner` system should now have all of the scripts that you will need to continue the setup.
-->

## Run setup.sh

The `setup.sh` file and `deploy` directory can be should be copied over when the provisioner is created.

```sh
ssh root@$(terraform output provisioner_dns_name)
```

Now that you are on the tink-provisioner node, you should see `/root/setup.sh` and `/root/deploy/docker-compose.yaml`. If not, revisit the "Copy files" section.

Run `ip a`. you should see 'enp1s0f1'. If you see 'enp5s0f1' change 'enp1s0f1'
inside of setup.sh to match ('enp5s0f1').

```sh
./setup.sh
```

If the setup gets hung at the following, reboot the node. when it comes back up run `./setup.sh` again and it should complete:

```console
fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/community/x86_64/APKINDEX.tar.gz
(1/10) Upgrading ca-certificates-cacert (20191127-r1 -> 20191127-r2)
(2/10) Installing ca-certificates (20191127-r2)
(3/10) Installing ncurses-terminfo-base (6.1_p20200118-r4)
(4/10) Installing ncurses-libs (6.1_p20200118-r4)
(5/10) Installing libedit (20191211.3.1-r0)
(6/10) Installing db (5.3.28-r1)
(7/10) Installing libsasl (2.1.27-r5)
(8/10) Installing libldap (2.4.48-r2)
(9/10) Installing libpq (12.2-r0)
(10/10) Installing postgresql-client (12.2-r0)
Executing busybox-1.31.1-r9.trigger
Executing ca-certificates-20191127-r2.trigger
OK: 12 MiB in 23 packages
```

You should now see the following:

```console
The push refers to repository [192.168.1.1/tink-worker]
951257f56dc4: Pushed
5f6dc49a57a0: Pushed
3e207b409db3: Pushed
latest: digest: sha256:0ba0dc929e2426b5060d421f21af9e7d8449ce3f27d222204f3b7201ea1e9882 size: 949
INFO: tinkerbell stack setup completed successfully on ubuntu server
NEXT:  1. Enter /vagrant/deploy and run: source ../envrc; docker-compose up -d
       2. Try executing your fist workflow.
          Follow the steps described in https://tinkerbell.org/examples/hello-world/ to say 'Hello World!' with a workflow.
root@tink-provisioner:~#
```

### Run Tink for the first time

```sh
cd deploy
source ../envrc
docker-compose up -d
```

We can follow along here now: https://tinkerbell.org/setup/packet-with-terraform/hardware-data/

```sh
docker exec -ti deploy_tink-cli_1 /bin/sh
```

#### Run Tink outside of Docker

This section is only provided for anyone interested in running tink from the provisioner outside of the docker container.  This is likely flawed and highly not recommended. I suspect that volumes are shared between the containerized CLI, so use that instead of this.

```sh
apt install -y golang
go get github.com/tinkerbell/tink/cmd/tink-cli # takes a minute
alias tink=tink-cli
export PATH=$PATH:~/go/bin

# tink wants these variables set, I wasn't sure what to use but I found
# these in docker-compose.yaml... and they worked :-D
export TINKERBELL_CERT_URL=http://$TINKERBELL_HOST_IP:42114/cert
export TINKERBELL_GRPC_AUTHORITY=$TINKERBELL_HOST_IP:42113
```

### Tink Examples

At this point you can follow along with the instructions here:
https://tinkerbell.org/examples/hello-world/

```sh
docker pull hello-world
docker tag hello-world $TINKERBELL_HOST_IP/hello-world
docker push  $TINKERBELL_HOST_IP/hello-world

tink template create -n hello-world -p hello-world.tmpl
```
