# Working with Helm Repositories

## Goal:  In this repository, We'll go through how to work with Helm repositories(HTTP Based).

### Objectives:

  - Learn how to prepare a package of helm chart along with index.yaml file.
  - Learn how to publish the repo(all packed charts + index.yaml) on http web server
  - See how to add repo, pull and push charts from repositories.
  - How to import a chart from helm repository as a dependency in anohter chart.

### Prerequisites 
 - Need access and credentials to a web server that can serve yaml and tar archives - it could be a regular web server,
   or some managed helm repositories service(like Jfrog Artifactory or Sonatype Nexus)
 
### Agenda
- Will demonstrate with a sample apache httpd http web server that will be deployed as a container using podman/docker.
   - Will create a custom image with base image of apache httpd, in order to configure the httpd web server to support free unauthenticated access to get and put/post files from/to server.
   - This is only demo , in real you should use web server protected with at least basic authentication of user/password or 
     with a Bearer <token>(more secured) 
- Will demonstrate with github pages, which is free for public repositories 
 
### Regular HTTP Web server Procedure:

1. Build a custom image with the configuration for a web server letting get and post freely from/to path /charts:
```shell
[zgrinber@zgrinber helm-http-repositories]$ podman build -t my-httpd:1 .
```

2.After the image was built successfully, run the container to start the web server
```shell
[zgrinber@zgrinber helm-http-repositories]$podman run -p 8081:80 --name httpd --hostname httpd  -d localhost/my-httpd:1
```
3.Create some sample chart to work on, and/or just change directory into existing sample directory:
```shell
[zgrinber@zgrinber helm-http-repositories]$ helm create sample
Creating sample
[zgrinber@zgrinber helm-http-repositories]$ cd sample
```
4.package the sample helm chart
```shell
[zgrinber@zgrinber sample]$ helm package .
```
5.create index file for the repo:
```shell
[zgrinber@zgrinber sample$ helm repo index . --url http://localhost:8081/charts
```
6.Make sure that packed package and index.yaml files were created:
```shell
[zgrinber@zgrinber sample]$ ls -ltr sample-0.1.0.tgz index.yaml 
-rw-rw-r--. 1 zgrinber zgrinber 3832 Apr 27 19:40 sample-0.1.0.tgz
-rw-rw-r--. 1 zgrinber zgrinber  418 Apr 27 19:40 index.yaml
```
7.upload the index.yaml and packaged chart to web server at url path `/charts`:
```shell
[zgrinber@zgrinber sample]$(echo sample-0.1.0.tgz ;  echo index.yaml) |  xargs -i curl -v -X PUT -T {} http://localhost:8081/charts/
```
**Note: In Apache httpd web server, it supports PUT method for uploading files, but some other web server, supports the POST method, so need to check before that according to the web server documentation.**
8. You should get 201 response for the 2 files, kindly verify with the following command that files indeed uploaded to server :
```html
[zgrinber@zgrinber sample]$ curl -L -X GET localhost:8081/charts 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>Index of /charts</title>
 </head>
 <body>
<h1>Index of /charts</h1>
<ul><li><a href="/"> Parent Directory</a></li>
<li><a href="index.yaml"> index.yaml</a></li>
<li><a href="sample-0.1.0.tgz"> sample-0.1.0.tgz</a></li>
</ul>
</body></html>

```
9. Now add the repo to helm:
```shell
[zgrinber@zgrinber sample]$ helm repo add httpd-charts http://localhost:8081/charts/
"httpd-charts" has been added to your repositories
```
10. Optionally you can update the repo(basically anytime you have a change in the repo you need to do it):
```shell
[zgrinber@zgrinber tmp]$ helm repo update httpd-charts
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "httpd-charts" chart repository
Update Complete. ⎈Happy Helming!⎈

```
11.Now you can pull the repo whenever and wherever you want:
```shell
[zgrinber@zgrinber tmp]$ helm pull httpd-charts/sample ; ll *.tgz 
-rw-r--r--. 1 zgrinber zgrinber 3832 Apr 28 15:44 sample-0.1.0.tgz
```

12. If needed to unpack the chart to a directory , you can use:
```shell
[zgrinber@zgrinber tmp]$ helm pull httpd-charts/sample --untar 
zgrinber@zgrinber tmp]$ cd sample
[zgrinber@zgrinber sample]$ ll
total 12
-rw-r--r--. 1 zgrinber zgrinber  121 Apr 28 15:47 Chart.yaml
-rw-r--r--. 1 zgrinber zgrinber   76 Apr 28 15:47 index.yaml
drwxr-xr-x. 3 zgrinber zgrinber  162 Apr 28 15:47 templates
-rw-r--r--. 1 zgrinber zgrinber 1873 Apr 28 15:47 values.yaml

```

13.Add as dependency to another chart(in this case add it as dependency to sample2 chart):
```yaml
piVersion: v2
name: sample2
description: A Helm chart for Kubernetes

type: application

version: 0.1.0

appVersion: "1.16.0"
dependencies:
  - name: sample
    repository: http://localhost:8081/charts
    version: 0.1.0


```

### Github pages 