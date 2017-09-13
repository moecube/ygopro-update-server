FROM node

# 都是逼的
RUN apt-get update
RUN apt-get install vim

WORKDIR /usr/src/app
COPY package.json /usr/src/app
COPY package-lock.json /usr/src/app
RUN npm install

COPY . /usr/src/app
ENTRYPOINT npm start