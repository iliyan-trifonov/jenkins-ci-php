while ! echo exit | nc -z -w 3 localhost 8080; do sleep 3; done
while curl -s http://localhost:8080 | grep "Please wait"; do echo "Waiting for Jenkins to start.." && sleep 3; done
echo "Jenkins started"
