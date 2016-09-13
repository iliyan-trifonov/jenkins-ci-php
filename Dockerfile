FROM ubuntu:14.04

MAINTAINER Iliyan Trifonov <iliyan.trifonov@gmail.com>

RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse" > /etc/apt/sources.list; \
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list; \
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list; \
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update; \
	apt-get -qq install wget

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C; \
	echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu trusty main" >> /etc/apt/sources.list; \
	echo "deb-src http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu trusty main" >> /etc/apt/sources.list

RUN wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add - > /dev/null 2>&1; \
	echo "deb http://pkg.jenkins-ci.org/debian binary/" > /etc/apt/sources.list.d/jenkins.list

RUN export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get -qq install php5 php5-cli php5-xsl php5-json php5-curl php5-sqlite php5-mysqlnd php5-xdebug php5-intl php5-mcrypt php-pear curl git ant jenkins

ADD ./jenkins_configure.sh /jenkins_configure.sh
ADD ./wait4jenkins.sh /wait4jenkins.sh

RUN sh /jenkins_configure.sh

RUN sed -i 's|disable_functions.*=|;disable_functions=|' /etc/php5/cli/php.ini; \
	echo "xdebug.max_nesting_level = 500" >> /etc/php5/mods-available/xdebug.ini

RUN mkdir -p /home/jenkins/composerbin && chown -R jenkins:jenkins /home/jenkins; \
	sudo -H -u jenkins bash -c ' \
		curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/jenkins/composerbin --filename=composer;'; \
	ln -s /home/jenkins/composerbin/composer /usr/local/bin/; \
	sudo -H -u jenkins bash -c ' \
		export COMPOSER_BIN_DIR=/home/jenkins/composerbin; \
		export COMPOSER_HOME=/home/jenkins; \
		composer global require "phpunit/phpunit=*" --prefer-source --no-interaction; \
		composer global require "squizlabs/php_codesniffer=*" --prefer-source --no-interaction; \
		composer global require "phploc/phploc=*" --prefer-source --no-interaction; \
		composer global require "pdepend/pdepend=*" --prefer-source --no-interaction; \
		composer global require "phpmd/phpmd=*" --prefer-source --no-interaction; \
		composer global require "sebastian/phpcpd=*" --prefer-source --no-interaction; \
		composer global require "theseer/phpdox=*" --prefer-source --no-interaction; '; \
	ln -s /home/jenkins/composerbin/pdepend /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpcpd /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpcs /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpdox /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phploc /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpmd /usr/local/bin/; \
	ln -s /home/jenkins/composerbin/phpunit /usr/local/bin/

RUN echo 'if [ -z "$TIME_ZONE" ]; then echo "No TIME_ZONE env set!" && exit 1; fi' > /set_timezone.sh; \
	echo "sed -i 's|;date.timezone.*=.*|date.timezone='\$TIME_ZONE'|' /etc/php5/cli/php.ini;" >> /set_timezone.sh; \
	echo "echo \$TIME_ZONE > /etc/timezone;" >> /set_timezone.sh; \
	echo "export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive;" >> /set_timezone.sh; \
	echo "dpkg-reconfigure tzdata" >> /set_timezone.sh; \
	echo "echo time zone set to: \$TIME_ZONE"  >> /set_timezone.sh

RUN echo 'if [ -n "$TIME_ZONE" ]; then sh /set_timezone.sh; fi;' > /run_all.sh; \
	echo "curl -o /var/lib/jenkins/jobs/php-template/config.xml https://raw.githubusercontent.com/sebastianbergmann/php-jenkins-template/master/config.xml " >> /run_all.sh; \
	echo "service jenkins start" >> /run_all.sh; \
	echo "tail -f /var/log/jenkins/jenkins.log;" >> /run_all.sh

EXPOSE 8080

CMD ["sh", "/run_all.sh"]
