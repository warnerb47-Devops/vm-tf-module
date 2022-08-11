FROM hashicorp/terraform:1.1.4
WORKDIR /root
COPY . .
WORKDIR /root/AWS
RUN terraform init
# CMD [ "/bin/sh" ]

# docker build -t vm-tf-module .
# docker run -d -ti --name vm-tf-module vm-tf-module init
# docker exec -ti vm-tf-module apply
# docker run -d -t --name vm-tf-module --entrypoint /bin/sh vm-tf-module
