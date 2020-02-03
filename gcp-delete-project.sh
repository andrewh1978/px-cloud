. gcp-env.sh

gcloud projects delete $GCP_PROJECT --quiet
rm -f gcp-key.json gcp-env.sh id_rsa.gcp*
