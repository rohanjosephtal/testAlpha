FROM phusion/baseimage
MAINTAINER Abhishek Amralkar & Rohan Joseph

RUN apt-get update && apt-get upgrade -y
RUN apt-get install unzip -y
RUN apt-get install nginx -y
RUN apt-get install telnet -y
RUN service nginx stop
RUN apt-get install python-pip -y
#RUN pip install s3cmd
RUN pip install awscli
ENV DEBIAN_FRONTEND noninteractive
RUN mkdir ~/.aws/
RUN touch ~/.aws/credentials






######ORACLE JAVA 8 Installation #####
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:webupd8team/java -y
RUN apt-get update
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN apt-get install oracle-java8-installer -y

##########Jetty Installation######

RUN groupadd -r jetty && useradd -r -g jetty jetty
RUN apt-get install unzip
ENV JETTY_HOME /usr/local/jetty
ENV PATH $JETTY_HOME/bin:$PATH
RUN mkdir -p "$JETTY_HOME"
WORKDIR $JETTY_HOME

# see http://dev.eclipse.org/mhonarc/lists/jetty-users/msg05220.html
ENV JETTY_GPG_KEYS \
	# 1024D/8FB67BAC 2006-12-10 Joakim Erdfelt <joakime@apache.org>
	B59B67FD7904984367F931800818D9D68FB67BAC \
	# 1024D/D7C58886 2010-03-09 Jesse McConnell (signing key) <jesse.mcconnell@gmail.com>
	5DE533CB43DAF8BC3E372283E7AE839CD7C58886

RUN set -xe \
	&& for key in $JETTY_GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

ENV JETTY_VERSION 9.3.2.v20150730
ENV JETTY_TGZ_URL https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz

RUN set -xe \
	&& curl -SL "$JETTY_TGZ_URL" -o jetty.tar.gz \
	&& curl -SL "$JETTY_TGZ_URL.asc" -o jetty.tar.gz.asc \
	&& gpg --verify jetty.tar.gz.asc \
	&& tar -xvf jetty.tar.gz --strip-components=1 \
	&& sed -i '/jetty-logging/d' etc/jetty.conf \
	&& rm -fr demo-base javadoc \
	&& rm jetty.tar.gz*

ENV JETTY_BASE /var/lib/jetty
RUN mkdir -p "$JETTY_BASE"
WORKDIR $JETTY_BASE

# Get the list of modules in the default start.ini and build new base with those modules, then add setuid
RUN modules="$(grep -- ^--module= "$JETTY_HOME/start.ini" | cut -d= -f2 | paste -d, -s)" \
	&& set -xe \
	&& java -jar "$JETTY_HOME/start.jar" --add-to-startd="$modules,setuid"

ENV JETTY_RUN /run/jetty
ENV JETTY_STATE $JETTY_RUN/jetty.state
ENV TMPDIR /tmp/jetty
RUN set -xe \
	&& mkdir -p "$JETTY_RUN" "$TMPDIR" \
	&& chown -R jetty:jetty "$JETTY_RUN" "$TMPDIR" "$JETTY_BASE"

RUN mkdir /etc/service/jetty
ADD start_jetty.sh /etc/service/jetty/run
RUN chmod a+x /etc/service/jetty/run

WORKDIR $JETTY_BASE/webapps

ENV VERSION=0.4.184

RUN aws s3 cp s3://packager-000-dev.avalonlabs.io/com/twiinlabs/accounts/${VERSION}/accounts-${VERSION}.war .

RUN chown jetty:jetty $JETTY_BASE/webapps/accounts-${VERSION}.war
RUN chmod 777 $JETTY_BASE/webapps/accounts-${VERSION}.war
RUN mkdir /var/avalon
RUN chmod 777 /var/avalon

ADD swagger /etc/nginx/sites-available/
RUN cd /etc/nginx/sites-enabled/ && ln -s ../sites-available/swagger
RUN rm -f /etc/nginx/sites-enabled/default

RUN mkdir /etc/service/nginx
ADD start_nginx.sh /etc/service/nginx/run
RUN chmod a+x /etc/service/nginx/run


CMD ["/sbin/my_init"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

