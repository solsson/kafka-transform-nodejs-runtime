FROM yolean/node-kafka@sha256:f7aedb184d533cef7b4a88ea8520271f5912fedbc7016f0b5bb8daf29cd39907 \
  AS prod
WORKDIR /usr/src/runtime

COPY package*.json ./

RUN npm ci

# We might need a dummy package.json for this, that names the module "handler" for example
RUN npm install ../app

FROM yolean/node-kafka@sha256:f7aedb184d533cef7b4a88ea8520271f5912fedbc7016f0b5bb8daf29cd39907 \
  AS prepare
WORKDIR /usr/src/runtime

COPY --from=prod /usr/src/runtime/node_modules/ ./node_modules/

COPY . .

RUN npm install --only=dev --no-shrinkwrap --no-optional

# Whatever produces something runnable
RUN npm prepare

FROM yolean/node-kafka@sha256:f7aedb184d533cef7b4a88ea8520271f5912fedbc7016f0b5bb8daf29cd39907 \
  AS runtime
WORKDIR /usr/src/runtime

COPY --from=prod /usr/src/runtime/node_modules/ ./node_modules/

# Whatever is needed at runtime
COPY --from=prepare package.json src ./

ENTRYPOINT [ "npm", "start" ]

# Now the handler developer should only need to copy prepared source and node_modules to /usr/src/app
