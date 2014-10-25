FROM ubuntu:14.04

MAINTAINER Iliyan Trifonov <iliyan.trifonov@gmail.com>

RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse" > /etc/apt/sources.list; \
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list; \
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list; \
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update; \
	apt-get -qq install wget

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C; \
	echo "deb http://ppa.launchpad.net/ondrej/php5/ubuntu trusty main" >> /etc/apt/sources.list; \
	echo "deb-src http://ppa.launchpad.net/ondrej/php5/ubuntu trusty main" >> /etc/apt/sources.list

RUN wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add - > /dev/null 2>&1; \
	echo "deb http://pkg.jenkins-ci.org/debian binary/" > /etc/apt/sources.list.d/jenkins.list

RUN export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get -qq install php5-cli php5-xsl php5-json php5-curl php5-sqlite php5-mysqlnd php5-xdebug php-pear curl git ant jenkins

RUN sed -i 's|;date.timezone.*=.*|date.timezone=Europe/Sofia|' /etc/php5/cli/php.ini; \
	sed -i 's|disable_functions.*=|;disable_functions=|' /etc/php5/cli/php.ini

RUN service jenkins start; \
	sleep 60; \
	curl -L http://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- http://localhost:8080/updateCenter/byId/default/postBack; \
	wget http://localhost:8080/jnlpJars/jenkins-cli.jar; \
	java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations xunit; \
	java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart; \
	curl https://raw.githubusercontent.com/sebastianbergmann/php-jenkins-template/master/config.xml | \
	java -jar jenkins-cli.jar -s http://localhost:8080 create-job php-template; \
	java -jar jenkins-cli.jar -s http://localhost:8080 reload-configuration

RUN mkdir -p /home/jenkins/composerbin && chown -R jenkins:jenkins /home/jenkins; \
	sudo -H -u jenkins bash -c ' \
		curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/jenkins/composerbin --filename=composer;'; \
	ln -s /home/jenkins/composerbin/composer /usr/local/bin/; \
	sudo -H -u jenkins bash -c ' \
		export COMPOSER_BIN_DIR=/home/jenkins/composerbin; \
		export COMPOSER_HOME=/home/jenkins; \
		composer global require "phpunit/phpunit=4.3.*" --prefer-source --no-interaction; \
		composer global require "squizlabs/php_codesniffer=1.*" --prefer-source --no-interaction; \
		composer global require "phploc/phploc=*" --prefer-source --no-interaction; \
		composer global require "pdepend/pdepend=2.0.3" --prefer-source --no-interaction; \
		composer global require "phpmd/phpmd=@stable" --prefer-source --no-interaction; \
		composer global require "sebastian/phpcpd=*" --prefer-source --no-interaction; \
		composer global require "theseer/phpdox=*" --prefer-source --no-interaction; '; \
	ln -s /home/jenkins/composerbin/pdepend /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpcpd /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpcs /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpdox /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phploc /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpmd /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpunit /usr/local/bin/

RUN echo "service jenkins start" > /run_all.sh; \
	echo "tail -f /var/log/jenkins/jenkins.log" >> /run_all.sh

EXPOSE 8080

CMD ["sh", "/run_all.sh"]
