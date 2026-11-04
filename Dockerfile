FROM nginx:1.27-alpine
ARG APP_VERSION=v1
COPY app/index.html /usr/share/nginx/html/index.html
RUN sed -i "s/VERSION_PLACEHOLDER/${APP_VERSION}/g" /usr/share/nginx/html/index.html
EXPOSE 80
