FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

# Use npm ci for faster and more reliable installs in CI/CD environments
RUN npm ci --only=production

# Bundle app source
COPY . .

# Use environment variable for port with default value
ENV PORT=3000

# Expose the port from the environment variable
EXPOSE ${PORT}

# Start the application
CMD [ "node", "server.js" ]