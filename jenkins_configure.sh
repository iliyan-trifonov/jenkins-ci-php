service jenkins start
while ! echo exit | nc -z -w 3 localhost 8080; do sleep 3; done
while curl -s http://localhost:8080 | grep "Please wait"; do echo "Waiting for Jenkins to start.." && sleep 3; done
echo "Jenkins started"
sleep 3
ADMINPASS=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
MYCRUMB=$(curl -u "admin:$ADMINPASS" 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
curl -L https://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -u "admin:$ADMINPASS"  -H 'Accept: application/json' -H "$MYCRUMB" -d @- http://localhost:8080/updateCenter/byId/default/postBack
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
service jenkins stop
java -Djenkins.install.runSetupWizard=false -jar /usr/share/jenkins/jenkins.war &
sleep 10
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations warnings xunit git ansicolor
java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart
curl https://raw.githubusercontent.com/sebastianbergmann/php-jenkins-template/master/config.xml |
java -jar jenkins-cli.jar -s http://localhost:8080 create-job php-template
java -jar jenkins-cli.jar -s http://localhost:8080 reload-configuration
