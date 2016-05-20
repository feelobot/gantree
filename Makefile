VERSION := 0.6.14

# Change this variable to your organisation s3 bucket
S3_BUCKET := s3://br-jenkins/gantree


all: build

build:
	gem build gantree.gemspec

install:
	gem install --local gantree-${VERSION}.gem

linux:
	#docker run -ti --rm -v `pwd`:/workspace -w /workspace ruby:2.1.5 /bin/bash -c "bundle install && bundle exec rake package:linux:x86_64"
	@echo "=> push latest version linux binary to : ${S3_BUCKET}"
	aws s3 cp ./gantree-${VERSION}-linux-x86_64.tar.gz ${S3_BUCKET}/ --sse AES256 --acl public-read

osx:
	docker run -ti --rm -v `pwd`:/workspace -w /workspace ruby:2.1.5 /bin/bash -c "bundle install && bundle exec rake package:osx"

clean:
	rm -rf gantree-${VERSION}-*.tar.gz
	rm -rf gantree-${VERSION}.gem
