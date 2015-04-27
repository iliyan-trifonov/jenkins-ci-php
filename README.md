Docker image with Jenkins CI and full PHP configuration and tools
===

Information
---

[See it in action here](http://jenkins.iliyan-trifonov.com/ "Jenkins CI PHP on iliyan-trifonov.com").

This [Docker image](https://registry.hub.docker.com/u/iliyan/jenkins-ci-php/ "Docker Jenkins CI PHP")
follows the http://jenkins-php.org/ configuration for installing Jenkins CI and the PHP testing tools.

After you run the container you should use a project built like the example on http://jenkins-php.org/
like [this one](http://gitlab.iliyan-trifonov.com/behat-tests/mvc-bdd-tdd/tree/master "mvc-bdd-tdd").

You only need to add build.xml and build/ in your project, put your files in src/, put the tests in tests/ 
and now you can use the full power of this configuration.

And you can always change the default configuration
in build.xml and probably build/phpunit.xml

Configuration of the image
---

This build uses Ubuntu 14.04 LTS image.

The [PHP 5.5 PPA by Ondřej Surý](https://launchpad.net/~ondrej/+archive/ubuntu/php5 "PPA for PHP 5.5") 
is used for the latest version of PHP and its extensions.

For Jenkins [the Debian deb repo](http://pkg.jenkins-ci.org/debian "Jenkins Deb Repo") is used.

The deb mirrors.ubuntu.com/mirrors.txt is used for faster local updating/downloading of the apt packages.

DEBIAN_FRONTEND=noninteractive and apt-get -qq are used for automatic silent installs.

date.timezone=yourtimezone and ;disable_functions= are set in php.ini

The time zone of the server is also set to yourtimezone. You can provide your time zone while starting the container with `-e 'TIME_ZONE=Europe/Paris'`.

Currently these plugins are installed: checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations warnings xunit git ansicolor.

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
sudo docker pull iliyan/jenkins-ci-php:1.3.1
```

And run it:

Locally:

```bash
sudo docker run -d --name jenkins -p 127.0.0.1:8080:8080 iliyan/jenkins-ci-php:1.3.1
```

Visible from outside on a hosting server:

```bash
sudo docker run -d --name jenkins -p VISIBLESERVERPORT:8080 iliyan/jenkins-ci-php:1.3.1
```

Set your own timezone:

```bash
sudo docker run -d --name jenkins -p VISIBLESERVERPORT:8080 -e 'TIME_ZONE=Europe/Paris' iliyan/jenkins-ci-php:1.3.1
```

Updating
---

Don't forget to backup the /var/lib/jenkins directory first!
It is recommended to always use data volume, mapping a local directory on the host to /var/lib/jenkins. 

First pull the latest docker image:

```bash
sudo docker pull iliyan/jenkins-ci-php:1.3.1
```

Then just remove the currently running image with:

```bash
sudo docker stop jenkins && sudo docker rm jenkins
```

Then run the latest image. For example using it with a data volume:

```bash
sudo docker run -d --name jenkins -p 127.0.0.1:8080 -v /home/myname/jenkins:/var/lib/jenkins iliyan/jenkins-ci-php:1.3.1
```

When I see in `Manage Jenkins` that there is a new update of the server, I run a new build for this project's master branch and latest tag on [https://hub.docker.com](https://hub.docker.com) so you can redownload the docker image and have the latest Jenkins and its plugins. You can also update/install new plugins and they stay in your /var/lib/jenkins even after the container is replaced.

This way even if you pull the same tag you will have a newer version of Jenkins automatically.
I suggest you to pull my Jenkins image at least once a month and you can also submit an issue for me to update to the latest version.

There are updates from time to time of the php-template which you may not see until you create a new project copying from it. So you're safe from breaking updates and you can always check the latest configuration by creating a new project from the template.

Data Volumes
---

I suggest you to use a [data volume](https://docs.docker.com/userguide/dockervolumes/ "Docker Data Volumes") 
with the container where you use a local directory on the host server and you can backup and reuse it with another 
container or a new version of this container's image.
Let's use it that way:

First copy what is created by the image build script inside /var/lib/jenkins by creating a temporary container:

```bash
mkdir /home/myname/jenkins
sudo docker run -ti --name jenkins iliyan/jenkins-ci-php:1.3.1 echo "Hello, Docker"
sudo docker cp jenkins:/var/lib/jenkins/* /home/myname/jenkins/
sudo docker rm jenkins
```

And then run a new container by specifying the data volume (you'll also need to give rights to the jenkins user on the mapped dir):

```bash
sudo docker run -d --name jenkins -p 127.0.0.1:8080:8080 -v /home/myname/jenkins:/var/lib/jenkins iliyan/jenkins-ci-php:1.3.1 bash
chown -R jenkins:jenkins /var/lib/jenkins
exit
sudo docker commit jenkins myname/jenkins
sudo docker run -d --name jenkins -p 127.0.0.1:8080:8080 -v /home/myname/jenkins:/var/lib/jenkins myname/jenkins sh /run_all.sh 
```

Possible configuration changes after install
---

Make sure the value of `Index page[s]` in the `Publish HTML reports` section in the project's settings is `index.html`.
This will fix the missing `Api documentation` page in the project's dashboard.

Enable top images in project's dashboard:
Go to: `Manage Jenkins` -> `Configure Global Security`
and change `Escaped HTML` to `Raw HTML`.
Save.

If your tests output colors you may find it useful to see the colors in the project builds' console logs.
To enable this check the `Color ANSI Console Output checkbox` in the project's settings.

Don't forget to secure your Jenkins pages from unauthorized access.

Extending it
---

If you need to install a new PHP extension or update Jenkins without rebuilding the image, you can start the container with Bash:

```bash
sudo docker run -ti --name jenkins_tmp -v /home/myname/jenkins:/var/lib/jenkins iliyan/jenkins-ci-php:1.3.1 bash
```

Update, install or change any configuration and then exit the container, commit it:

```bash
sudo docker commit jenkins_tmp myname/jenkins && jenkins stop jenkins && jenkins rm jenkins jenkins_tmp
```

Start from the image/tag where you've made and comitted the changes:

```bash
sudo docker run -d --name jenkins -p 8080:8080 -v /home/myname/jenkins:/var/lib/jenkins myname/jenkins sh /run_all.sh
```

You may also want to change the versions of the PHP tools in Dockerfile and rebuild the image.

Inside the directory where the Dockerfile is, the build command will be:

```bash
sudo docker build --no-cache --force-rm -t myname/jenkins .
```

After the buiild use myname/jenkins to run the container

Alternative usage of the PHP testing tools:
---

You can download all of the tools from your project's composer.json file adding them for example in the dev secion 
like I did [here](http://gitlab.iliyan-trifonov.com/behat-tests/mvc-bdd-tdd/blob/master/composer.json "composer.json") 
and [here](http://gitlab.iliyan-trifonov.com/behat-tests/mvc-bdd-tdd/blob/master/build.xml "build.xml").

Check also [this Laravel 4 test project build](https://gitlab.iliyan-trifonov.com/laravel/test-empty-laravel-project/tree/master "Laravel 4 Test Jenkins PHP build") that uses the tools from /usr/local/bin. See how the composer and its packages are called from [build.xml](https://gitlab.iliyan-trifonov.com/laravel/test-empty-laravel-project/blob/master/build.xml "build.xml"). The Jenkins project for this is [here](https://jenkins.iliyan-trifonov.com/job/LaravelTestEmptyProject/ "Laravel Test Project").

Final
---

You can test the new Jenkins CI installation with [this project](https://github.com/sebastianbergmann/money.git "sebastianbergmann/money")
or [this one](http://gitlab.iliyan-trifonov.com/behat-tests/mvc-bdd-tdd/tree/master "mvc-bdd-tdd").
Create a new Jenkins Job by using the copy option and use php-template.

Enable the build, pick the Git Option and add
the url of the project (try with the ssh and http urls if you are not using credentials).

Save and click Build. 
Go to the console log to see how it is working.
If the project builds successfully you will see the power of CI!

After this long sysadmin task you can continue working with PHP! :)
