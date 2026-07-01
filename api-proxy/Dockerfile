FROM node:22-alpine

RUN apk add --no-cache bash jq

WORKDIR /app
COPY package.json ./
RUN npm install --production --no-audit --no-fund
COPY server.js run.sh ./
RUN chmod +x run.sh

EXPOSE 5000
CMD ["/app/run.sh"]
