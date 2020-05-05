#!/usr/bin/bash
# a Terraform external data source to get the TF control host's hostname
echo "{\"hostname\":\"`hostname`\"}"