FROM docker.io/bitnami/kubectl:1.29.0
COPY static /static
CMD ["proxy", "--www=/static", "--accept-hosts=^.*$", "--address=[::]", "--api-prefix=/k8s/", "--www-prefix="]
