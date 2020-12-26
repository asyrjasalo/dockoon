ARG FROM_IMAGE=asyrjasalo/mockoon:alpine
FROM $FROM_IMAGE

COPY --chown=node:node apis.json .
CMD ["start", "--data", "apis.json", "--index", "0"]
