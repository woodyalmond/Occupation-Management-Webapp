FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /src

COPY pubspec.yaml pubspec.lock* analysis_options.yaml ./
COPY lib ./lib
COPY test ./test
COPY web ./web

RUN flutter create --platforms web --project-name alarmapp_local .
RUN flutter pub get

ARG API_BASE_URL=
RUN flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build/web /usr/share/nginx/html

EXPOSE 80
