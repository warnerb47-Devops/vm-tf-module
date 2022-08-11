FROM hashicorp/terraform:1.1.4
WORKDIR /root
COPY . .
WORKDIR /root/AWS

# docker build -t vm-tf-module .
# docker run -d -t --name vm-tf-module --entrypoint /bin/sh vm-tf-module
# docker exec -ti vm-tf-module sh
