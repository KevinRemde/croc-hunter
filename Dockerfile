FROM golang:1.7-alpine

MAINTAINER Kevin Remde <kevrem@microsoft.com>

ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/kevinremde/croc-hunter" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile"

COPY . /go/src/github.com/kevinremde/croc-hunter
COPY static/ static/

ENV GIT_SHA $VCS_REF
ENV GOPATH /go
RUN cd $GOPATH/src/github.com/kevinremde/croc-hunter && go install -v .

CMD ["croc-hunter"]

EXPOSE 8080
	
