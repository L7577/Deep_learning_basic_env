# try to infer the correct DOCKER
ifndef DOCKER
DOCKER  :=$(shell if which docker > /dev/null; \
  then echo 'docker'; exit; \
  else \
  printf "***\n" 1>&2; \
  printf "***Error: Couldn't find a docker executable.\n" 1>&2; \
  printf "***\n" 1>&2; exit 1; fi)
endif

V		:= @

DEFAULT_RUNTIME =$(shell docker info 2>/dev/null | sed '/Runtime:/!d;s/.* //')
RUNTIMES=$(shell docker info 2>/dev/null | sed -e '/Runtimes:/!d' -e '/nvidia/!d;s/.*/nvidia/')
ifneq ("$(RUNTIMES)","nvidia")
$(warning WARNING:Runtimes is not found nvidia, should set it!)
endif
ifneq ("$(DEFAULT_RUNTIME)","nvidia")
$(warning WARNING:Default runtime is not nvidia, should set it)
endif

######################################
#CUDA and cuDNN 
#devel base  runtime  
CUDA_TAG		=-devel
SYSTEM			=-ubuntu18.04

CUDA_IMAGE		=nvidia/cuda:$(CUDA)$(CUDNN)$(CUDA_TAG)$(SYSTEM)

#--------------------------------------------------
#Tensorflow Docker images
TENSORFLOW_VERSION	?=latest

#latest nightly devel 
TENSORFLOW_TAG		=-devel

TAG_VARIANTS		?=-gpu-jupyter
#Tag Variants gpu  or gpu-jupyter
#TAG_VARIANTS		=-jupyter

TENSORFLOW_IMAGE	=tensorflow/tensorflow:$(TENSORFLOW_VERSION)$(TAG_VARIANTS)

#--------------------------------------------------
#PyTorch Docker images

PYTORCH_VERSION		?=latest

PYTORCH_IMAGE		=pytotch/pytorch:$(PYTORCH_VERSION)$(CUDA)$(CUDNN)$(PYTORCH_TAG)

#---------------------------------------------------
WORK_DIR		?=/home/l/test
DOCKER_WORK_DIR		?=/test
DOCKER_NAME 		?=test1
DOCKER_CMD		=

DOCKER_PULL		:=docker pull
DOCKER_RUN		:=docker run

DOCKER_RUN_ARGS		=--name $(DOCKER_NAME) -v $(WORK_DIR):$(DOCKER_WORK_DIR) \
			-it 

RUN_CMD			=$(DOCKER_RUN) $(DOCKER_RUN_ARGS) $(RUN_IMAGE) $(DOCKER_CMD)
#---------------------------------------------------
.PHONY:all
all:
	@echo "Example:  make tensorflow \n please try again" 

.PHONY:cuda
cuda:CUDA:=11.0
cuda:CUDNN?=
cuda:RUN_IMAGE=$(CUDA_IMAGE)
cuda:
	@echo "$(RUN_CMD)"

.PHONY:tensorflow
tensorflow:RUN_IMAGE=$(TENSORFLOW_IMAGE)
tensorflow:TAG_VARIANTS:=
tensorflow:
	@echo "$(RUN_CMD)"



.PHONY:pytorch
pytorch:PYTORCH_VERSION=latest
pytorch:CUDA_VERSION:=11.3
pytorch:CUDNN_VERSION:=8
pytorch:PYTORCH_TAG:=
pytorch:RUN_IMAGE=$(PYTORCH_IMAGE)
pytorch:
	@echo "$(RUN_CMD)"

