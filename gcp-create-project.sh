. gcp-env.sh

gcloud projects create $PROJECT
account=$(gcloud alpha billing accounts list | tail -1 | cut -f 1 -d " ")
gcloud alpha billing projects link $PROJECT --billing-account $account
gcloud services enable compute.googleapis.com --project $PROJECT
gcloud compute networks create px-net --project $PROJECT
gcloud compute networks subnets create --range 192.168.99.0/24 --network px-net px-subnet --project $PROJECT
gcloud compute firewall-rules create allow-ssh --allow=tcp:22 --network px-net --project $PROJECT
gcloud compute firewall-rules create allow-https --allow=tcp:443 --network px-net --project $PROJECT
gcloud compute firewall-rules create allow-k8s --allow=tcp:6443 --network px-net --project $PROJECT
gcloud compute firewall-rules create allow-px-tcp --allow=tcp:9001-9022 --network px-net --project $PROJECT
gcloud compute firewall-rules create allow-px-udp --allow=udp:9002 --network px-net --project $PROJECT
gcloud compute project-info add-metadata --metadata "ssh-keys=$USER:$(cat $HOME/.ssh/id_rsa.pub"
