provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "jenkins-cluster" {
  name = "jenkins-cluster"
}

resource "aws_autoscaling_group" "jenkins_ecs_instances" {
  name = "jenkins_ecs_instances"
  min_size = 5
  max_size = 5
  launch_configuration = "${aws_launch_configuration.jenkins_ecs_instance.name}"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

resource "aws_launch_configuration" "jenkins_ecs_instance" {
  name_prefix = "jenkins_ecs_instance-"
  instance_type = "t2.micro"
  image_id = "ami-fbc1c684"
}

resource "aws_ecs_task_definition" "jenkins_task" {
  family = "jenkins_task"
  container_definitions = <<EOF
    [{
      "name": "jenkins_task",
      "image": "${var.repo_url}",
      "cpu": 1024,
      "memory": 768,
      "essential": true,
      "portMappings": [{"containerPort": 8080, "hostPort": 8080},
      {"containerPort": 50000, "hostPort": 50000}]
    }]
  EOF
}

resource "aws_ecs_service" "jenkins_task" {
  name = "jenkins_task"
  cluster = "${aws_ecs_cluster.jenkins-cluster.id}"
  task_definition = "${aws_ecs_task_definition.jenkins_task.arn}"
  desired_count = 1

  load_balancer {
    elb_name = "${aws_elb.jenkins.id}"
    container_name = "jenkins_task"
    container_port = 8080
  }
}

resource "aws_elb" "jenkins" {
  availability_zones = ["us-east-1a", "us-east-1b"]
  name = "jenkins"
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 8080
    instance_protocol = "http"
  }
}