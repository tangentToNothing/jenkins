output "jenkins_url" {
  value = "${aws_elb.jenkins.dns_name}"
}