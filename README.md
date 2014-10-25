Docker container with Jenkins CI and full PHP configuration and tools
===

Information
---

This Docker image follows the http://jenkins-php.org/ configuration
for installing Jenkins CI and the PHP testing tools.

It uses Ubuntu 14.04 LTS image.

The [PHP 5.5 PPA by Ondřej Surý](https://launchpad.net/~ondrej/+archive/ubuntu/php5 "PPA for PHP 5.5") is used for the latest version of PHP and its extensions.

For Jenkins [the Debian deb repo](http://pkg.jenkins-ci.org/debian "Jenkins Deb Repo") is used.

The deb mirrors.ubuntu.com/mirrors.txt is used for faster local updating/downloading of the apt packages.

DEBIAN_FRONTEND=noninteractive and apt-get -qq are used for automatic silent installs.

date.timezone=Europe/Sofia and ;disable_functions= are set in php.ini

After Jenkins is installed and needs its first update there is a wait of 20 seconds until the update script is called. 

The Jenkins server is first updated before installing the plugins.

Currently these plugins are installed: checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations xunit.

And these PHP testing tools are installed globally through Composer:
phpunit/phpunit, squizlabs/php_codesniffer, phploc/phploc, pdepend/pdepend, phpmd/phpmd, sebastian/phpcpd, theseer/phpdox.

Composer installs the tools in /home/jenkins/.composer and makes all of them available globally in /usr/local/bin/.

Composer is set to use git to fetch the dependencies to avoid the GitHub API rate limits.

Port 8080 is exposed and available. This is the default Jenkins' port.

The default CMD in the image is: "sh /run_all.sh"

Install
---

First download the image:

```bash
docker pull iliyan/docker-jenkins-ci-php:1.0.0
```

And run it:

Locally:
```bash
docker run -d --name jenkins -p localhost:8080:8080 iliyan/docker-jenkins-ci-php:1.0.0
```
Visible from outside on a hosting server:
```bash
docker run -d --name jenkins -p VISIBLESERVERPORT:8080 iliyan/docker-jenkins-ci-php:1.0.0
```

Data Volumes
---

I suggest you to use a [data volume](https://docs.docker.com/userguide/dockervolumes/ "Docker Data Volumes") with the container where you use a local directory on the host server and you can backup and reuse it with another container or a new version of this container's image.
Let's use it that way:

First copy what is created by the image build script inside /var/lib/jenkins by creating a temporary container:

```bash
mkdir /home/myname/jenkins
docker run -ti --name jenkins iliyan/docker-jenkins-ci-php echo "Hello, Docker"
docker cp jenkins:/var/lib/jenkins/* /home/myname/jenkins/
docker rm jenkins
```

And then run a new container by specifying the data volume:

```bash
docker run -d --name jenkins -p localhost:8080:8080 -v /home/myname/jenkins:/var/lib/jenkins iliyan/docker-jenkins-ci-php:1.0.0
```

Extending it
---

If you need to install a new PHP extension or update Jenkins without rebuilding the image, you can start the container with Bash:

```bash
docker run -ti --name jenkins_tmp -v /home/myname/jenkins:/var/lib/jenkins iliyan/docker-jenkins-ci-php:1.0.0 bash
```

Update, install or change any configuration and then exit the container, commit it:

```bash
docker commit jenkins_tmp myname/jenkins && jenkins stop jenkins && jenkins rm jenkins jenkins_tmp
```

Start from the image/tag where you've made and comitted the changes:

```bash
docker run -d --name jenkins -p 8080:8080 -v /home/myname/jenkins:/var/lib/jenkins myname/jenkins sh /run_all.sh
```

You may also want to change the versions of the PHP tools in Dockerfile and rebuild the image.

Inside the directory where the Dockerfile is, the build command will be:

```bash
build --no-cache --force-rm -t myname/jenkins .
```

After the buiild use myname/jenkins to run the container

Alternative usage of the PHP testing tools:
---

You can download all of the tools from your project's composer.json file adding them for example in the dev secion like I did [here](http://gitlab.iliyan-trifonov.com/behat-tests/mvc-bdd-tdd/blob/master/composer.json "composer.json") and [here](http://gitlab.iliyan-trifonov.com/behat-tests/mvc-bdd-tdd/blob/master/build.xml "build.xml").

Final
---

You can test the new Jenkins CI installation with [this project](https://github.com/sebastianbergmann/money.git "sebastianbergmann/money").
Install the Git Plugin. Create a new Jenkins Job by using the copy option and use php-template. Enable the build, pick the Git SCM and add
the url of the project. Save and click Build. Go to the console log to see how it is working.
If the project builds successfully you will see the power of CI!

After this long sysadmin task you can continue working with PHP! :)
