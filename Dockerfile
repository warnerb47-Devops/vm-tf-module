FROM python:3.7.13-buster

# configure terraform
RUN apt update && apt install -y gnupg software-properties-common curl
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt update && apt install terraform
WORKDIR /root
COPY . .
CMD [ "/bin/bash" ]

# docker build -t vm-tf-module .
# docker run -d -t --name vm-tf-module vm-tf-module
# docker exec -ti vm-tf-module bash