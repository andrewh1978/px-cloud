# Set the GCP region
GCP_REGION=europe-west1
GCP_owner_tag=CHANGEME

# Do not change below this line
ssh-keygen -t rsa -b 2048 -f id_rsa.gcp -N ''
GCP_PROJECT=pxd-$(uuidgen | tr -d -- - | cut -b 1-26 | tr 'A-Z' 'a-z')
gcloud projects create $GCP_PROJECT
account=$(gcloud alpha billing accounts list | tail -1 | cut -f 1 -d " ")
gcloud alpha billing projects link $GCP_PROJECT --billing-account $account
gcloud services enable compute.googleapis.com --project $GCP_PROJECT
gcloud compute networks create px-net --project $GCP_PROJECT
gcloud compute networks subnets create --range 192.168.0.0/16 --network px-net px-subnet --region $GCP_REGION --project $GCP_PROJECT
gcloud compute firewall-rules create allow-internal --allow=tcp,udp,icmp --source-ranges=192.168.0.0/16 --network px-net --project $GCP_PROJECT &
gcloud compute firewall-rules create allow-external --allow=tcp:22,tcp:443,tcp:6443 --network px-net --project $GCP_PROJECT &
gcloud compute project-info add-metadata --metadata "ssh-keys=centos:$(cat id_rsa.gcp.pub)" --project $GCP_PROJECT &
service_account=$(gcloud iam service-accounts list --project $GCP_PROJECT --format 'flattened(email)' | tail -1 | cut -f 2 -d " ")
GCP_key="$(gcloud iam service-accounts keys create /dev/stdout --iam-account $service_account)"
wait

set | grep ^GCP | sed 's/^/export /' >gcp-env.sh
